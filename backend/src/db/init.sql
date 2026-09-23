CREATE TABLE IF NOT EXISTS authors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    isbn VARCHAR(20),
    published_year INTEGER,
    author_id INTEGER NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_books_author_id ON books(author_id);

INSERT INTO authors (name, bio)
VALUES
    ('George Orwell', 'English novelist and essayist, author of 1984 and Animal Farm.'),
    ('Agatha Christie', 'English writer known for detective novels.')
ON CONFLICT DO NOTHING;

INSERT INTO books (title, isbn, published_year, author_id)
VALUES
    ('1984', '9780451524935', 1949, 1),
    ('Animal Farm', '9780451526342', 1945, 1),
    ('Murder on the Orient Express', '9780062073501', 1934, 2)
ON CONFLICT DO NOTHING;
