"use client";

import { useState, useEffect, useMemo } from "react";
import { useRouter } from "next/navigation";
import { getVendors } from "@/lib/firebase/vendors";
import { Vendor } from "@/lib/types/vendor";
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
import { VendorStatusBadge } from "@/components/vendor/vendor-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatDate } from "@/lib/utils";
import Link from "next/link";
import { Search, ChevronRight, Users, UserCheck, Clock3 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function VendorsPage() {
  const router = useRouter();
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

  const handleSearch = (event: React.FormEvent) => {
    event.preventDefault();
  };

  const filteredVendors = useMemo(
    () =>
      vendors.filter(
        (vendor) =>
          vendor.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          vendor.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
          vendor.businessName.toLowerCase().includes(searchQuery.toLowerCase())
      ),
    [vendors, searchQuery]
  );

  const approvedCount = useMemo(() => vendors.filter((vendor) => vendor.status === "approved").length, [vendors]);
  const pendingCount = useMemo(() => vendors.filter((vendor) => vendor.status === "pending").length, [vendors]);

  const summaryCards = [
    {
      key: "all",
      label: "Total Vendors",
      value: vendors.length,
      icon: <Users className="h-4 w-4 text-indigo-600" />,
      active: statusFilter === "all",
      onClick: () => setStatusFilter("all"),
    },
    {
      key: "approved",
      label: "Approved Vendors",
      value: approvedCount,
      icon: <UserCheck className="h-4 w-4 text-green-600" />,
      active: statusFilter === "approved",
      onClick: () => setStatusFilter("approved"),
    },
    {
      key: "pending",
      label: "Pending Vendors",
      value: pendingCount,
      icon: <Clock3 className="h-4 w-4 text-amber-500" />,
      active: statusFilter === "pending",
      onClick: () => setStatusFilter("pending"),
    },
  ];

  return (
    <div className="space-y-4">
      <div className="mb-2 flex flex-col gap-1">
        <h1 className="text-xl font-semibold md:text-2xl">Vendors</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">Manage and review vendor accounts</p>
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {summaryCards.map((card) => (
          <button key={card.key} type="button" onClick={card.onClick} className="text-left">
            <Card className={`shadow-sm transition-colors hover:border-primary/50 ${card.active ? "border-primary/60 bg-primary/5" : ""}`}>
              <CardHeader className="px-4 py-3">
                <CardTitle className="flex items-center gap-2 text-md font-medium">
                  {card.icon}
                  {card.label}
                </CardTitle>
              </CardHeader>
              <CardContent className="px-4 pb-3">
                <div className="text-2xl font-bold">{card.value}</div>
              </CardContent>
            </Card>
          </button>
        ))}
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
                  onChange={(event) => setSearchQuery(event.target.value)}
                  className="rounded-r-none text-sm h-9"
                />
                <Button type="submit" className="rounded-l-none px-3 h-9">
                  <Search size={16} />
                </Button>
              </form>

              <Select value={statusFilter} onValueChange={setStatusFilter}>
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
                    <TableCell colSpan={6} className="py-10 text-center">
                      <div className="flex justify-center">
                        <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
                      </div>
                    </TableCell>
                  </TableRow>
                ) : filteredVendors.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="py-10 text-center">
                      No vendors found
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredVendors.map((vendor) => (
                    <TableRow
                      key={vendor.id}
                      className="cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800"
                      onClick={() => router.push(`/dashboard/vendors/${vendor.id}`)}
                    >
                      <TableCell className="max-w-[120px] truncate font-medium">{vendor.name}</TableCell>
                      <TableCell className="max-w-[120px] truncate">{vendor.businessName}</TableCell>
                      <TableCell className="max-w-[120px] truncate">{vendor.email}</TableCell>
                      <TableCell className="whitespace-nowrap">{formatDate(vendor.createdAt)}</TableCell>
                      <TableCell>
                        <VendorStatusBadge status={vendor.status} isSuspended={vendor.isSuspended} />
                      </TableCell>
                      <TableCell className="text-right" onClick={(event) => event.stopPropagation()}>
                        <Link href={`/dashboard/vendors/${vendor.id}`}>
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-8 w-8 p-0 hover:bg-gray-100 dark:hover:bg-gray-700"
                            aria-label={`Open vendor ${vendor.name}`}
                          >
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
              <Button variant="outline" onClick={loadMore} disabled={loading || !hasMore} size="sm">
                Load More
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
