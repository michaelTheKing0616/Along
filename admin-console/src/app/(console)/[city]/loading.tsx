/** Route-level skeleton: header, filter row and a table-shaped block. */
export default function Loading() {
  return (
    <div aria-busy="true" aria-label="Loading">
      <div className="page-header">
        <span className="skeleton" style={{ width: 220, height: 28, marginBottom: 10 }} />
        <span className="skeleton" style={{ width: 420, height: 14 }} />
      </div>
      <div className="kpi-grid">
        {[0, 1, 2, 3].map((i) => (
          <span key={i} className="skeleton" style={{ height: 84 }} />
        ))}
      </div>
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <span key={i} className="skeleton" style={{ height: 36, marginBottom: 6 }} />
      ))}
    </div>
  );
}
