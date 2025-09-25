import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import App from '../App';

describe('App Component', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ value: 5 }),
    });
  });

  it('renders the title', async () => {
    render(<App />);

    expect(screen.getByText(/Loading/i)).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText(/Engineering App/i)).toBeInTheDocument();
    });

    expect(screen.getByText(/Welcome to your engineering platform/i)).toBeInTheDocument();
  });

  it('displays the counter after loading', async () => {
    render(<App />);

    await waitFor(() => {
      expect(screen.getByText(/Count: 5/i)).toBeInTheDocument();
    });

    expect(screen.getByRole('button', { name: /Increment/i })).toBeInTheDocument();
  });

  it('handles fetch error gracefully', async () => {
    global.fetch = vi.fn().mockRejectedValue(new Error('Network error'));

    render(<App />);

    await waitFor(() => {
      expect(screen.getByText(/Backend connection failed/i)).toBeInTheDocument();
    });
  });
});
