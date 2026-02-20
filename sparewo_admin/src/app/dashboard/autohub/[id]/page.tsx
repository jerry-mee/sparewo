// src/app/dashboard/autohub/[id]/page.tsx
"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import {
  getBookingById,
  getAllServiceProviders,
  ServiceBooking,
  ServiceProvider,
} from "@/lib/firebase/autohub";
import { auth } from "@/lib/firebase/config";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { StatusPill } from "@/components/ui/status-pill";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { formatDate } from "@/lib/utils";
import {
  ArrowLeft,
  User,
  Car,
  Calendar,
  MapPin,
  CheckCircle2,
  ChevronRight,
  ClipboardList,
  RefreshCw,
} from "lucide-react";
import { toast } from "sonner";
import Link from "next/link";

const trackerStages: ServiceBooking["status"][] = [
  "pending",
  "confirmed",
  "in_progress",
  "completed",
];

const trackerLabels: Record<ServiceBooking["status"], string> = {
  pending: "Request Received",
  confirmed: "Approved & Assigned",
  in_progress: "Service In Progress",
  completed: "Completed",
  cancelled: "Cancelled",
};

const trackerDescriptions: Record<Exclude<ServiceBooking["status"], "cancelled">, string> = {
  pending: "Request submitted and awaiting admin review",
  confirmed: "Approved and assigned to a provider",
  in_progress: "Vehicle is currently being serviced",
  completed: "Service completed and closed",
};

export default function BookingDetailsPage() {
  const { id } = useParams<{ id: string }>();

  const [booking, setBooking] = useState<ServiceBooking | null>(null);
  const [providers, setProviders] = useState<ServiceProvider[]>([]);
  const [loading, setLoading] = useState(true);
  const [notes, setNotes] = useState("");
  const [selectedProvider, setSelectedProvider] = useState<string>("");
  const [draftStatus, setDraftStatus] = useState<ServiceBooking["status"]>("pending");
  const [savingStatus, setSavingStatus] = useState(false);
  const [savingAssignment, setSavingAssignment] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const [bookingData, providersData] = await Promise.all([
          getBookingById(id),
          getAllServiceProviders(),
        ]);

        setBooking(bookingData);
        setProviders(providersData);

        if (bookingData?.adminNotes) setNotes(bookingData.adminNotes);
        if (bookingData?.assignedProviderId) setSelectedProvider(bookingData.assignedProviderId);
        if (bookingData?.status) setDraftStatus(bookingData.status);
      } catch (error) {
        console.error(error);
        toast.error("Failed to load booking details");
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [id]);

  const handleStatusUpdate = async (newStatus: ServiceBooking["status"]) => {
    if (!booking) return;
    setSavingStatus(true);
    try {
      const token = await auth.currentUser?.getIdToken();
      if (!token) {
        toast.error("You are not authenticated.");
        return;
      }

      const response = await fetch("/api/admin/autohub/status", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          bookingId: booking.id,
          status: newStatus,
          notes,
        }),
      });
      const payload = await response.json();
      if (!response.ok || payload?.success !== true) {
        throw new Error(payload?.error || "Failed to update booking status");
      }

      setBooking({ ...booking, status: newStatus, adminNotes: notes });
      setDraftStatus(newStatus);
      toast.success(`Status updated to ${newStatus}`);
    } catch (error) {
      console.error(error);
      toast.error("Failed to update status");
    } finally {
      setSavingStatus(false);
    }
  };

  const handleAssignProvider = async () => {
    if (!booking || !selectedProvider) return;
    setSavingAssignment(true);
    try {
      const provider = providers.find((p) => p.id === selectedProvider);
      if (provider) {
        const token = await auth.currentUser?.getIdToken();
        if (!token) {
          toast.error("You are not authenticated.");
          return;
        }

        const response = await fetch("/api/admin/autohub/status", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            bookingId: booking.id,
            status: "confirmed",
            notes,
            providerId: provider.id,
            providerName: provider.name,
          }),
        });
        const payload = await response.json();
        if (!response.ok || payload?.success !== true) {
          throw new Error(payload?.error || "Failed to assign provider");
        }

        setBooking({
          ...booking,
          assignedProviderId: provider.id,
          assignedProviderName: provider.name,
          status: "confirmed",
        });
        toast.success(`Assigned to ${provider.name}`);
      }
    } catch (error) {
      console.error(error);
      toast.error("Failed to assign provider");
    } finally {
      setSavingAssignment(false);
    }
  };

  if (loading) {
    return (
      <div className="flex h-96 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
      </div>
    );
  }

  if (!booking) return <div>Booking not found</div>;

  const stageIndex = trackerStages.indexOf(booking.status);
  const cancelled = booking.status === "cancelled";

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground">
        <Link href="/dashboard/autohub">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <span>AutoHub</span>
        <ChevronRight className="h-4 w-4" />
        <span>Request Tracker</span>
        <ChevronRight className="h-4 w-4" />
        <span className="font-medium text-foreground">{booking.bookingNumber}</span>
      </div>

      <Card>
        <CardContent className="space-y-4 pt-6">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h1 className="text-2xl font-semibold tracking-tight">Booking #{booking.bookingNumber}</h1>
              <p className="text-sm text-muted-foreground">Created on {formatDate(booking.createdAt)}</p>
            </div>
            <StatusPill status={booking.status} />
          </div>

          <div className="grid gap-4 md:grid-cols-4">
            {trackerStages.map((stage, index) => {
              const complete = !cancelled && stageIndex > index;
              const active = !cancelled && stageIndex === index;
              return (
                <div key={stage} className="relative rounded-lg border bg-background px-3 py-3">
                  <div className="flex items-center gap-2">
                    <span
                      className={`inline-flex h-7 w-7 items-center justify-center rounded-full border text-xs font-semibold ${
                        complete || active
                          ? "border-primary bg-primary text-primary-foreground"
                          : "border-muted-foreground/40 text-muted-foreground"
                      }`}
                    >
                      {complete ? <CheckCircle2 className="h-4 w-4" /> : index + 1}
                    </span>
                    <div>
                      <p className="text-xs uppercase tracking-wide text-muted-foreground">Step {index + 1}</p>
                      <p className="text-sm font-medium">{trackerLabels[stage]}</p>
                    </div>
                  </div>
                  <p className="mt-2 text-xs text-muted-foreground">{trackerDescriptions[stage]}</p>
                  {index < trackerStages.length - 1 && (
                    <div className="pointer-events-none absolute -right-2 top-6 hidden md:block">
                      <ChevronRight className="h-4 w-4 text-muted-foreground/60" />
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {cancelled && (
            <div className="rounded-md border border-rose-300 bg-rose-50 px-3 py-2 text-sm text-rose-800 dark:border-rose-500/50 dark:bg-rose-900/20 dark:text-rose-200">
              This request has been cancelled.
            </div>
          )}
        </CardContent>
      </Card>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Car className="h-5 w-5 text-primary" /> Vehicle & Service Snapshot
              </CardTitle>
            </CardHeader>
            <CardContent className="grid gap-6 sm:grid-cols-2">
              <div>
                <h4 className="text-sm font-medium text-muted-foreground">Vehicle Details</h4>
                <p className="mt-1 text-lg font-medium">
                  {booking.vehicleYear} {booking.vehicleBrand} {booking.vehicleModel}
                </p>
              </div>
              <div>
                <h4 className="text-sm font-medium text-muted-foreground">Requested Services</h4>
                <div className="mt-1 flex flex-wrap gap-2">
                  {booking.services.map((service, index) => (
                    <span
                      key={index}
                      className="rounded-full bg-secondary px-2.5 py-0.5 text-xs font-medium text-secondary-foreground"
                    >
                      {service}
                    </span>
                  ))}
                </div>
              </div>
              <div className="sm:col-span-2">
                <h4 className="text-sm font-medium text-muted-foreground">Description / Issue</h4>
                <p className="mt-1 rounded-md bg-muted p-3 text-sm">
                  {booking.serviceDescription || "No description provided."}
                </p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <ClipboardList className="h-5 w-5 text-primary" /> Follow-up Timeline
              </CardTitle>
            </CardHeader>
            <CardContent className="grid gap-3 sm:grid-cols-2">
              <div className="rounded-md border bg-background p-3">
                <p className="text-sm font-medium">Pickup Window</p>
                <p className="text-sm text-muted-foreground">
                  {formatDate(booking.pickupDate)} at {booking.pickupTime}
                </p>
                <p className="text-sm text-muted-foreground">{booking.pickupLocation}</p>
              </div>
              <div className="rounded-md border bg-background p-3">
                <p className="text-sm font-medium">Assigned Provider</p>
                <p className="text-sm text-muted-foreground">
                  {booking.assignedProviderName || "Pending assignment"}
                </p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <User className="h-5 w-5 text-primary" /> Customer Info
              </CardTitle>
            </CardHeader>
            <CardContent className="grid gap-4 sm:grid-cols-2">
              <div>
                <h4 className="text-sm font-medium text-muted-foreground">Name</h4>
                <p>{booking.userName}</p>
              </div>
              <div>
                <h4 className="text-sm font-medium text-muted-foreground">Contact</h4>
                <p>{booking.userEmail}</p>
                <p className="text-sm text-muted-foreground">{booking.userPhone}</p>
              </div>
              <div className="sm:col-span-2">
                <h4 className="mb-1 flex items-center gap-1 text-sm font-medium text-muted-foreground">
                  <MapPin className="h-3 w-3" /> Pickup Location
                </h4>
                <p>{booking.pickupLocation}</p>
                <div className="mt-2 flex items-center gap-2 text-sm text-muted-foreground">
                  <Calendar className="h-4 w-4" />
                  Requested: {formatDate(booking.pickupDate)} at {booking.pickupTime}
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Workflow Actions</CardTitle>
              <CardDescription>Manage booking status and assignment updates</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Assignment</label>
                <div className="flex gap-2">
                  <Select value={selectedProvider} onValueChange={setSelectedProvider}>
                    <SelectTrigger className="w-full">
                      <SelectValue placeholder="Select Service Provider" />
                    </SelectTrigger>
                    <SelectContent>
                      {providers.map((provider) => (
                        <SelectItem key={provider.id} value={provider.id}>
                          {provider.name} ({provider.type})
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Button
                    variant="outline"
                    onClick={handleAssignProvider}
                    disabled={savingAssignment || !selectedProvider}
                  >
                    {savingAssignment ? "Saving..." : "Update Assignment"}
                  </Button>
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium">Status</label>
                <div className="flex gap-2">
                  <Select
                    value={draftStatus}
                    onValueChange={(value) => setDraftStatus(value as ServiceBooking["status"])}
                  >
                    <SelectTrigger className="w-full">
                      <SelectValue placeholder="Select status" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="pending">Pending</SelectItem>
                      <SelectItem value="confirmed">Confirmed</SelectItem>
                      <SelectItem value="in_progress">In Progress</SelectItem>
                      <SelectItem value="completed">Completed</SelectItem>
                      <SelectItem value="cancelled">Cancelled</SelectItem>
                    </SelectContent>
                  </Select>
                  <Button
                    onClick={() => handleStatusUpdate(draftStatus)}
                    disabled={savingStatus || draftStatus === booking.status}
                  >
                    {savingStatus ? "Updating..." : "Update Status"}
                  </Button>
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium">Admin Notes</label>
                <Textarea
                  placeholder="Internal notes..."
                  value={notes}
                  onChange={(event) => setNotes(event.target.value)}
                />
                <Button
                  variant="ghost"
                  size="sm"
                  className="w-full"
                  onClick={() => handleStatusUpdate(booking.status)}
                  disabled={savingStatus}
                >
                  {savingStatus ? (
                    <>
                      <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
                      Saving...
                    </>
                  ) : (
                    "Save Notes"
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
