const { Pool } = require('pg');

// Local dev (docker-compose) uses DATABASE_URL. Production (RDS) uses discrete
// PGHOST/PGUSER/PGPASSWORD/etc instead of building a connection string,
// because RDS's auto-generated master password can contain characters (@, /)
// that are unsafe to interpolate into a postgres:// URI without encoding.
const connectionConfig = process.env.DATABASE_URL
  ? { connectionString: process.env.DATABASE_URL }
  : {
      host: process.env.PGHOST,
      port: process.env.PGPORT ? Number(process.env.PGPORT) : 5432,
      user: process.env.PGUSER,
      password: process.env.PGPASSWORD,
      database: process.env.PGDATABASE,
    };

const pool = new Pool({
  ...connectionConfig,
  // RDS requires SSL in most VPC setups once "rds.force_ssl" is on;
  // rejectUnauthorized:false avoids needing the RDS CA bundle for this demo app.
  ssl: process.env.PGSSL === 'true' ? { rejectUnauthorized: false } : false,
});

module.exports = { pool };
