"use client";

import { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import {
  getClientById,
  getClientCars,
  getClientOrders,
  getClientBookings,
  toggleClientSuspension,
  UserProfile,
  UserCar,
  ClientOrder,
  ClientBooking,
} from "@/lib/firebase/clients";
import { createNotification } from "@/lib/firebase/notifications";
import { resetPassword } from "@/lib/firebase/auth";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Separator } from "@/components/ui/separator";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { formatDate, formatCurrency, getInitials } from "@/lib/utils";
import {
  ArrowLeft,
  Car,
  Mail,
  Phone,
  Calendar,
  Ban,
  CheckCircle,
  ShoppingBag,
  Wrench,
  ChevronRight,
  KeyRound,
  BellRing,
} from "lucide-react";
import { toast } from "sonner";
import Link from "next/link";
import Image from "next/image";

export default function ClientDetailsPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();

  const [client, setClient] = useState<UserProfile | null>(null);
  const [cars, setCars] = useState<UserCar[]>([]);
  const [orders, setOrders] = useState<ClientOrder[]>([]);
  const [bookings, setBookings] = useState<ClientBooking[]>([]);
  const [loading, setLoading] = useState(true);

  const [updatingStatus, setUpdatingStatus] = useState(false);
  const [sendingReset, setSendingReset] = useState(false);
  const [messageDialogOpen, setMessageDialogOpen] = useState(false);
  const [messageText, setMessageText] = useState("");
  const [sendingMessage, setSendingMessage] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const clientData = await getClientById(id);
        setClient(clientData);

        if (clientData) {
          const [carsData, ordersData, bookingsData] = await Promise.all([
            getClientCars(id),
            getClientOrders(id),
            getClientBookings(id),
          ]);

          setCars(carsData);
          setOrders(ordersData);
          setBookings(bookingsData);
        }
      } catch (error) {
        console.error(error);
        toast.error("Failed to load client details");
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [id]);

  const handleSuspensionToggle = async () => {
    if (!client) return;
    setUpdatingStatus(true);
    try {
      const newState = !client.isSuspended;
      await toggleClientSuspension(client.id, newState);
      setClient({ ...client, isSuspended: newState });
      toast.success(newState ? "Client suspended" : "Client reactivated");
    } catch (error) {
      console.error(error);
      toast.error("Failed to update client status");
    } finally {
      setUpdatingStatus(false);
    }
  };

  const handlePasswordReset = async () => {
    if (!client?.email) {
      toast.error("Client has no email address on file");
      return;
    }

    setSendingReset(true);
    try {
      await resetPassword(client.email);
      toast.success("Password reset email dispatched");
    } catch (error) {
      console.error(error);
      toast.error("Could not send password reset email");
    } finally {
      setSendingReset(false);
    }
  };

  const handleSendMessage = async () => {
    if (!client) return;

    const text = messageText.trim();
    if (!text) {
      toast.error("Message cannot be empty");
      return;
    }

    setSendingMessage(true);
    try {
      await createNotification({
        userId: client.id,
        title: "Message from SpareWo Admin",
        message: text,
        type: "info",
        link: "/notifications",
        read: false,
      });

      toast.success("Client notification sent");
      setMessageText("");
      setMessageDialogOpen(false);
    } catch (error) {
      console.error(error);
      toast.error("Failed to send client notification");
    } finally {
      setSendingMessage(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const colors: Record<string, string> = {
      pending: "bg-yellow-100 text-yellow-800",
      completed: "bg-green-100 text-green-800",
      confirmed: "bg-blue-100 text-blue-800",
      cancelled: "bg-red-100 text-red-800",
      delivered: "bg-green-100 text-green-800",
      processing: "bg-indigo-100 text-indigo-800",
      shipped: "bg-purple-100 text-purple-800",
    };
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium ${colors[status] || "bg-gray-100"}`}>
        {status.toUpperCase()}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="flex h-96 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
      </div>
    );
  }

  if (!client) {
    return (
      <div className="flex flex-col items-center justify-center gap-4 py-20">
        <h2 className="text-xl font-semibold">Client not found</h2>
        <Button onClick={() => router.back()} variant="outline">
          <ArrowLeft className="mr-2 h-4 w-4" /> Go Back
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <Link href="/dashboard/clients">
            <Button variant="ghost" size="icon">
              <ArrowLeft className="h-5 w-5" />
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-bold tracking-tight">{client.name}</h1>
            <p className="text-sm text-muted-foreground">User ID: {client.id}</p>
          </div>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => setMessageDialogOpen(true)}>
            <BellRing className="mr-2 h-4 w-4" /> Notify
          </Button>
          <Button variant="outline" onClick={handlePasswordReset} disabled={sendingReset || !client.email}>
            <KeyRound className="mr-2 h-4 w-4" />
            {sendingReset ? "Sending..." : "Password Reset"}
          </Button>
          <Button
            variant={client.isSuspended ? "default" : "destructive"}
            onClick={handleSuspensionToggle}
            disabled={updatingStatus}
          >
            {client.isSuspended ? (
              <>
                <CheckCircle className="mr-2 h-4 w-4" /> Reactivate
              </>
            ) : (
              <>
                <Ban className="mr-2 h-4 w-4" /> Suspend
              </>
            )}
          </Button>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        <Card className="md:col-span-1 h-fit">
          <CardHeader>
            <CardTitle>Profile</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col items-center text-center">
            <Avatar className="mb-4 h-24 w-24">
              <AvatarImage src={client.photoUrl} />
              <AvatarFallback className="text-xl">{getInitials(client.name)}</AvatarFallback>
            </Avatar>
            <h3 className="text-xl font-semibold">{client.name}</h3>
            <div className="mt-1">
              {client.isSuspended ? (
                <span className="rounded-full bg-red-100 px-3 py-1 text-sm font-medium text-red-800">Suspended</span>
              ) : (
                <span className="rounded-full bg-green-100 px-3 py-1 text-sm font-medium text-green-800">Active</span>
              )}
            </div>

            <Separator className="my-6" />

            <div className="w-full space-y-4 text-left">
              <div className="flex items-center gap-3">
                <Mail className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm break-all">{client.email || "No email provided"}</span>
              </div>
              <div className="flex items-center gap-3">
                <Phone className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm">{client.phone || "No phone provided"}</span>
              </div>
              <div className="flex items-center gap-3">
                <Calendar className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm">Joined: {formatDate(client.createdAt)}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <div className="md:col-span-2">
          <Tabs defaultValue="garage">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="garage">Garage ({cars.length})</TabsTrigger>
              <TabsTrigger value="orders">Orders ({orders.length})</TabsTrigger>
              <TabsTrigger value="bookings">Bookings ({bookings.length})</TabsTrigger>
            </TabsList>

            <TabsContent value="garage" className="mt-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Car className="h-5 w-5" /> Registered Vehicles
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {cars.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-8 text-center text-muted-foreground">
                      <Car className="mb-2 h-10 w-10 opacity-20" />
                      <p>No vehicles registered yet.</p>
                    </div>
                  ) : (
                    <div className="grid gap-4 sm:grid-cols-2">
                      {cars.map((car) => (
                        <div
                          key={car.id}
                          className="flex flex-col overflow-hidden rounded-lg border bg-card text-card-foreground shadow-sm"
                        >
                          <div className="relative aspect-video w-full bg-muted">
                            {car.imageUrl ? (
                              <Image
                                src={car.imageUrl}
                                alt={`${car.make} ${car.model}`}
                                fill
                                sizes="(max-width: 768px) 100vw, 50vw"
                                className="object-cover"
                              />
                            ) : (
                              <div className="flex h-full items-center justify-center">
                                <Car className="h-12 w-12 text-muted-foreground/30" />
                              </div>
                            )}
                          </div>
                          <div className="flex flex-1 flex-col p-4">
                            <h4 className="font-semibold">
                              {car.year} {car.make} {car.model}
                            </h4>
                            {car.plateNumber && (
                              <span className="mt-1 inline-block rounded bg-secondary px-2 py-0.5 text-xs font-mono text-secondary-foreground">
                                {car.plateNumber}
                              </span>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="orders" className="mt-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <ShoppingBag className="h-5 w-5" /> Order History
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {orders.length === 0 ? (
                    <div className="py-8 text-center text-muted-foreground">No orders found.</div>
                  ) : (
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Order #</TableHead>
                          <TableHead>Date</TableHead>
                          <TableHead>Total</TableHead>
                          <TableHead>Status</TableHead>
                          <TableHead className="text-right">Action</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {orders.map((order) => (
                          <TableRow key={order.id}>
                            <TableCell className="font-mono">{order.orderNumber}</TableCell>
                            <TableCell>{formatDate(order.createdAt)}</TableCell>
                            <TableCell>{formatCurrency(order.totalAmount)}</TableCell>
                            <TableCell>{getStatusBadge(order.status)}</TableCell>
                            <TableCell className="text-right">
                              <Link href={`/dashboard/orders/${order.id}`}>
                                <Button variant="ghost" size="sm">
                                  View <ChevronRight className="ml-1 h-3 w-3" />
                                </Button>
                              </Link>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="bookings" className="mt-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Wrench className="h-5 w-5" /> Service Bookings
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {bookings.length === 0 ? (
                    <div className="py-8 text-center text-muted-foreground">No bookings found.</div>
                  ) : (
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Booking #</TableHead>
                          <TableHead>Vehicle</TableHead>
                          <TableHead>Service Date</TableHead>
                          <TableHead>Status</TableHead>
                          <TableHead className="text-right">Action</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {bookings.map((booking) => (
                          <TableRow key={booking.id}>
                            <TableCell className="font-mono">{booking.bookingNumber}</TableCell>
                            <TableCell>
                              {booking.vehicleBrand} {booking.vehicleModel}
                            </TableCell>
                            <TableCell>{formatDate(booking.pickupDate)}</TableCell>
                            <TableCell>{getStatusBadge(booking.status)}</TableCell>
                            <TableCell className="text-right">
                              <Link href={`/dashboard/autohub/${booking.id}`}>
                                <Button variant="ghost" size="sm">
                                  View <ChevronRight className="ml-1 h-3 w-3" />
                                </Button>
                              </Link>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
      </div>

      <Dialog open={messageDialogOpen} onOpenChange={setMessageDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Send Direct Notification</DialogTitle>
            <DialogDescription>
              This sends an in-app notification to {client.name}. Use this for urgent account guidance.
            </DialogDescription>
          </DialogHeader>
          <Textarea
            value={messageText}
            onChange={(event) => setMessageText(event.target.value)}
            placeholder="Write your message..."
            className="min-h-[120px]"
          />
          <DialogFooter>
            <Button variant="outline" onClick={() => setMessageDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSendMessage} disabled={sendingMessage || !messageText.trim()}>
              {sendingMessage ? "Sending..." : "Send Notification"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
