const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000';

async function request(path, options = {}) {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || `Request failed: ${res.status}`);
  }
  if (res.status === 204) return null;
  return res.json();
}

export const api = {
  getAuthors: () => request('/api/authors'),
  createAuthor: (data) => request('/api/authors', { method: 'POST', body: JSON.stringify(data) }),
  getBooks: () => request('/api/books'),
  createBook: (data) => request('/api/books', { method: 'POST', body: JSON.stringify(data) }),
  updateBook: (id, data) => request(`/api/books/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  deleteBook: (id) => request(`/api/books/${id}`, { method: 'DELETE' }),
};
