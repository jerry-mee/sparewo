// src/app/dashboard/clients/page.tsx
"use client";

import { useState, useEffect, useMemo } from "react";
import { useRouter } from "next/navigation";
import { getClients, UserProfile } from "@/lib/firebase/clients";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { StatusPill } from "@/components/ui/status-pill";
import { DocumentData } from "firebase/firestore";
import { formatDate, getInitials } from "@/lib/utils";
import Link from "next/link";
import { Search, ChevronRight, Users, Mail, UserCheck, UserX } from "lucide-react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

type ClientFilter = "all" | "active" | "suspended";

export default function ClientsPage() {
  const router = useRouter();
  const [clients, setClients] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<ClientFilter>("all");
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  const fetchClients = async (reset = false) => {
    setLoading(true);
    try {
      const result = await getClients(searchQuery, 10, reset ? undefined : lastDoc);
      if (reset) {
        setClients(result.clients);
      } else {
        setClients((prev) => [...prev, ...result.clients]);
      }
      setLastDoc(result.lastDoc);
      setHasMore(result.clients.length === 10);
    } catch (error) {
      console.error("Error fetching clients:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchClients(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleSearch = (event: React.FormEvent) => {
    event.preventDefault();
    fetchClients(true);
  };

  const activeCount = useMemo(() => clients.filter((client) => !client.isSuspended).length, [clients]);
  const suspendedCount = useMemo(() => clients.filter((client) => client.isSuspended).length, [clients]);

  const filteredClients = useMemo(() => {
    if (statusFilter === "active") {
      return clients.filter((client) => !client.isSuspended);
    }

    if (statusFilter === "suspended") {
      return clients.filter((client) => client.isSuspended);
    }

    return clients;
  }, [clients, statusFilter]);

  const summaryCards = [
    {
      key: "all",
      label: "Total Clients",
      value: `${clients.length}${hasMore ? "+" : ""}`,
      icon: <Users className="h-4 w-4 text-muted-foreground" />,
      active: statusFilter === "all",
      onClick: () => setStatusFilter("all"),
    },
    {
      key: "active",
      label: "Active Clients",
      value: activeCount,
      icon: <UserCheck className="h-4 w-4 text-emerald-600" />,
      active: statusFilter === "active",
      onClick: () => setStatusFilter("active"),
    },
    {
      key: "suspended",
      label: "Suspended Clients",
      value: suspendedCount,
      icon: <UserX className="h-4 w-4 text-red-600" />,
      active: statusFilter === "suspended",
      onClick: () => setStatusFilter("suspended"),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-semibold tracking-tight">Client Management</h1>
        <p className="text-muted-foreground">View and manage registered users and their vehicles.</p>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        {summaryCards.map((card) => (
          <button key={card.key} type="button" onClick={card.onClick} className="text-left">
            <Card className={`transition-colors hover:border-primary/50 ${card.active ? "border-primary/60 bg-primary/5" : ""}`}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">{card.label}</CardTitle>
                {card.icon}
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{card.value}</div>
              </CardContent>
            </Card>
          </button>
        ))}
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Registered Users</CardTitle>
            <form onSubmit={handleSearch} className="flex w-full max-w-sm items-center space-x-2">
              <Input
                placeholder="Search by name or email..."
                value={searchQuery}
                onChange={(event) => setSearchQuery(event.target.value)}
                className="h-9"
              />
              <Button type="submit" size="sm" variant="secondary">
                <Search className="h-4 w-4" />
              </Button>
            </form>
          </div>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Contact</TableHead>
                  <TableHead>Joined</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading && clients.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="h-24 text-center">
                      Loading clients...
                    </TableCell>
                  </TableRow>
                ) : filteredClients.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="h-24 text-center">
                      No clients found.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredClients.map((client) => (
                    <TableRow
                      key={client.id}
                      className="cursor-pointer hover:bg-muted/40"
                      onClick={() => router.push(`/dashboard/clients/${client.id}`)}
                    >
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <Avatar className="h-9 w-9">
                            <AvatarImage src={client.photoUrl} alt={client.name} />
                            <AvatarFallback>{getInitials(client.name)}</AvatarFallback>
                          </Avatar>
                          <div className="flex flex-col">
                            <span className="font-medium">{client.name}</span>
                            <span className="text-xs text-muted-foreground md:hidden">{client.email}</span>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell className="hidden md:table-cell">
                        <div className="flex flex-col text-sm">
                          <span className="flex items-center gap-1">
                            <Mail className="h-3 w-3 text-muted-foreground" />
                            {client.email}
                          </span>
                          {client.phone && <span className="text-muted-foreground">{client.phone}</span>}
                        </div>
                      </TableCell>
                      <TableCell>{formatDate(client.createdAt)}</TableCell>
                      <TableCell>
                        <StatusPill
                          status={client.isSuspended ? "suspended" : "approved"}
                          label={client.isSuspended ? "Suspended" : "Active"}
                          className="text-xs"
                        />
                      </TableCell>
                      <TableCell className="text-right" onClick={(event) => event.stopPropagation()}>
                        <Link href={`/dashboard/clients/${client.id}`}>
                          <Button variant="ghost" size="icon" aria-label={`Open client ${client.name}`}>
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
              <Button variant="outline" onClick={() => fetchClients(false)} disabled={loading}>
                {loading ? "Loading..." : "Load More"}
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
