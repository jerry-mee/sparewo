"use client";

import { useState, useEffect } from "react";
import { getVendors } from "@/lib/firebase/vendors";
import { Vendor } from "@/lib/types/vendor";
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
import { VendorStatusBadge } from "@/components/vendor/vendor-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatDate } from "@/lib/utils";
import Link from "next/link";
import { Search, ChevronRight, Users } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function VendorsPage() {
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  // Fetch vendors on component mount and when filters change
  useEffect(() => {
    const fetchVendors = async () => {
      setLoading(true);
      try {
        const status = statusFilter === "all" ? null : statusFilter;
        const result = await getVendors(status, 10);
        setVendors(result.vendors);
        setLastDoc(result.lastDoc);
        setHasMore(result.vendors.length === 10);
      } catch (error) {
        console.error("Error fetching vendors:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchVendors();
  }, [statusFilter]);

  // Load more vendors
  const loadMore = async () => {
    if (!lastDoc) return;
    
    try {
      const status = statusFilter === "all" ? null : statusFilter;
      const result = await getVendors(status, 10, lastDoc);
      setVendors([...vendors, ...result.vendors]);
      setLastDoc(result.lastDoc);
      setHasMore(result.vendors.length === 10);
    } catch (error) {
      console.error("Error loading more vendors:", error);
    }
  };

  // Handle search
  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    // In a real app, this would search by calling the Firebase function
  };

  // Filter vendors by search query (client-side filtering for demo)
  const filteredVendors = vendors.filter(vendor => 
    vendor.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    vendor.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
    vendor.businessName.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-2">
        <h1 className="text-2xl font-semibold">Vendors</h1>
        <p className="text-gray-500 dark:text-gray-400">
          Manage and review vendor accounts
        </p>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <Card>
          <CardHeader className="py-4">
            <CardTitle className="flex items-center gap-2 text-lg font-medium">
              <Users className="h-5 w-5 text-indigo-600" />
              Total Vendors
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="text-3xl font-bold">{vendors.length}</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="py-4">
            <CardTitle className="flex items-center gap-2 text-lg font-medium">
              <Users className="h-5 w-5 text-green-500" />
              Approved Vendors
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="text-3xl font-bold">
              {vendors.filter(v => v.status === 'approved').length}
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="py-4">
            <CardTitle className="flex items-center gap-2 text-lg font-medium">
              <Users className="h-5 w-5 text-amber-500" />
              Pending Vendors
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="text-3xl font-bold">
              {vendors.filter(v => v.status === 'pending').length}
            </div>
          </CardContent>
        </Card>
      </div>
      
      <Card>
        <CardHeader>
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <CardTitle>Vendor List</CardTitle>
            
            <div className="flex flex-col sm:flex-row gap-2">
              <form onSubmit={handleSearch} className="flex w-full sm:w-auto">
                <Input
                  placeholder="Search vendors..."
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
        </CardHeader>
        
        <CardContent>
          <div className="border rounded-lg overflow-hidden">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Vendor Name</TableHead>
                  <TableHead>Business Name</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Date Joined</TableHead>
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
                ) : filteredVendors.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-10">
                      No vendors found
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredVendors.map((vendor) => (
                    <TableRow key={vendor.id} className="hover:bg-gray-50 dark:hover:bg-gray-800">
                      <TableCell className="font-medium">{vendor.name}</TableCell>
                      <TableCell>{vendor.businessName}</TableCell>
                      <TableCell>{vendor.email}</TableCell>
                      <TableCell>{formatDate(vendor.createdAt)}</TableCell>
                      <TableCell>
                        <VendorStatusBadge status={vendor.status} />
                      </TableCell>
                      <TableCell className="text-right">
                        <Link href={`/dashboard/vendors/${vendor.id}`}>
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
            <div className="flex justify-center mt-4">
              <Button
                variant="outline"
                onClick={loadMore}
                disabled={loading || !hasMore}
                className="mt-4"
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