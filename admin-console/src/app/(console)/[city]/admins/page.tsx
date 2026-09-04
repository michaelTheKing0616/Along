interface PageProps {
  params: Promise<{ city: string }>;
}

export default async function AdminsPage({ params }: PageProps) {
  const { city } = await params;

  return (
    <>
      <div className="page-header">
        <h1>Admin users</h1>
        <p>Role management — {city}</p>
      </div>
    </>
  );
}
