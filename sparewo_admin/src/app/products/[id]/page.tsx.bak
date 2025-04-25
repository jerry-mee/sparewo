// Static shell page
export const dynamic = 'force-static';

export function generateStaticParams() {
  return [];
}

export default function ProductPage({ params }: { params: { id: string } }) {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold mb-4">Product Details</h1>
      <p>Loading product ID: {params.id}...</p>
      <div id="product-content-placeholder"></div>
    </div>
  );
}
