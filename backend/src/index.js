require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { pool } = require('./db');
const authorsRouter = require('./routes/authors');
const booksRouter = require('./routes/books');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok' });
  } catch (err) {
    res.status(503).json({ status: 'db_unavailable', error: err.message });
  }
});

app.use('/api/authors', authorsRouter);
app.use('/api/books', booksRouter);

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;

if (require.main === module) {
  app.listen(PORT, () => console.log(`Library Catalog API listening on port ${PORT}`));
}

module.exports = app;
