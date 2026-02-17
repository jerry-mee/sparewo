// src/app/dashboard/vendors/pending/page.tsx
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
import { Textarea } from "@/components/ui/textarea";
import { VendorStatusBadge } from "@/components/vendor/vendor-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatDate } from "@/lib/utils";
import Link from "next/link";
import { CheckCircle, XCircle, ChevronRight, Users, Clock, Building } from "lucide-react";
import { toast } from "sonner";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

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

  // Group vendors by businessType
  const vendorsByType: Record<string, Vendor[]> = {};
  vendors.forEach(vendor => {
    if (!vendorsByType[vendor.businessType]) {
      vendorsByType[vendor.businessType] = [];
    }
    vendorsByType[vendor.businessType].push(vendor);
  });

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-1 mb-2">
        <h1 className="text-xl md:text-2xl font-semibold">Pending Vendors</h1>
        <p className="text-sm text-muted-foreground">
          Review and approve vendor registration requests
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
            <div className="text-2xl font-bold">{vendors.length}</div>
          </CardContent>
        </Card>
        
        <Card className="shadow-sm">
          <CardHeader className="py-3 px-4">
            <CardTitle className="flex items-center gap-2 text-md font-medium">
              <Building className="h-4 w-4 text-indigo-600" />
              Types
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-3 px-4">
            <div className="text-2xl font-bold">{Object.keys(vendorsByType).length}</div>
          </CardContent>
        </Card>
        
        <Card className="shadow-sm">
          <CardHeader className="py-3 px-4">
            <CardTitle className="flex items-center gap-2 text-md font-medium truncate">
              <Users className="h-4 w-4 text-purple-500 flex-shrink-0" />
              Oldest
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-3 px-4">
            <div className="text-sm font-medium truncate">
              {vendors.length > 0 ? formatDate(vendors[vendors.length - 1]?.createdAt) : 'None'}
            </div>
          </CardContent>
        </Card>
      </div>
      
      <Card className="shadow-sm">
        <CardHeader className="py-3 px-4">
          <CardTitle>Pending Vendors</CardTitle>
          <CardDescription className="text-sm">
            Vendors awaiting your review
          </CardDescription>
        </CardHeader>
        
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="whitespace-nowrap">Vendor Name</TableHead>
                  <TableHead className="whitespace-nowrap">Business</TableHead>
                  <TableHead className="whitespace-nowrap">Email</TableHead>
                  <TableHead className="whitespace-nowrap">Joined</TableHead>
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
                ) : vendors.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-6">
                      <div className="flex flex-col items-center gap-1">
                        <Users className="h-6 w-6 text-muted-foreground" />
                        <p className="text-muted-foreground text-sm">No pending vendors</p>
                      </div>
                    </TableCell>
                  </TableRow>
                ) : (
                  vendors.map((vendor) => (
                    <TableRow key={vendor.id} className="hover:bg-muted/40">
                      <TableCell className="font-medium truncate max-w-[120px]">{vendor.name}</TableCell>
                      <TableCell className="truncate max-w-[120px]">{vendor.businessName}</TableCell>
                      <TableCell className="truncate max-w-[120px]">{vendor.email}</TableCell>
                      <TableCell className="whitespace-nowrap">{formatDate(vendor.createdAt)}</TableCell>
                      <TableCell>
                        <VendorStatusBadge status={vendor.status} isSuspended={vendor.isSuspended} />
                      </TableCell>
                      <TableCell className="text-right p-0 pr-2">
                        <div className="flex justify-end items-center space-x-1">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => openApproveDialog(vendor)}
                            className="text-green-600 hover:text-green-700 hover:bg-green-50 h-8 w-8 p-0"
                          >
                            <CheckCircle size={16} />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => openRejectDialog(vendor)}
                            className="text-red-600 hover:text-red-700 hover:bg-red-50 h-8 w-8 p-0"
                          >
                            <XCircle size={16} />
                          </Button>
                          <Link href={`/dashboard/vendors/${vendor.id}`}>
                            <Button variant="ghost" size="sm" className="hover:bg-muted/60 h-8 w-8 p-0">
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
              {dialogAction === "approve" ? "Approve Vendor" : "Reject Vendor"}
            </DialogTitle>
            <DialogDescription className="text-sm">
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