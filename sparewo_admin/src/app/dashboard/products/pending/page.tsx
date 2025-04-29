"use client";

import { useState, useEffect } from "react";
import { getPendingProducts, updateProductStatus } from "@/lib/firebase/products";
import { Product } from "@/lib/types/product";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { ProductStatusBadge } from "@/components/product/product-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatCurrency, formatDate } from "@/lib/utils";
import Link from "next/link";
import { CheckCircle, XCircle, ChevronRight, Package, Filter, Clock } from "lucide-react";
import { toast } from "sonner";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function PendingProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  // Dialog state
  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogAction, setDialogAction] = useState<"approve" | "reject">("approve");
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [showInCatalog, setShowInCatalog] = useState(false);

  // Fetch pending products on component mount
  useEffect(() => {
    const fetchProducts = async () => {
      setLoading(true);
      try {
        const result = await getPendingProducts(10);
        setProducts(result.products);
        setLastDoc(result.lastDoc);
        setHasMore(result.products.length === 10);
      } catch (error) {
        console.error("Error fetching pending products:", error);
        toast.error("Failed to load pending products");
      } finally {
        setLoading(false);
      }
    };

    fetchProducts();
  }, []);

  // Load more products
  const loadMore = async () => {
    if (!lastDoc) return;
    
    try {
      const result = await getPendingProducts(10, lastDoc);
      setProducts([...products, ...result.products]);
      setLastDoc(result.lastDoc);
      setHasMore(result.products.length === 10);
    } catch (error) {
      console.error("Error loading more products:", error);
      toast.error("Failed to load more products");
    }
  };

  // Open approval dialog
  const openApproveDialog = (product: Product) => {
    setSelectedProduct(product);
    setDialogAction("approve");
    setShowInCatalog(false);
    setDialogOpen(true);
  };

  // Open rejection dialog
  const openRejectDialog = (product: Product) => {
    setSelectedProduct(product);
    setDialogAction("reject");
    setRejectionReason("");
    setDialogOpen(true);
  };

  // Handle dialog confirmation
  const handleConfirm = async () => {
    if (!selectedProduct) return;
    
    try {
      if (dialogAction === "approve") {
        await updateProductStatus(selectedProduct.id, "approved", showInCatalog);
        toast.success(`Product ${selectedProduct.name} has been approved`);
      } else {
        await updateProductStatus(selectedProduct.id, "rejected", false, rejectionReason);
        toast.success(`Product ${selectedProduct.name} has been rejected`);
      }
      
      // Update the local state to remove the processed product
      setProducts(products.filter(p => p.id !== selectedProduct.id));
    } catch (error) {
      console.error(`Error ${dialogAction}ing product:`, error);
      toast.error(`Failed to ${dialogAction} product`);
    } finally {
      setDialogOpen(false);
      setSelectedProduct(null);
    }
  };

  // Group products by category
  const productsByCategory: Record<string, Product[]> = {};
  products.forEach(product => {
    if (!productsByCategory[product.category]) {
      productsByCategory[product.category] = [];
    }
    productsByCategory[product.category].push(product);
  });

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-1 mb-2">
        <h1 className="text-xl md:text-2xl font-semibold">Pending Products</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Review and approve product submissions
        </p>
      </div>
      
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        <Card className="shadow-sm">
          <CardHeader className="py-3 px-4">
            <CardTitle className="flex items-center gap-2 text-md font-medium">
              <Clock className="h-4 w-4 text-amber-500" />
              Pending
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-3 px-4">
            <div className="text-2xl font-bold">{products.length}</div>
          </CardContent>
        </Card>
        
        <Card className="shadow-sm">
          <CardHeader className="py-3 px-4">
            <CardTitle className="flex items-center gap-2 text-md font-medium">
              <Filter className="h-4 w-4 text-indigo-600" />
              Categories
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-3 px-4">
            <div className="text-2xl font-bold">{Object.keys(productsByCategory).length}</div>
          </CardContent>
        </Card>
        
        <Card className="shadow-sm">
          <CardHeader className="py-3 px-4">
            <CardTitle className="flex items-center gap-2 text-md font-medium truncate">
              <Package className="h-4 w-4 text-purple-500 flex-shrink-0" />
              Oldest
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-3 px-4">
            <div className="text-sm font-medium truncate">
              {products.length > 0 ? formatDate(products[products.length - 1]?.createdAt) : 'None'}
            </div>
          </CardContent>
        </Card>
      </div>
      
      <Card className="shadow-sm">
        <CardHeader className="py-3 px-4">
          <CardTitle>Pending Products</CardTitle>
          <CardDescription className="text-sm">
            Products awaiting your review
          </CardDescription>
        </CardHeader>
        
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="whitespace-nowrap">Product</TableHead>
                  <TableHead className="whitespace-nowrap">Category</TableHead>
                  <TableHead className="whitespace-nowrap">Brand</TableHead>
                  <TableHead className="whitespace-nowrap">Price</TableHead>
                  <TableHead className="whitespace-nowrap">Status</TableHead>
                  <TableHead className="text-right whitespace-nowrap">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-6">
                      <div className="flex justify-center">
                        <div className="w-5 h-5 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
                      </div>
                    </TableCell>
                  </TableRow>
                ) : products.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-6">
                      <div className="flex flex-col items-center gap-1">
                        <Package className="h-6 w-6 text-gray-400" />
                        <p className="text-gray-500 text-sm">No pending products</p>
                      </div>
                    </TableCell>
                  </TableRow>
                ) : (
                  products.map((product) => (
                    <TableRow key={product.id} className="hover:bg-gray-50 dark:hover:bg-gray-800">
                      <TableCell className="font-medium truncate max-w-[120px]">{product.name}</TableCell>
                      <TableCell className="truncate max-w-[100px]">{product.category}</TableCell>
                      <TableCell className="truncate max-w-[100px]">{product.brand}</TableCell>
                      <TableCell className="whitespace-nowrap">{formatCurrency(product.price)}</TableCell>
                      <TableCell>
                        <ProductStatusBadge status={product.status} />
                      </TableCell>
                      <TableCell className="text-right p-0 pr-2">
                        <div className="flex justify-end items-center space-x-1">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => openApproveDialog(product)}
                            className="text-green-600 hover:text-green-700 hover:bg-green-50 h-8 w-8 p-0"
                          >
                            <CheckCircle size={16} />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => openRejectDialog(product)}
                            className="text-red-600 hover:text-red-700 hover:bg-red-50 h-8 w-8 p-0"
                          >
                            <XCircle size={16} />
                          </Button>
                          <Link href={`/dashboard/products/${product.id}`}>
                            <Button variant="ghost" size="sm" className="hover:bg-gray-100 dark:hover:bg-gray-700 h-8 w-8 p-0">
                              <ChevronRight size={16} />
                            </Button>
                          </Link>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
          
          {hasMore && (
            <div className="flex justify-center p-4">
              <Button
                variant="outline"
                onClick={loadMore}
                disabled={loading || !hasMore}
                size="sm"
              >
                Load More
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
      
      {/* Approval/Rejection Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-sm mx-auto">
          <DialogHeader>
            <DialogTitle>
              {dialogAction === "approve" ? "Approve Product" : "Reject Product"}
            </DialogTitle>
            <DialogDescription className="text-sm">
              {dialogAction === "approve"
                ? "Are you sure you want to approve this product?"
                : "Please provide a reason for rejecting this product."}
            </DialogDescription>
          </DialogHeader>
          
          {dialogAction === "approve" && (
            <div className="flex items-center space-x-2 mt-2">
              <Checkbox
                id="show-in-catalog"
                checked={showInCatalog}
                onCheckedChange={(checked: boolean) => 
                  setShowInCatalog(checked)
                }
              />
              <label
                htmlFor="show-in-catalog"
                className="text-sm font-medium leading-none cursor-pointer"
              >
                Show in client-facing catalog
              </label>
            </div>
          )}
          
          {dialogAction === "reject" && (
            <Textarea
              placeholder="Reason for rejection"
              value={rejectionReason}
              onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setRejectionReason(e.target.value)}
              className="min-h-[100px] text-sm"
            />
          )}
          
          <DialogFooter className="flex flex-col sm:flex-row sm:justify-end gap-2 sm:gap-0">
            <Button variant="outline" onClick={() => setDialogOpen(false)} size="sm">
              Cancel
            </Button>
            <Button
              onClick={handleConfirm}
              variant={dialogAction === "approve" ? "default" : "destructive"}
              disabled={dialogAction === "reject" && !rejectionReason.trim()}
              size="sm"
            >
              {dialogAction === "approve" ? "Approve" : "Reject"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}