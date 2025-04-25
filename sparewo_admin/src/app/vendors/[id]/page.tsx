// Static shell page
export const dynamic = 'force-static';

export function generateStaticParams() {
  return [];
}

export default function VendorPage({ params }: { params: { id: string } }) {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold mb-4">Vendor Details</h1>
      <p>Loading vendor ID: {params.id}...</p>
      <div id="vendor-content-placeholder"></div>
    </div>
  );
}
