data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_instance" {
  name               = "${var.project}-app-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# SSM Session Manager + Run Command - this is how we deploy/patch/inspect
# instances with zero SSH keys and no inbound port 22 anywhere.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "app_instance_inline" {
  statement {
    sid       = "ReadDbSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }

  statement {
    sid       = "PullDeployArtifacts"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.deploy_bucket_arn}/*"]
  }

  statement {
    sid       = "ListDeployArtifactsBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.deploy_bucket_arn]
  }
}

resource "aws_iam_role_policy" "app_instance_inline" {
  name   = "${var.project}-app-instance-inline"
  role   = aws_iam_role.app_instance.id
  policy = data.aws_iam_policy_document.app_instance_inline.json
}

resource "aws_iam_instance_profile" "app_instance" {
  name = "${var.project}-app-instance-profile"
  role = aws_iam_role.app_instance.name
}

resource "aws_lb" "app" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name = "${var.project}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project}-app-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.app_instance.name
  }

  vpc_security_group_ids = [var.app_sg_id]

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    deploy_bucket = var.deploy_bucket_name
    aws_region    = var.aws_region
    db_secret_arn = var.db_secret_arn
    db_host       = var.db_host
    db_port       = var.db_port
    db_name       = var.db_name
    app_port      = var.app_port
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-app"
      App  = var.project
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project}-asg"
  vpc_zone_identifier = var.public_subnet_ids
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity

  target_group_arns = [aws_lb_target_group.app.arn]

  # ELB (not just EC2 status) health checks - an instance that's "running" but
  # failing /health through the ALB gets replaced, not just one that's stopped.
  health_check_type         = "ELB"
  health_check_grace_period = 90

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Rolling replacement when the launch template changes (new AMI, new
  # user_data) instead of a manual terminate-and-hope.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "App"
    value               = var.project
    propagate_at_launch = true
  }
}
