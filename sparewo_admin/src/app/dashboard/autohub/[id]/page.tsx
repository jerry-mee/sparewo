// src/app/dashboard/autohub/[id]/page.tsx
"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import { 
  getBookingById, 
  getAllServiceProviders, 
  updateBookingStatus, 
  assignProviderToBooking,
  ServiceBooking,
  ServiceProvider 
} from "@/lib/firebase/autohub";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { 
  Select, 
  SelectContent, 
  SelectItem, 
  SelectTrigger, 
  SelectValue 
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { formatDate } from "@/lib/utils";
import { ArrowLeft, User, Car, Calendar, MapPin, CheckCircle2 } from "lucide-react";
import { toast } from "sonner";
import Link from "next/link";

export default function BookingDetailsPage() {
  const { id } = useParams<{ id: string }>();
  
  const [booking, setBooking] = useState<ServiceBooking | null>(null);
  const [providers, setProviders] = useState<ServiceProvider[]>([]);
  const [loading, setLoading] = useState(true);
  const [notes, setNotes] = useState("");
  const [selectedProvider, setSelectedProvider] = useState<string>("");

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const [bookingData, providersData] = await Promise.all([
          getBookingById(id),
          getAllServiceProviders()
        ]);
        
        setBooking(bookingData);
        setProviders(providersData);
        
        if (bookingData?.adminNotes) setNotes(bookingData.adminNotes);
        if (bookingData?.assignedProviderId) setSelectedProvider(bookingData.assignedProviderId);
      } catch (error) {
        console.error(error);
        toast.error("Failed to load booking details");
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [id]);

  const handleStatusUpdate = async (newStatus: ServiceBooking['status']) => {
    if (!booking) return;
    try {
      await updateBookingStatus(booking.id, newStatus, notes);
      setBooking({ ...booking, status: newStatus, adminNotes: notes });
      toast.success(`Status updated to ${newStatus}`);
    } catch (error) {
      console.error(error);
      toast.error("Failed to update status");
    }
  };

  const handleAssignProvider = async () => {
    if (!booking || !selectedProvider) return;
    try {
      const provider = providers.find(p => p.id === selectedProvider);
      if (provider) {
        await assignProviderToBooking(booking.id, provider.id, provider.name);
        setBooking({ 
          ...booking, 
          assignedProviderId: provider.id, 
          assignedProviderName: provider.name,
          status: 'confirmed' 
        });
        toast.success(`Assigned to ${provider.name}`);
      }
    } catch (error) {
      console.error(error);
      toast.error("Failed to assign provider");
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

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2">
        <Link href="/dashboard/autohub">
          <Button variant="ghost" size="icon"><ArrowLeft className="h-5 w-5" /></Button>
        </Link>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Booking #{booking.bookingNumber}</h1>
          <p className="text-sm text-muted-foreground">Created on {formatDate(booking.createdAt)}</p>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Main Details */}
        <div className="space-y-6 lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Car className="h-5 w-5 text-primary" /> Vehicle & Service
              </CardTitle>
            </CardHeader>
            <CardContent className="grid gap-6 sm:grid-cols-2">
              <div>
                <h4 className="text-sm font-medium text-muted-foreground">Vehicle Details</h4>
                <p className="mt-1 text-lg font-medium">{booking.vehicleYear} {booking.vehicleBrand} {booking.vehicleModel}</p>
              </div>
              <div>
                <h4 className="text-sm font-medium text-muted-foreground">Requested Services</h4>
                <div className="mt-1 flex flex-wrap gap-2">
                  {booking.services.map((s, i) => (
                    <span key={i} className="rounded-full bg-secondary px-2.5 py-0.5 text-xs font-medium text-secondary-foreground">
                      {s}
                    </span>
                  ))}
                </div>
              </div>
              <div className="sm:col-span-2">
                <h4 className="text-sm font-medium text-muted-foreground">Description / Issue</h4>
                <p className="mt-1 rounded-md bg-muted p-3 text-sm">{booking.serviceDescription || "No description provided."}</p>
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
                <h4 className="text-sm font-medium text-muted-foreground mb-1 flex items-center gap-1">
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

        {/* Sidebar Actions */}
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Workflow Actions</CardTitle>
              <CardDescription>Manage booking status</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Assignment</label>
                <div className="flex gap-2">
                  <Select value={selectedProvider} onValueChange={setSelectedProvider}>
                    <SelectTrigger className="w-full">
                      <SelectValue placeholder="Select Mechanic" />
                    </SelectTrigger>
                    <SelectContent>
                      {providers.map(p => (
                        <SelectItem key={p.id} value={p.id}>{p.name} ({p.type})</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Button size="icon" variant="outline" onClick={handleAssignProvider}>
                    <CheckCircle2 className="h-4 w-4" />
                  </Button>
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium">Status</label>
                <div className="grid grid-cols-2 gap-2">
                  <Button 
                    variant={booking.status === 'confirmed' ? "default" : "outline"}
                    size="sm" 
                    onClick={() => handleStatusUpdate('confirmed')}
                    className="w-full"
                  >
                    Confirm
                  </Button>
                  <Button 
                    variant={booking.status === 'in_progress' ? "default" : "outline"}
                    size="sm" 
                    onClick={() => handleStatusUpdate('in_progress')}
                    className="w-full"
                  >
                    In Progress
                  </Button>
                  <Button 
                    variant={booking.status === 'completed' ? "default" : "outline"}
                    size="sm" 
                    onClick={() => handleStatusUpdate('completed')}
                    className="w-full bg-green-600 hover:bg-green-700 text-white"
                  >
                    Complete
                  </Button>
                  <Button 
                    variant={booking.status === 'cancelled' ? "default" : "outline"}
                    size="sm" 
                    onClick={() => handleStatusUpdate('cancelled')}
                    className="w-full text-red-600 hover:bg-red-50 hover:text-red-700"
                  >
                    Cancel
                  </Button>
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium">Admin Notes</label>
                <Textarea 
                  placeholder="Internal notes..." 
                  value={notes} 
                  onChange={(e) => setNotes(e.target.value)} 
                />
                <Button variant="ghost" size="sm" className="w-full" onClick={() => handleStatusUpdate(booking.status)}>
                  Save Notes
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}