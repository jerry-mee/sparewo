"use client";

import { useState, useEffect } from "react";
import { getProducts } from "@/lib/firebase/products";
import { Product } from "@/lib/types/product";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { 
  Select, 
  SelectContent, 
  SelectItem, 
  SelectTrigger, 
  SelectValue 
} from "@/components/ui/select";
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table";
import { ProductStatusBadge } from "@/components/product/product-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatCurrency } from "@/lib/utils";
import Link from "next/link";
import { Search, ChevronRight, Package, ShoppingBag, Clock } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  useEffect(() => {
    const fetchProducts = async () => {
      setLoading(true);
      try {
        const status = statusFilter === "all" ? null : statusFilter;
        const result = await getProducts(status, null, 10);
        setProducts(result.products);
        setLastDoc(result.lastDoc);
        setHasMore(result.products.length === 10);
      } catch (error) {
        console.error("Error fetching products:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchProducts();
  }, [statusFilter]);

  const loadMore = async () => {
    if (!lastDoc) return;
    
    try {
      const status = statusFilter === "all" ? null : statusFilter;
      const result = await getProducts(status, null, 10, lastDoc);
      setProducts([...products, ...result.products]);
      setLastDoc(result.lastDoc);
      setHasMore(result.products.length === 10);
    } catch (error) {
      console.error("Error loading more products:", error);
    }
  };

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
  };

  const filteredProducts = products.filter(product => {
    const searchLower = searchQuery.toLowerCase();
    return (
      (product.name && product.name.toLowerCase().includes(searchLower)) ||
      (product.brand && product.brand.toLowerCase().includes(searchLower)) ||
      (product.category && product.category.toLowerCase().includes(searchLower))
    );
  });

  const approvedCount = products.filter(p => p.status === 'approved').length;
  const pendingCount = products.filter(p => p.status === 'pending').length;
  const catalogCount = products.filter(p => p.status === 'approved' && p.showInCatalog).length;

  return (
    <div className="space-y-6 w-full">
      <div className="flex flex-col gap-2">
        <h1 className="text-2xl font-semibold">Products</h1>
        <p className="text-gray-500 dark:text-gray-400">
          Manage and review all products
        </p>
      </div>
      
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="py-4">
            <CardTitle className="flex items-center gap-2 text-lg font-medium">
              <Package className="h-5 w-5 text-indigo-600" />
              Total Products
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="text-3xl font-bold">{products.length}</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="py-4">
            <CardTitle className="flex items-center gap-2 text-lg font-medium">
              <ShoppingBag className="h-5 w-5 text-green-500" />
              In Catalog
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="text-3xl font-bold">{catalogCount}</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="py-4">
            <CardTitle className="flex items-center gap-2 text-lg font-medium">
              <Clock className="h-5 w-5 text-amber-500" />
              Pending Review
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="text-3xl font-bold">{pendingCount}</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="py-4">
            <CardTitle className="flex items-center gap-2 text-lg font-medium">
              <Package className="h-5 w-5 text-blue-500" />
              Approved
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="text-3xl font-bold">{approvedCount}</div>
          </CardContent>
        </Card>
      </div>
      
      <Card>
        <CardHeader className="p-4 sm:p-6">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <CardTitle>Product List</CardTitle>
            
            <div className="flex flex-col sm:flex-row gap-2 w-full sm:w-auto">
              <form onSubmit={handleSearch} className="flex w-full sm:w-auto">
                <Input
                  placeholder="Search products..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="rounded-r-none w-full"
                />
                <Button type="submit" className="rounded-l-none flex-shrink-0">
                  <Search size={18} />
                </Button>
              </form>
              
              <Select
                value={statusFilter}
                onValueChange={setStatusFilter}
              >
                <SelectTrigger className="w-full sm:w-32">
                  <SelectValue placeholder="Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All</SelectItem>
                  <SelectItem value="pending">Pending</SelectItem>
                  <SelectItem value="approved">Approved</SelectItem>
                  <SelectItem value="rejected">Rejected</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-[30%]">Product Name</TableHead>
                  <TableHead className="w-[20%]">Category</TableHead>
                  <TableHead className="w-[15%]">Brand</TableHead>
                  <TableHead className="w-[15%]">Price</TableHead>
                  <TableHead className="w-[15%]">Status</TableHead>
                  <TableHead className="w-[5%] text-right">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-10">
                      <div className="flex justify-center">
                        <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
                      </div>
                    </TableCell>
                  </TableRow>
                ) : filteredProducts.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-10">
                      No products found
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredProducts.map((product) => (
                    <TableRow key={product.id} className="hover:bg-gray-50 dark:hover:bg-gray-800">
                      <TableCell className="font-medium truncate max-w-xs">
                        {product.name || 'Unnamed Product'}
                      </TableCell>
                      <TableCell className="truncate">
                        {product.category || 'Uncategorized'}
                      </TableCell>
                      <TableCell className="truncate">
                        {product.brand || 'Unknown'}
                      </TableCell>
                      <TableCell>
                        {formatCurrency(product.price || 0)}
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2 flex-wrap">
                          <ProductStatusBadge status={product.status} />
                          {product.showInCatalog && product.status === 'approved' && (
                            <span className="px-2 py-0.5 text-xs bg-blue-100 text-blue-800 rounded-full whitespace-nowrap">
                              Catalog
                            </span>
                          )}
                        </div>
                      </TableCell>
                      <TableCell className="text-right p-0 pr-2">
                        <Link href={`/dashboard/products/${product.id}`}>
                          <Button variant="ghost" size="sm" className="hover:bg-gray-100 dark:hover:bg-gray-700">
                            <ChevronRight size={18} />
                          </Button>
                        </Link>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
          
          {hasMore && (
            <div className="flex justify-center py-4">
              <Button
                variant="outline"
                onClick={loadMore}
                disabled={loading || !hasMore}
              >
                Load More
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}