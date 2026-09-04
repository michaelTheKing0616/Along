interface PageProps {
  params: Promise<{ city: string }>;
}

export default async function VerificationPage({ params }: PageProps) {
  const { city } = await params;

  return (
    <>
      <div className="page-header">
        <h1>Verification</h1>
        <p>Driver document review queue — {city}</p>
      </div>
    </>
  );
}
