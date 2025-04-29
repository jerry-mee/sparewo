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
    <div className="space-y-4">
      <div className="flex flex-col gap-1 mb-2">
        <h1 className="text-xl md:text-2xl font-semibold">Vendors</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Manage and review vendor accounts
        </p>
      </div>
      
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
        <Card className="shadow-sm">
          <CardHeader className="py-3 px-4">
            <CardTitle className="flex items-center gap-2 text-md font-medium">
              <Users className="h-4 w-4 text-indigo-600" />
              Total Vendors
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-3 px-4">
            <div className="text-2xl font-bold">{vendors.length}</div>
          </CardContent>
        </Card>
        
        <Card className="shadow-sm">
          <CardHeader className="py-3 px-4">
            <CardTitle className="flex items-center gap-2 text-md font-medium">
              <Users className="h-4 w-4 text-green-500" />
              Approved Vendors
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-3 px-4">
            <div className="text-2xl font-bold">
              {vendors.filter(v => v.status === 'approved').length}
            </div>
          </CardContent>
        </Card>
        
        <Card className="shadow-sm sm:col-span-2 lg:col-span-1">
          <CardHeader className="py-3 px-4">
            <CardTitle className="flex items-center gap-2 text-md font-medium">
              <Users className="h-4 w-4 text-amber-500" />
              Pending Vendors
            </CardTitle>
          </CardHeader>
          <CardContent className="pb-3 px-4">
            <div className="text-2xl font-bold">
              {vendors.filter(v => v.status === 'pending').length}
            </div>
          </CardContent>
        </Card>
      </div>
      
      <Card className="shadow-sm">
        <CardHeader className="py-3 px-4">
          <div className="flex flex-col gap-3">
            <CardTitle>Vendor List</CardTitle>
            
            <div className="flex flex-col gap-2">
              <form onSubmit={handleSearch} className="flex">
                <Input
                  placeholder="Search vendors..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="rounded-r-none text-sm h-9"
                />
                <Button type="submit" className="rounded-l-none px-3 h-9">
                  <Search size={16} />
                </Button>
              </form>
              
              <Select
                value={statusFilter}
                onValueChange={setStatusFilter}
              >
                <SelectTrigger className="h-9 text-sm">
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
                  <TableHead className="whitespace-nowrap">Vendor Name</TableHead>
                  <TableHead className="whitespace-nowrap">Business Name</TableHead>
                  <TableHead className="whitespace-nowrap">Email</TableHead>
                  <TableHead className="whitespace-nowrap">Date Joined</TableHead>
                  <TableHead className="whitespace-nowrap">Status</TableHead>
                  <TableHead className="text-right whitespace-nowrap">Action</TableHead>
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
                      <TableCell className="font-medium truncate max-w-[120px]">{vendor.name}</TableCell>
                      <TableCell className="truncate max-w-[120px]">{vendor.businessName}</TableCell>
                      <TableCell className="truncate max-w-[120px]">{vendor.email}</TableCell>
                      <TableCell className="whitespace-nowrap">{formatDate(vendor.createdAt)}</TableCell>
                      <TableCell>
                        <VendorStatusBadge status={vendor.status} />
                      </TableCell>
                      <TableCell className="text-right">
                        <Link href={`/dashboard/vendors/${vendor.id}`}>
                          <Button variant="ghost" size="sm" className="hover:bg-gray-100 dark:hover:bg-gray-700 h-8 w-8 p-0">
                            <ChevronRight size={16} />
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
    </div>
  );
}