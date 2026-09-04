interface PageProps {
  params: Promise<{ city: string }>;
}

export default async function SafetyPage({ params }: PageProps) {
  const { city } = await params;

  return (
    <>
      <div className="page-header">
        <h1>Safety</h1>
        <p>SOS board — {city}</p>
      </div>
    </>
  );
}
