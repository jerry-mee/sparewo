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
import { formatCurrency, formatDate } from "@/lib/utils";
import Link from "next/link";
import { Search, ChevronRight } from "lucide-react";

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  // Fetch products on component mount and when filters change
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

  // Load more products
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

  // Handle search
  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    // In a real app, this would search by calling the Firebase function
    console.log("Searching for:", searchQuery);
    // For now, we'll just filter the client-side data
    // This is just for demonstration - in a real app, you'd search the database
  };

  // Filter products by search query (client-side filtering for demo)
  const filteredProducts = products.filter(product =>
    product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    product.brand.toLowerCase().includes(searchQuery.toLowerCase()) ||
    product.category.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Products</h1>
          <p className="text-gray-500 dark:text-gray-400">
            Manage and review all products
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-2">
          <form onSubmit={handleSearch} className="flex w-full sm:w-auto">
            <Input
              placeholder="Search products..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="rounded-r-none"
            />
            <Button type="submit" className="rounded-l-none">
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

      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Product Name</TableHead>
              <TableHead>Category</TableHead>
              <TableHead>Brand</TableHead>
              <TableHead>Price</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Action</TableHead>
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
                <TableRow key={product.id}>
                  <TableCell>{product.name}</TableCell>
                  <TableCell>{product.category}</TableCell>
                  <TableCell>{product.brand}</TableCell>
                  <TableCell>{formatCurrency(product.price)}</TableCell>
                  <TableCell>
                    <ProductStatusBadge status={product.status} />
                  </TableCell>
                  <TableCell className="text-right">
                    <Link href={`/dashboard/products/${product.id}`}>
                      <Button variant="ghost" size="icon">
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
        <div className="flex justify-center mt-4">
          <Button
            variant="outline"
            onClick={loadMore}
            disabled={loading || !hasMore}
          >
            Load More
          </Button>
        </div>
      )}
    </div>
  );
}
