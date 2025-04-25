export const dynamic = 'force-static';

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-4 text-center">
      <h1 className="text-4xl font-bold mb-4">SpareWo Admin Dashboard</h1>
      <p className="text-xl mb-8">Vendor and Product Management</p>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl">
        <a href="/vendors" className="p-6 bg-blue-100 rounded-lg hover:bg-blue-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Vendors</h2>
          <p>Manage vendor applications and approvals</p>
        </a>
        <a href="/products" className="p-6 bg-green-100 rounded-lg hover:bg-green-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Products</h2>
          <p>Manage product catalog and approvals</p>
        </a>
        <a href="/catalogs" className="p-6 bg-purple-100 rounded-lg hover:bg-purple-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Catalogs</h2>
          <p>Manage general and store catalogs</p>
        </a>
        <a href="/orders" className="p-6 bg-orange-100 rounded-lg hover:bg-orange-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Orders</h2>
          <p>Track and manage customer orders</p>
        </a>
      </div>
    </div>
  );
}
