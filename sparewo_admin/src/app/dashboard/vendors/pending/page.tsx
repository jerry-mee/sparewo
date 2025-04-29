"use client";

import { useState, useEffect } from "react";
import { getPendingVendors, updateVendorStatus } from "@/lib/firebase/vendors";
import { Vendor } from "@/lib/types/vendor";
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
import { Textarea } from "@/components/ui/textarea"; // Fixed import path
import { VendorStatusBadge } from "@/components/vendor/vendor-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatDate } from "@/lib/utils";
import Link from "next/link";
import { CheckCircle, XCircle, ChevronRight } from "lucide-react";
import { toast } from "sonner";

export default function PendingVendorsPage() {
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  // Dialog state
  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogAction, setDialogAction] = useState<"approve" | "reject">("approve");
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");

  // Fetch pending vendors on component mount
  useEffect(() => {
    const fetchVendors = async () => {
      setLoading(true);
      try {
        const result = await getPendingVendors(10);
        setVendors(result.vendors);
        setLastDoc(result.lastDoc);
        setHasMore(result.vendors.length === 10);
      } catch (error) {
        console.error("Error fetching pending vendors:", error);
        toast.error("Failed to load pending vendors");
      } finally {
        setLoading(false);
      }
    };

    fetchVendors();
  }, []);

  // Load more vendors
  const loadMore = async () => {
    if (!lastDoc) return;
    
    try {
      const result = await getPendingVendors(10, lastDoc);
      setVendors([...vendors, ...result.vendors]);
      setLastDoc(result.lastDoc);
      setHasMore(result.vendors.length === 10);
    } catch (error) {
      console.error("Error loading more vendors:", error);
      toast.error("Failed to load more vendors");
    }
  };

  // Open approval dialog
  const openApproveDialog = (vendor: Vendor) => {
    setSelectedVendor(vendor);
    setDialogAction("approve");
    setDialogOpen(true);
  };

  // Open rejection dialog
  const openRejectDialog = (vendor: Vendor) => {
    setSelectedVendor(vendor);
    setDialogAction("reject");
    setRejectionReason("");
    setDialogOpen(true);
  };

  // Handle dialog confirmation
  const handleConfirm = async () => {
    if (!selectedVendor) return;
    
    try {
      if (dialogAction === "approve") {
        await updateVendorStatus(selectedVendor.id, "approved");
        toast.success(`Vendor ${selectedVendor.name} has been approved`);
      } else {
        await updateVendorStatus(selectedVendor.id, "rejected", rejectionReason);
        toast.success(`Vendor ${selectedVendor.name} has been rejected`);
      }
      
      // Update the local state to remove the processed vendor
      setVendors(vendors.filter(v => v.id !== selectedVendor.id));
    } catch (error) {
      console.error(`Error ${dialogAction}ing vendor:`, error);
      toast.error(`Failed to ${dialogAction} vendor`);
    } finally {
      setDialogOpen(false);
      setSelectedVendor(null);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Pending Vendors</h1>
        <p className="text-gray-500 dark:text-gray-400">
          Review and approve vendor registration requests
        </p>
      </div>
      
      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Vendor Name</TableHead>
              <TableHead>Business Name</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Date Joined</TableHead>
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
            ) : vendors.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  No pending vendors
                </TableCell>
              </TableRow>
            ) : (
              vendors.map((vendor) => (
                <TableRow key={vendor.id}>
                  <TableCell>{vendor.name}</TableCell>
                  <TableCell>{vendor.businessName}</TableCell>
                  <TableCell>{vendor.email}</TableCell>
                  <TableCell>{formatDate(vendor.createdAt)}</TableCell>
                  <TableCell>
                    <VendorStatusBadge status={vendor.status} />
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end items-center space-x-2">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => openApproveDialog(vendor)}
                        className="text-green-500 hover:text-green-600 hover:bg-green-50"
                      >
                        <CheckCircle size={18} />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => openRejectDialog(vendor)}
                        className="text-red-500 hover:text-red-600 hover:bg-red-50"
                      >
                        <XCircle size={18} />
                      </Button>
                      <Link href={`/dashboard/vendors/${vendor.id}`}>
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
              {dialogAction === "approve" ? "Approve Vendor" : "Reject Vendor"}
            </DialogTitle>
            <DialogDescription>
              {dialogAction === "approve"
                ? "Are you sure you want to approve this vendor? They will be able to upload products to the marketplace."
                : "Please provide a reason for rejecting this vendor."}
            </DialogDescription>
          </DialogHeader>
          
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