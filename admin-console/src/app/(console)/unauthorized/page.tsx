import Link from 'next/link';

export default function UnauthorizedPage() {
  return (
    <main className="page-center">
      <div className="card" style={{ maxWidth: '28rem', textAlign: 'center' }}>
        <h1 style={{ marginTop: 0 }}>Unauthorized</h1>
        <p style={{ color: 'var(--color-text-muted)' }}>
          Your role does not have access to this page.
        </p>
        <Link href="/abuja/dashboard">Return to dashboard</Link>
      </div>
    </main>
  );
}
