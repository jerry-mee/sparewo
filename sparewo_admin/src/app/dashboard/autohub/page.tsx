"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import {
  createServiceProvider,
  getAllServiceProviders,
  getServiceBookings,
  ServiceBooking,
  ServiceProvider,
  toggleServiceProviderActive,
} from "@/lib/firebase/autohub";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { DocumentData } from "firebase/firestore";
import { formatDate } from "@/lib/utils";
import Link from "next/link";
import { ChevronRight, Wrench, Calendar, MapPin, Plus, ShieldCheck } from "lucide-react";
import { toast } from "sonner";

const getStatusColor = (status: string) => {
  switch (status) {
    case "pending":
      return "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400";
    case "confirmed":
      return "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400";
    case "in_progress":
      return "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400";
    case "completed":
      return "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400";
    case "cancelled":
      return "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

const providerTypes: Array<ServiceProvider["type"]> = ["mechanic", "garage", "towing"];

export default function AutoHubPage() {
  const router = useRouter();
  const [bookings, setBookings] = useState<ServiceBooking[]>([]);
  const [providers, setProviders] = useState<ServiceProvider[]>([]);

  const [loadingBookings, setLoadingBookings] = useState(true);
  const [loadingProviders, setLoadingProviders] = useState(true);

  const [statusFilter, setStatusFilter] = useState("all");
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  const [providerDialogOpen, setProviderDialogOpen] = useState(false);
  const [providerName, setProviderName] = useState("");
  const [providerPhone, setProviderPhone] = useState("");
  const [providerAddress, setProviderAddress] = useState("");
  const [providerEmail, setProviderEmail] = useState("");
  const [providerType, setProviderType] = useState<ServiceProvider["type"]>("mechanic");
  const [creatingProvider, setCreatingProvider] = useState(false);

  const fetchBookings = async (reset = false) => {
    setLoadingBookings(true);
    try {
      const result = await getServiceBookings(statusFilter === "all" ? undefined : statusFilter, 10, reset ? undefined : lastDoc);

      if (reset) {
        setBookings(result.bookings);
      } else {
        setBookings((prev) => [...prev, ...result.bookings]);
      }

      setLastDoc(result.lastDoc);
      setHasMore(result.bookings.length === 10);
    } catch (error) {
      toast.error("Failed to load bookings");
      console.error(error);
    } finally {
      setLoadingBookings(false);
    }
  };

  const fetchProviders = async () => {
    setLoadingProviders(true);
    try {
      const allProviders = await getAllServiceProviders();
      setProviders(allProviders);
    } catch (error) {
      console.error(error);
      toast.error("Failed to load providers");
    } finally {
      setLoadingProviders(false);
    }
  };

  useEffect(() => {
    fetchBookings(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter]);

  useEffect(() => {
    fetchProviders();
  }, []);

  const handleCreateProvider = async () => {
    const name = providerName.trim();
    const phone = providerPhone.trim();
    const address = providerAddress.trim();

    if (!name || !phone || !address) {
      toast.error("Name, phone, and address are required");
      return;
    }

    setCreatingProvider(true);
    try {
      await createServiceProvider({
        name,
        phone,
        address,
        email: providerEmail.trim() || undefined,
        type: providerType,
      });

      toast.success("Service provider added");
      setProviderName("");
      setProviderPhone("");
      setProviderAddress("");
      setProviderEmail("");
      setProviderType("mechanic");
      setProviderDialogOpen(false);
      await fetchProviders();
    } catch (error) {
      console.error(error);
      toast.error("Failed to add provider");
    } finally {
      setCreatingProvider(false);
    }
  };

  const handleToggleProvider = async (provider: ServiceProvider) => {
    try {
      await toggleServiceProviderActive(provider.id, !provider.isActive);
      toast.success(provider.isActive ? "Provider deactivated" : "Provider activated");
      await fetchProviders();
    } catch (error) {
      console.error(error);
      toast.error("Failed to update provider status");
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-semibold tracking-tight">AutoHub Management Center</h1>
        <p className="text-muted-foreground">
          Oversee service requests, field assignments, and provider availability.
        </p>
      </div>

      <Tabs defaultValue="requests">
        <TabsList className="grid w-full max-w-sm grid-cols-2">
          <TabsTrigger value="requests">Service Requests</TabsTrigger>
          <TabsTrigger value="providers">Provider Registry</TabsTrigger>
        </TabsList>

        <TabsContent value="requests" className="mt-6">
          <Card>
            <CardHeader>
              <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <CardTitle>Recent Bookings</CardTitle>
                <div className="w-full sm:w-[220px]">
                  <Select value={statusFilter} onValueChange={setStatusFilter}>
                    <SelectTrigger>
                      <SelectValue placeholder="Filter by status" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Statuses</SelectItem>
                      <SelectItem value="pending">Pending</SelectItem>
                      <SelectItem value="confirmed">Confirmed</SelectItem>
                      <SelectItem value="in_progress">In Progress</SelectItem>
                      <SelectItem value="completed">Completed</SelectItem>
                      <SelectItem value="cancelled">Cancelled</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Booking Ref</TableHead>
                      <TableHead>Customer</TableHead>
                      <TableHead>Vehicle</TableHead>
                      <TableHead>Service Info</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead className="text-right">Action</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {loadingBookings && bookings.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={6} className="h-24 text-center">
                          Loading requests...
                        </TableCell>
                      </TableRow>
                    ) : bookings.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={6} className="h-24 text-center">
                          No bookings found.
                        </TableCell>
                      </TableRow>
                    ) : (
                      bookings.map((item) => (
                        <TableRow key={item.id} className="cursor-pointer hover:bg-muted/40" onClick={() => router.push("/dashboard/autohub/" + item.id)}>
                          <TableCell className="font-mono font-medium">{item.bookingNumber}</TableCell>
                          <TableCell>
                            <div className="flex flex-col">
                              <span>{item.userName}</span>
                              <span className="text-xs text-muted-foreground">{item.userPhone}</span>
                            </div>
                          </TableCell>
                          <TableCell>
                            {item.vehicleYear} {item.vehicleBrand} {item.vehicleModel}
                          </TableCell>
                          <TableCell>
                            <div className="flex flex-col gap-1 text-xs">
                              <div className="flex items-center gap-1">
                                <Wrench className="h-3 w-3 text-muted-foreground" />
                                <span className="truncate max-w-[150px]">{item.services.join(", ")}</span>
                              </div>
                              <div className="flex items-center gap-1">
                                <Calendar className="h-3 w-3 text-muted-foreground" />
                                <span>{formatDate(item.pickupDate)}</span>
                              </div>
                              {item.pickupLocation && (
                                <div className="flex items-center gap-1">
                                  <MapPin className="h-3 w-3 text-muted-foreground" />
                                  <span className="truncate max-w-[150px]">{item.pickupLocation}</span>
                                </div>
                              )}
                            </div>
                          </TableCell>
                          <TableCell>
                            <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${getStatusColor(item.status)}`}>
                              {item.status.replace("_", " ").toUpperCase()}
                            </span>
                          </TableCell>
                          <TableCell className="text-right" onClick={(event) => event.stopPropagation()}>
                            <Link href={"/dashboard/autohub/" + item.id}>
                              <Button variant="ghost" size="icon">
                                <ChevronRight className="h-4 w-4" />
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
                  <Button variant="outline" onClick={() => fetchBookings(false)} disabled={loadingBookings}>
                    {loadingBookings ? "Loading..." : "Load More"}
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="providers" className="mt-6 space-y-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <div>
                <CardTitle>Service Providers</CardTitle>
                <p className="text-sm text-muted-foreground mt-1">
                  Activate/deactivate technicians and garages for AutoHub assignments.
                </p>
              </div>
              <Button onClick={() => setProviderDialogOpen(true)}>
                <Plus className="mr-2 h-4 w-4" /> Add Provider
              </Button>
            </CardHeader>
            <CardContent>
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Name</TableHead>
                      <TableHead>Type</TableHead>
                      <TableHead>Phone</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead className="text-right">Action</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {loadingProviders ? (
                      <TableRow>
                        <TableCell colSpan={5} className="h-24 text-center">
                          Loading providers...
                        </TableCell>
                      </TableRow>
                    ) : providers.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={5} className="h-24 text-center">
                          No providers found.
                        </TableCell>
                      </TableRow>
                    ) : (
                      providers.map((provider) => (
                        <TableRow key={provider.id}>
                          <TableCell>
                            <div>
                              <p className="font-medium">{provider.name}</p>
                              <p className="text-xs text-muted-foreground truncate">{provider.address}</p>
                            </div>
                          </TableCell>
                          <TableCell className="capitalize">{provider.type}</TableCell>
                          <TableCell>{provider.phone}</TableCell>
                          <TableCell>
                            <span
                              className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium ${
                                provider.isActive
                                  ? "bg-green-100 text-green-800"
                                  : "bg-slate-200 text-slate-700"
                              }`}
                            >
                              <ShieldCheck className="h-3 w-3" />
                              {provider.isActive ? "Active" : "Inactive"}
                            </span>
                          </TableCell>
                          <TableCell className="text-right">
                            <Button variant="outline" size="sm" onClick={() => handleToggleProvider(provider)}>
                              {provider.isActive ? "Deactivate" : "Activate"}
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      <Dialog open={providerDialogOpen} onOpenChange={setProviderDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Service Provider</DialogTitle>
          </DialogHeader>

          <div className="space-y-3">
            <Input placeholder="Provider name" value={providerName} onChange={(event) => setProviderName(event.target.value)} />
            <Select value={providerType} onValueChange={(value) => setProviderType(value as ServiceProvider["type"])}>
              <SelectTrigger>
                <SelectValue placeholder="Provider type" />
              </SelectTrigger>
              <SelectContent>
                {providerTypes.map((type) => (
                  <SelectItem key={type} value={type}>
                    {type}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Input placeholder="Phone number" value={providerPhone} onChange={(event) => setProviderPhone(event.target.value)} />
            <Input placeholder="Address" value={providerAddress} onChange={(event) => setProviderAddress(event.target.value)} />
            <Input placeholder="Email (optional)" value={providerEmail} onChange={(event) => setProviderEmail(event.target.value)} />
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setProviderDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleCreateProvider} disabled={creatingProvider}>
              {creatingProvider ? "Saving..." : "Create Provider"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
