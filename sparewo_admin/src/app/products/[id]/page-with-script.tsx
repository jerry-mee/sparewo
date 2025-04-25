// This approach uses client-side script loading
// This avoids the "use client" + generateStaticParams conflict

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
      
      <script
        dangerouslySetInnerHTML={{
          __html: `
            document.addEventListener('DOMContentLoaded', function() {
              const productId = "${params.id}";
              const placeholder = document.getElementById('product-content-placeholder');
              
              // Show loading state
              if (placeholder) {
                placeholder.innerHTML = '<div class="animate-pulse bg-gray-200 h-32 rounded-md"></div>';
              }
              
              // Load the client component script
              const script = document.createElement('script');
              script.src = '/products/client.js'; // You'll need to build and place this client script
              script.onload = function() {
                // Once loaded, initialize the client component with the product ID
                if (window.renderProductDetails && placeholder) {
                  window.renderProductDetails(productId, placeholder);
                }
              };
              document.body.appendChild(script);
            });
          `,
        }}
      />
    </div>
  );
}