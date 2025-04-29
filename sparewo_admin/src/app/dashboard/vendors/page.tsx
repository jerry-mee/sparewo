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

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
  };

  const filteredVendors = vendors.filter(vendor => {
    const searchLower = searchQuery.toLowerCase();
    return (
      (vendor.name && vendor.name.toLowerCase().includes(searchLower)) ||
      (vendor.email && vendor.email.toLowerCase().includes(searchLower)) ||
      (vendor.businessName && vendor.businessName.toLowerCase().includes(searchLower))
    );
  });

  const approvedCount = vendors.filter(v => v.status === 'approved').length;
  const pendingCount = vendors.filter(v => v.status === 'pending').length;

  return (
    <div className="space-y-6 w-full">
      <div className="flex flex-col gap-2">
        <h1 className="text-2xl font-semibold">Vendors</h1>
        <p className="text-gray-500 dark:text-gray-400">
          Manage and review vendor accounts
        </p>
      </div>
      
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
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
              Approved
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="text-3xl font-bold">{approvedCount}</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="py-4">
            <CardTitle className="flex items-center gap-2 text-lg font-medium">
              <Users className="h-5 w-5 text-amber-500" />
              Pending
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-4">
            <div className="text-3xl font-bold">{pendingCount}</div>
          </CardContent>
        </Card>
      </div>
      
      <Card>
        <CardHeader className="p-4 sm:p-6">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <CardTitle>Vendor List</CardTitle>
            
            <div className="flex flex-col sm:flex-row gap-2 w-full sm:w-auto">
              <form onSubmit={handleSearch} className="flex w-full sm:w-auto">
                <Input
                  placeholder="Search vendors..."
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
                  <TableHead className="w-[20%]">Vendor Name</TableHead>
                  <TableHead className="w-[25%]">Business Name</TableHead>
                  <TableHead className="w-[25%]">Email</TableHead>
                  <TableHead className="w-[15%]">Date Joined</TableHead>
                  <TableHead className="w-[10%]">Status</TableHead>
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
                ) : filteredVendors.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-10">
                      No vendors found
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredVendors.map((vendor) => (
                    <TableRow key={vendor.id} className="hover:bg-gray-50 dark:hover:bg-gray-800">
                      <TableCell className="font-medium truncate">
                        {vendor.name || 'Unnamed'}
                      </TableCell>
                      <TableCell className="truncate">
                        {vendor.businessName || 'No business name'}
                      </TableCell>
                      <TableCell className="truncate">
                        {vendor.email || 'No email'}
                      </TableCell>
                      <TableCell>
                        {vendor.createdAt ? formatDate(vendor.createdAt) : 'Unknown date'}
                      </TableCell>
                      <TableCell>
                        <VendorStatusBadge status={vendor.status} />
                      </TableCell>
                      <TableCell className="text-right p-0 pr-2">
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