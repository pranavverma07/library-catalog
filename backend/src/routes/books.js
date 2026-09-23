const express = require('express');
const { pool } = require('../db');

const router = express.Router();

const BOOK_SELECT = `
  SELECT b.id, b.title, b.isbn, b.published_year, b.author_id,
         a.name AS author_name, b.created_at
  FROM books b
  JOIN authors a ON a.id = b.author_id
`;

router.get('/', async (req, res, next) => {
  try {
    const result = await pool.query(`${BOOK_SELECT} ORDER BY b.id`);
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const result = await pool.query(`${BOOK_SELECT} WHERE b.id = $1`, [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Book not found' });
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const { title, isbn, published_year, author_id } = req.body;
    if (!title || !author_id) return res.status(400).json({ error: 'title and author_id are required' });
    const result = await pool.query(
      'INSERT INTO books (title, isbn, published_year, author_id) VALUES ($1, $2, $3, $4) RETURNING id',
      [title, isbn || null, published_year || null, author_id]
    );
    const created = await pool.query(`${BOOK_SELECT} WHERE b.id = $1`, [result.rows[0].id]);
    res.status(201).json(created.rows[0]);
  } catch (err) {
    next(err);
  }
});

router.put('/:id', async (req, res, next) => {
  try {
    const { title, isbn, published_year, author_id } = req.body;
    const result = await pool.query(
      `UPDATE books SET title = COALESCE($1, title), isbn = COALESCE($2, isbn),
       published_year = COALESCE($3, published_year), author_id = COALESCE($4, author_id)
       WHERE id = $5 RETURNING id`,
      [title, isbn, published_year, author_id, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Book not found' });
    const updated = await pool.query(`${BOOK_SELECT} WHERE b.id = $1`, [req.params.id]);
    res.json(updated.rows[0]);
  } catch (err) {
    next(err);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const result = await pool.query('DELETE FROM books WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Book not found' });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

module.exports = router;
