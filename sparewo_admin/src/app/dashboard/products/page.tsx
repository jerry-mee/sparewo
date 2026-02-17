// src/app/dashboard/products/page.tsx
"use client";

import { useState, useEffect, useMemo } from "react";
import { useRouter } from "next/navigation";
import { getProducts } from "@/lib/firebase/products";
import { Product } from "@/lib/types/product";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ProductStatusBadge } from "@/components/product/product-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatCurrency } from "@/lib/utils";
import Link from "next/link";
import { Search, ChevronRight, Package, ShoppingBag, Clock, BadgeCheck } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

type ProductFilter = "all" | "pending" | "approved" | "catalog";

export default function ProductsPage() {
  const router = useRouter();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [quickFilter, setQuickFilter] = useState<ProductFilter>("all");
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

  const handleSearch = (event: React.FormEvent) => {
    event.preventDefault();
  };

  const approvedCount = useMemo(() => products.filter((product) => product.status === "approved").length, [products]);
  const pendingCount = useMemo(() => products.filter((product) => product.status === "pending").length, [products]);
  const catalogCount = useMemo(
    () => products.filter((product) => product.status === "approved" && product.showInCatalog).length,
    [products]
  );

  const filteredProducts = useMemo(() => {
    const queryNeedle = searchQuery.toLowerCase();

    return products.filter((product) => {
      const matchesText =
        product.name.toLowerCase().includes(queryNeedle) ||
        product.brand.toLowerCase().includes(queryNeedle) ||
        product.category.toLowerCase().includes(queryNeedle);

      if (!matchesText) return false;

      if (quickFilter === "catalog") {
        return product.status === "approved" && product.showInCatalog;
      }

      if (quickFilter === "approved") {
        return product.status === "approved";
      }

      if (quickFilter === "pending") {
        return product.status === "pending";
      }

      return true;
    });
  }, [products, searchQuery, quickFilter]);

  const handleQuickFilter = (filter: ProductFilter) => {
    setQuickFilter(filter);
    if (filter === "catalog" || filter === "all") {
      setStatusFilter("all");
      return;
    }

    setStatusFilter(filter);
  };

  useEffect(() => {
    if (statusFilter === "all" && quickFilter !== "catalog") {
      setQuickFilter("all");
      return;
    }

    if (statusFilter === "pending" || statusFilter === "approved") {
      setQuickFilter(statusFilter);
    }
  }, [statusFilter, quickFilter]);

  const summaryCards = [
    {
      key: "all",
      label: "Total Products",
      value: products.length,
      icon: <Package className="h-5 w-5 text-indigo-600" />,
      active: quickFilter === "all",
      onClick: () => handleQuickFilter("all"),
    },
    {
      key: "catalog",
      label: "In Catalog",
      value: catalogCount,
      icon: <ShoppingBag className="h-5 w-5 text-green-500" />,
      active: quickFilter === "catalog",
      onClick: () => handleQuickFilter("catalog"),
    },
    {
      key: "pending",
      label: "Pending Review",
      value: pendingCount,
      icon: <Clock className="h-5 w-5 text-amber-500" />,
      active: quickFilter === "pending",
      onClick: () => handleQuickFilter("pending"),
    },
    {
      key: "approved",
      label: "Approved",
      value: approvedCount,
      icon: <BadgeCheck className="h-5 w-5 text-blue-500" />,
      active: quickFilter === "approved",
      onClick: () => handleQuickFilter("approved"),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-2">
        <h1 className="text-2xl font-semibold">Products</h1>
        <p className="text-muted-foreground">Manage and review all products</p>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
        {summaryCards.map((card) => (
          <button key={card.key} type="button" onClick={card.onClick} className="text-left">
            <Card className={`transition-colors hover:border-primary/50 ${card.active ? "border-primary/60 bg-primary/5" : ""}`}>
              <CardHeader className="py-4">
                <CardTitle className="flex items-center gap-2 text-lg font-medium">
                  {card.icon}
                  {card.label}
                </CardTitle>
              </CardHeader>
              <CardContent className="pb-4">
                <div className="text-3xl font-bold">{card.value}</div>
              </CardContent>
            </Card>
          </button>
        ))}
      </div>

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <CardTitle>Product List</CardTitle>

            <div className="flex flex-col gap-2 sm:flex-row">
              <form onSubmit={handleSearch} className="flex w-full sm:w-auto">
                <Input
                  placeholder="Search products..."
                  value={searchQuery}
                  onChange={(event) => setSearchQuery(event.target.value)}
                  className="rounded-r-none"
                />
                <Button type="submit" className="rounded-l-none">
                  <Search size={18} />
                </Button>
              </form>

              <Select value={statusFilter} onValueChange={setStatusFilter}>
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

        <CardContent>
          <div className="overflow-hidden rounded-lg border">
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
                    <TableCell colSpan={6} className="py-10 text-center">
                      <div className="flex justify-center">
                        <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
                      </div>
                    </TableCell>
                  </TableRow>
                ) : filteredProducts.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="py-10 text-center">
                      No products found
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredProducts.map((product) => (
                    <TableRow
                      key={product.id}
                      className="cursor-pointer hover:bg-muted/40"
                      onClick={() => router.push(`/dashboard/products/${product.id}`)}
                    >
                      <TableCell className="font-medium">{product.name}</TableCell>
                      <TableCell>{product.category}</TableCell>
                      <TableCell>{product.brand}</TableCell>
                      <TableCell>{formatCurrency(product.price)}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <ProductStatusBadge status={product.status} />
                          {product.showInCatalog && product.status === "approved" && (
                            <span className="rounded-full bg-blue-100 px-2 py-0.5 text-xs text-blue-800">Catalog</span>
                          )}
                        </div>
                      </TableCell>
                      <TableCell className="text-right" onClick={(event) => event.stopPropagation()}>
                        <Link href={`/dashboard/products/${product.id}`}>
                          <Button
                            variant="ghost"
                            size="sm"
                            className="hover:bg-muted/60"
                            aria-label={`Open product ${product.name}`}
                          >
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
            <div className="mt-4 flex justify-center">
              <Button variant="outline" onClick={loadMore} disabled={loading || !hasMore} className="mt-4">
                Load More
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
