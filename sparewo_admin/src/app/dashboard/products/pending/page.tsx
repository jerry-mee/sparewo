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
import { Textarea } from "@/components/ui/textarea"; // Fixed import
import { Checkbox } from "@/components/ui/checkbox";
import { ProductStatusBadge } from "@/components/product/product-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatCurrency, formatDate } from "@/lib/utils";
import Link from "next/link";
import { CheckCircle, XCircle, ChevronRight } from "lucide-react";
import { toast } from "sonner";

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

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Pending Products</h1>
        <p className="text-gray-500 dark:text-gray-400">
          Review and approve product submissions
        </p>
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
              <TableHead className="text-right">Actions</TableHead>
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
            ) : products.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  No pending products
                </TableCell>
              </TableRow>
            ) : (
              products.map((product) => (
                <TableRow key={product.id}>
                  <TableCell>{product.name}</TableCell>
                  <TableCell>{product.category}</TableCell>
                  <TableCell>{product.brand}</TableCell>
                  <TableCell>{formatCurrency(product.price)}</TableCell>
                  <TableCell>
                    <ProductStatusBadge status={product.status} />
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end items-center space-x-2">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => openApproveDialog(product)}
                        className="text-green-500 hover:text-green-600 hover:bg-green-50"
                      >
                        <CheckCircle size={18} />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => openRejectDialog(product)}
                        className="text-red-500 hover:text-red-600 hover:bg-red-50"
                      >
                        <XCircle size={18} />
                      </Button>
                      <Link href={`/dashboard/products/${product.id}`}>
                        <Button variant="ghost" size="icon">
                          <ChevronRight size={18} />
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
      
      {/* Approval/Rejection Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {dialogAction === "approve" ? "Approve Product" : "Reject Product"}
            </DialogTitle>
            <DialogDescription>
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
              className="min-h-[100px]"
            />
          )}
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleConfirm}
              variant={dialogAction === "approve" ? "default" : "destructive"}
              disabled={dialogAction === "reject" && !rejectionReason.trim()}
            >
              {dialogAction === "approve" ? "Approve" : "Reject"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}