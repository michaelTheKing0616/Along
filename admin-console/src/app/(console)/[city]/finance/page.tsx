interface PageProps {
  params: Promise<{ city: string }>;
}

export default async function FinancePage({ params }: PageProps) {
  const { city } = await params;

  return (
    <>
      <div className="page-header">
        <h1>Finance</h1>
        <p>Ledger and adjustments — {city}</p>
      </div>
    </>
  );
}
