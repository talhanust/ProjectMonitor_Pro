import { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [count, setCount] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch('/api/counter')
      .then((res) => {
        if (!res.ok) throw new Error('Failed to fetch');
        return res.json();
      })
      .then((data) => {
        setCount(data.value);
        setLoading(false);
      })
      .catch((err) => {
        console.error('Failed to fetch count:', err);
        setError('Backend connection failed. Make sure the backend is running.');
        setLoading(false);
      });
  }, []);

  const incrementCount = async () => {
    try {
      const response = await fetch('/api/counter/increment', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({}),
      });
      if (!response.ok) throw new Error('Failed to increment');
      const data = await response.json();
      setCount(data.value);
      setError(null);
    } catch (err) {
      console.error('Failed to increment count:', err);
      setError('Failed to increment. Check backend connection.');
    }
  };

  if (loading) {
    return (
      <div className="app">
        <div className="loading">Loading...</div>
      </div>
    );
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>🚀 Engineering App</h1>
        <p className="subtitle">Welcome to your engineering platform</p>

        {error && <div className="error-message">⚠️ {error}</div>}

        {count !== null && (
          <div className="counter-section">
            <p className="count-display">Count: {count}</p>
            <button onClick={incrementCount} className="increment-btn">
              Increment
            </button>
          </div>
        )}

        <div className="server-info">
          <p>Frontend: http://localhost:3000</p>
          <p>Backend API: http://localhost:8080</p>
        </div>
      </header>
    </div>
  );
}

export default App;
