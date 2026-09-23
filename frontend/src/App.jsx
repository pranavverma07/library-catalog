import { useEffect, useState } from 'react';
import { api } from './api';

function AuthorForm({ onCreated }) {
  const [name, setName] = useState('');
  const [bio, setBio] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  async function handleSubmit(e) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await api.createAuthor({ name, bio });
      setName('');
      setBio('');
      onCreated();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-2 mt-4">
      <input
        className="border border-slate-300 rounded px-3 py-2 text-sm"
        placeholder="Author name"
        value={name}
        onChange={(e) => setName(e.target.value)}
        required
      />
      <input
        className="border border-slate-300 rounded px-3 py-2 text-sm"
        placeholder="Bio (optional)"
        value={bio}
        onChange={(e) => setBio(e.target.value)}
      />
      {error && <p className="text-red-600 text-sm">{error}</p>}
      <button
        type="submit"
        disabled={submitting}
        className="bg-slate-800 text-white rounded px-3 py-2 text-sm disabled:opacity-50"
      >
        Add author
      </button>
    </form>
  );
}

function BookForm({ authors, onCreated }) {
  const [title, setTitle] = useState('');
  const [isbn, setIsbn] = useState('');
  const [publishedYear, setPublishedYear] = useState('');
  const [authorId, setAuthorId] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  async function handleSubmit(e) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await api.createBook({
        title,
        isbn: isbn || undefined,
        published_year: publishedYear ? Number(publishedYear) : undefined,
        author_id: Number(authorId),
      });
      setTitle('');
      setIsbn('');
      setPublishedYear('');
      setAuthorId('');
      onCreated();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="grid grid-cols-2 gap-2 mt-4">
      <input
        className="border border-slate-300 rounded px-3 py-2 text-sm col-span-2"
        placeholder="Title"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        required
      />
      <input
        className="border border-slate-300 rounded px-3 py-2 text-sm"
        placeholder="ISBN (optional)"
        value={isbn}
        onChange={(e) => setIsbn(e.target.value)}
      />
      <input
        className="border border-slate-300 rounded px-3 py-2 text-sm"
        placeholder="Year"
        type="number"
        value={publishedYear}
        onChange={(e) => setPublishedYear(e.target.value)}
      />
      <select
        className="border border-slate-300 rounded px-3 py-2 text-sm col-span-2"
        value={authorId}
        onChange={(e) => setAuthorId(e.target.value)}
        required
      >
        <option value="" disabled>
          Select author
        </option>
        {authors.map((a) => (
          <option key={a.id} value={a.id}>
            {a.name}
          </option>
        ))}
      </select>
      {error && <p className="text-red-600 text-sm col-span-2">{error}</p>}
      <button
        type="submit"
        disabled={submitting}
        className="bg-slate-800 text-white rounded px-3 py-2 text-sm col-span-2 disabled:opacity-50"
      >
        Add book
      </button>
    </form>
  );
}

function BookRow({ book, authors, onChanged }) {
  const [editing, setEditing] = useState(false);
  const [title, setTitle] = useState(book.title);
  const [authorId, setAuthorId] = useState(book.author_id);
  const [busy, setBusy] = useState(false);

  async function saveEdit() {
    setBusy(true);
    try {
      await api.updateBook(book.id, { title, author_id: Number(authorId) });
      setEditing(false);
      onChanged();
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    setBusy(true);
    try {
      await api.deleteBook(book.id);
      onChanged();
    } finally {
      setBusy(false);
    }
  }

  if (editing) {
    return (
      <tr className="border-b border-slate-200">
        <td className="py-2 px-3">
          <input
            className="border border-slate-300 rounded px-2 py-1 text-sm w-full"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />
        </td>
        <td className="py-2 px-3">
          <select
            className="border border-slate-300 rounded px-2 py-1 text-sm w-full"
            value={authorId}
            onChange={(e) => setAuthorId(e.target.value)}
          >
            {authors.map((a) => (
              <option key={a.id} value={a.id}>
                {a.name}
              </option>
            ))}
          </select>
        </td>
        <td className="py-2 px-3">{book.published_year || '—'}</td>
        <td className="py-2 px-3 flex gap-2">
          <button disabled={busy} onClick={saveEdit} className="text-sm text-emerald-700">
            Save
          </button>
          <button disabled={busy} onClick={() => setEditing(false)} className="text-sm text-slate-500">
            Cancel
          </button>
        </td>
      </tr>
    );
  }

  return (
    <tr className="border-b border-slate-200">
      <td className="py-2 px-3">{book.title}</td>
      <td className="py-2 px-3">{book.author_name}</td>
      <td className="py-2 px-3">{book.published_year || '—'}</td>
      <td className="py-2 px-3 flex gap-2">
        <button disabled={busy} onClick={() => setEditing(true)} className="text-sm text-slate-600">
          Edit
        </button>
        <button disabled={busy} onClick={remove} className="text-sm text-red-600">
          Delete
        </button>
      </td>
    </tr>
  );
}

function App() {
  const [authors, setAuthors] = useState([]);
  const [books, setBooks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  async function loadAll() {
    setLoading(true);
    setError(null);
    try {
      const [authorsData, booksData] = await Promise.all([api.getAuthors(), api.getBooks()]);
      setAuthors(authorsData);
      setBooks(booksData);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadAll();
  }, []);

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="bg-slate-800 text-white px-6 py-4">
        <h1 className="text-xl font-semibold">Library Catalog</h1>
      </header>

      <main className="max-w-5xl mx-auto p-6 grid grid-cols-1 md:grid-cols-3 gap-6">
        <section className="bg-white rounded-lg shadow p-4">
          <h2 className="font-semibold text-slate-800">Authors</h2>
          <ul className="mt-3 divide-y divide-slate-100 text-sm">
            {authors.map((a) => (
              <li key={a.id} className="py-2">
                <p className="font-medium text-slate-800">{a.name}</p>
                {a.bio && <p className="text-slate-500 text-xs mt-0.5">{a.bio}</p>}
              </li>
            ))}
          </ul>
          <AuthorForm onCreated={loadAll} />
        </section>

        <section className="bg-white rounded-lg shadow p-4 md:col-span-2">
          <h2 className="font-semibold text-slate-800">Books</h2>
          {error && <p className="text-red-600 text-sm mt-2">{error}</p>}
          {loading ? (
            <p className="text-slate-500 text-sm mt-3">Loading…</p>
          ) : (
            <table className="w-full mt-3 text-sm">
              <thead>
                <tr className="text-left text-slate-500 border-b border-slate-200">
                  <th className="py-2 px-3">Title</th>
                  <th className="py-2 px-3">Author</th>
                  <th className="py-2 px-3">Year</th>
                  <th className="py-2 px-3">Actions</th>
                </tr>
              </thead>
              <tbody>
                {books.map((b) => (
                  <BookRow key={b.id} book={b} authors={authors} onChanged={loadAll} />
                ))}
              </tbody>
            </table>
          )}
          <BookForm authors={authors} onCreated={loadAll} />
        </section>
      </main>
    </div>
  );
}

export default App;
