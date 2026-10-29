'use client';

/** Route-level failure: says what broke and offers one recovery action. */
export default function ConsoleError({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div className="empty-state" role="alert">
      <strong>This page could not load</strong>
      <span>{error.message || 'Something went wrong while fetching data.'}</span>
      <button type="button" className="btn btn-primary" style={{ marginTop: 10 }} onClick={reset}>
        Try again
      </button>
    </div>
  );
}
