const request = require('supertest');
const app = require('../index');
const { pool } = require('../db');

afterAll(async () => {
  await pool.end();
});

describe('GET /health', () => {
  it('returns ok when the database is reachable', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('Authors API', () => {
  it('lists seeded authors', async () => {
    const res = await request(app).get('/api/authors');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThanOrEqual(1);
  });

  it('creates a new author', async () => {
    const res = await request(app).post('/api/authors').send({ name: 'Test Author' });
    expect(res.status).toBe(201);
    expect(res.body.name).toBe('Test Author');
  });
});

describe('Books API', () => {
  it('creates and fetches a book joined with its author', async () => {
    const author = await request(app).post('/api/authors').send({ name: 'Jane Doe' });
    const created = await request(app)
      .post('/api/books')
      .send({ title: 'Test Book', author_id: author.body.id, published_year: 2020 });
    expect(created.status).toBe(201);
    expect(created.body.author_name).toBe('Jane Doe');

    const fetched = await request(app).get(`/api/books/${created.body.id}`);
    expect(fetched.status).toBe(200);
    expect(fetched.body.title).toBe('Test Book');
  });

  it('404s for a book that does not exist', async () => {
    const res = await request(app).get('/api/books/999999');
    expect(res.status).toBe(404);
  });
});
