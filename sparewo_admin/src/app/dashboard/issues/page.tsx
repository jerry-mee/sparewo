"use client";

import { useEffect, useMemo, useState } from "react";
import { AlertTriangle, CheckCircle2, Clock3, Filter, Loader2, PlusCircle, ShieldAlert } from "lucide-react";
import { DocumentData } from "firebase/firestore";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Textarea } from "@/components/ui/textarea";
import { useAuth } from "@/lib/context/auth-context";
import {
  createIssue,
  getIssueReferences,
  getIssues,
  getIssueStats,
  updateIssueWorkflow,
} from "@/lib/firebase/issues";
import { formatDateTime } from "@/lib/utils";
import {
  IssueLevel,
  IssueRecord,
  IssueReferenceOption,
  IssueSeverity,
  IssueStatus,
  IssueSubjectType,
} from "@/lib/types/issue";

const STATUS_OPTIONS: Array<{ value: IssueStatus; label: string }> = [
  { value: "open", label: "Open" },
  { value: "triaged", label: "Triaged" },
  { value: "in_progress", label: "In Progress" },
  { value: "waiting_customer", label: "Waiting Customer" },
  { value: "resolved", label: "Resolved" },
  { value: "closed", label: "Closed" },
];

const LEVEL_OPTIONS: Array<{ value: IssueLevel; label: string }> = [
  { value: "l1", label: "L1" },
  { value: "l2", label: "L2" },
  { value: "l3", label: "L3" },
  { value: "executive", label: "Executive" },
];

const SEVERITY_OPTIONS: Array<{ value: IssueSeverity; label: string }> = [
  { value: "low", label: "Low" },
  { value: "medium", label: "Medium" },
  { value: "high", label: "High" },
  { value: "critical", label: "Critical" },
];

const SUBJECT_OPTIONS: Array<{ value: IssueSubjectType; label: string }> = [
  { value: "product", label: "Product" },
  { value: "service", label: "Service" },
  { value: "order", label: "Order" },
  { value: "vendor", label: "Vendor" },
  { value: "account", label: "Account" },
  { value: "payment", label: "Payment" },
  { value: "app", label: "App" },
  { value: "other", label: "Other" },
];

const REPORTED_VIA_OPTIONS = ["client_app", "vendor_app", "admin", "phone", "whatsapp", "email", "other"] as const;

export default function IssuesPage() {
  const { user } = useAuth();
  const [issues, setIssues] = useState<IssueRecord[]>([]);
  const [stats, setStats] = useState({ total: 0, open: 0, inProgress: 0, resolved: 0, critical: 0 });
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [updatingId, setUpdatingId] = useState<string | null>(null);
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(false);

  const [statusFilter, setStatusFilter] = useState<IssueStatus | "all">("all");
  const [levelFilter, setLevelFilter] = useState<IssueLevel | "all">("all");
  const [severityFilter, setSeverityFilter] = useState<IssueSeverity | "all">("all");
  const [resolvedFilter, setResolvedFilter] = useState<"all" | "yes" | "no">("all");
  const [search, setSearch] = useState("");

  const [references, setReferences] = useState<{
    clients: IssueReferenceOption[];
    vendors: IssueReferenceOption[];
    products: IssueReferenceOption[];
    orders: IssueReferenceOption[];
    bookings: IssueReferenceOption[];
  }>({
    clients: [],
    vendors: [],
    products: [],
    orders: [],
    bookings: [],
  });

  const [title, setTitle] = useState("");
  const [complaint, setComplaint] = useState("");
  const [clientId, setClientId] = useState("");
  const [subjectType, setSubjectType] = useState<IssueSubjectType>("product");
  const [subjectId, setSubjectId] = useState("");
  const [severity, setSeverity] = useState<IssueSeverity>("medium");
  const [level, setLevel] = useState<IssueLevel>("l1");
  const [reportedVia, setReportedVia] = useState<(typeof REPORTED_VIA_OPTIONS)[number]>("admin");
  const [assignedToName, setAssignedToName] = useState("");

  const [clientSearch, setClientSearch] = useState("");
  const [subjectSearch, setSubjectSearch] = useState("");

  const loadStats = async () => {
    try {
      setStats(await getIssueStats());
    } catch (error) {
      console.error(error);
      toast.error("Failed to load issue stats");
    }
  };

  const loadIssues = async (reset = false) => {
    setLoading(true);
    try {
      const result = await getIssues(
        {
          status: statusFilter,
          level: levelFilter,
          severity: severityFilter,
          resolved: resolvedFilter,
          search,
        },
        20,
        reset ? undefined : lastDoc
      );

      if (reset) {
        setIssues(result.issues);
      } else {
        setIssues((prev) => [...prev, ...result.issues]);
      }

      setLastDoc(result.lastDoc);
      setHasMore(result.issues.length === 20);
    } catch (error) {
      console.error(error);
      toast.error("Failed to load issues");
    } finally {
      setLoading(false);
    }
  };

  const loadReferences = async () => {
    try {
      setReferences(await getIssueReferences());
    } catch (error) {
      console.error(error);
      toast.error("Failed to load issue reference data");
    }
  };

  useEffect(() => {
    void Promise.all([loadReferences(), loadStats()]);
  }, []);

  useEffect(() => {
    void loadIssues(true);
  }, [statusFilter, levelFilter, severityFilter, resolvedFilter]);

  const filteredClients = useMemo(() => {
    const needle = clientSearch.trim().toLowerCase();
    if (!needle) return references.clients;
    return references.clients.filter((item) => item.search.includes(needle));
  }, [references.clients, clientSearch]);

  const subjectOptions = useMemo(() => {
    if (subjectType === "product") return references.products;
    if (subjectType === "service") return references.bookings;
    if (subjectType === "order") return references.orders;
    if (subjectType === "vendor") return references.vendors;
    return [];
  }, [references, subjectType]);

  const filteredSubjects = useMemo(() => {
    const needle = subjectSearch.trim().toLowerCase();
    if (!needle) return subjectOptions;
    return subjectOptions.filter((item) => item.search.includes(needle));
  }, [subjectOptions, subjectSearch]);

  const selectedClient = useMemo(
    () => references.clients.find((item) => item.id === clientId),
    [references.clients, clientId]
  );
  const selectedSubject = useMemo(
    () => subjectOptions.find((item) => item.id === subjectId),
    [subjectOptions, subjectId]
  );

  const handleCreateIssue = async () => {
    if (!user) {
      toast.error("Please sign in again and retry.");
      return;
    }
    if (!title.trim() || !complaint.trim()) {
      toast.error("Title and complaint details are required.");
      return;
    }
    if (!selectedClient) {
      toast.error("Attach a client for accountability.");
      return;
    }
    if ((subjectType === "product" || subjectType === "service" || subjectType === "order" || subjectType === "vendor") && !selectedSubject) {
      toast.error("Attach the relevant product/service/order/vendor record.");
      return;
    }

    setCreating(true);
    try {
      const payload = {
        title: title.trim(),
        complaint: complaint.trim(),
        clientId: selectedClient.id,
        clientName: selectedClient.label,
        clientEmail: selectedClient.label.match(/\(([^)]+)\)/)?.[1] ?? "",
        subjectType,
        subjectId: selectedSubject?.id,
        subjectLabel: selectedSubject?.label,
        vendorId: subjectType === "vendor" ? selectedSubject?.id : undefined,
        vendorName: subjectType === "vendor" ? selectedSubject?.label : undefined,
        orderId: subjectType === "order" ? selectedSubject?.id : undefined,
        bookingId: subjectType === "service" ? selectedSubject?.id : undefined,
        productId: subjectType === "product" ? selectedSubject?.id : undefined,
        severity,
        level,
        reportedVia,
        assignedToName: assignedToName.trim() || undefined,
      };

      await createIssue(payload, user.uid);
      toast.success("Issue logged successfully.");
      setTitle("");
      setComplaint("");
      setClientId("");
      setSubjectId("");
      setAssignedToName("");
      setClientSearch("");
      setSubjectSearch("");
      await Promise.all([loadIssues(true), loadStats()]);
    } catch (error) {
      console.error(error);
      toast.error("Failed to create issue.");
    } finally {
      setCreating(false);
    }
  };

  const handleWorkflowUpdate = async (
    issueId: string,
    next: { status?: IssueStatus; level?: IssueLevel; severity?: IssueSeverity }
  ) => {
    setUpdatingId(issueId);
    try {
      await updateIssueWorkflow(issueId, next);
      await Promise.all([loadIssues(true), loadStats()]);
      toast.success("Issue updated.");
    } catch (error) {
      console.error(error);
      toast.error("Failed to update issue.");
    } finally {
      setUpdatingId(null);
    }
  };

  const statusBadge = (status: IssueStatus) => {
    const classMap: Record<IssueStatus, string> = {
      open: "bg-red-100 text-red-800",
      triaged: "bg-blue-100 text-blue-800",
      in_progress: "bg-amber-100 text-amber-900",
      waiting_customer: "bg-purple-100 text-purple-800",
      resolved: "bg-emerald-100 text-emerald-800",
      closed: "bg-slate-100 text-slate-800",
    };
    return <Badge className={classMap[status]}>{status.replace("_", " ")}</Badge>;
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-semibold tracking-tight">Complaints & Issue Tracker</h1>
        <p className="text-muted-foreground">
          Record complaints, assign accountability, and track every issue through resolution.
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-5">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Total Issues</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center justify-between">
            <div className="text-2xl font-semibold">{stats.total}</div>
            <AlertTriangle className="h-4 w-4 text-muted-foreground" />
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Open</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center justify-between">
            <div className="text-2xl font-semibold">{stats.open}</div>
            <Clock3 className="h-4 w-4 text-amber-600" />
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">In Progress</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center justify-between">
            <div className="text-2xl font-semibold">{stats.inProgress}</div>
            <Loader2 className="h-4 w-4 text-blue-600" />
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Resolved</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center justify-between">
            <div className="text-2xl font-semibold">{stats.resolved}</div>
            <CheckCircle2 className="h-4 w-4 text-emerald-600" />
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Critical</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center justify-between">
            <div className="text-2xl font-semibold">{stats.critical}</div>
            <ShieldAlert className="h-4 w-4 text-red-600" />
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <PlusCircle className="h-5 w-5" /> Log New Complaint/Issue
          </CardTitle>
          <CardDescription>
            Every issue must be tied to a client and the related record (product/service/order/vendor).
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <label className="text-sm font-medium">Issue Title</label>
              <Input value={title} onChange={(event) => setTitle(event.target.value)} placeholder="Short issue summary" />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Assigned To (optional)</label>
              <Input
                value={assignedToName}
                onChange={(event) => setAssignedToName(event.target.value)}
                placeholder="Ops lead / manager name"
              />
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium">Complaint Details</label>
            <Textarea
              value={complaint}
              onChange={(event) => setComplaint(event.target.value)}
              placeholder="What exactly happened, expected vs actual behavior, impact, screenshots reference, timestamps..."
              rows={4}
            />
          </div>

          <div className="grid gap-4 md:grid-cols-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Severity</label>
              <Select value={severity} onValueChange={(value) => setSeverity(value as IssueSeverity)}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {SEVERITY_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Level</label>
              <Select value={level} onValueChange={(value) => setLevel(value as IssueLevel)}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {LEVEL_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Subject Type</label>
              <Select value={subjectType} onValueChange={(value) => { setSubjectType(value as IssueSubjectType); setSubjectId(""); }}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {SUBJECT_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Reported Via</label>
              <Select value={reportedVia} onValueChange={(value) => setReportedVia(value as (typeof REPORTED_VIA_OPTIONS)[number])}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {REPORTED_VIA_OPTIONS.map((option) => (
                    <SelectItem key={option} value={option}>{option.replace("_", " ")}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <label className="text-sm font-medium">Search Client</label>
              <Input value={clientSearch} onChange={(event) => setClientSearch(event.target.value)} placeholder="Name, email, UID" />
              <Select value={clientId} onValueChange={setClientId}>
                <SelectTrigger><SelectValue placeholder="Select client" /></SelectTrigger>
                <SelectContent>
                  {filteredClients.map((client) => (
                    <SelectItem key={client.id} value={client.id}>{client.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Search Related Record</label>
              <Input
                value={subjectSearch}
                onChange={(event) => setSubjectSearch(event.target.value)}
                placeholder={`${subjectType} id / label`}
                disabled={subjectOptions.length === 0}
              />
              <Select value={subjectId} onValueChange={setSubjectId} disabled={subjectOptions.length === 0}>
                <SelectTrigger><SelectValue placeholder={subjectOptions.length === 0 ? "No attachment required for this type" : "Attach related record"} /></SelectTrigger>
                <SelectContent>
                  {filteredSubjects.map((option) => (
                    <SelectItem key={option.id} value={option.id}>{option.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex justify-end">
            <Button onClick={handleCreateIssue} disabled={creating}>
              {creating ? "Saving..." : "Create Issue"}
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
            <CardTitle className="flex items-center gap-2">
              <Filter className="h-5 w-5" /> Active Tracker
            </CardTitle>
            <div className="grid grid-cols-2 gap-2 md:grid-cols-5">
              <Input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search issues" />
              <Select value={statusFilter} onValueChange={(value) => setStatusFilter(value as IssueStatus | "all")}>
                <SelectTrigger><SelectValue placeholder="Status" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All status</SelectItem>
                  {STATUS_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Select value={levelFilter} onValueChange={(value) => setLevelFilter(value as IssueLevel | "all")}>
                <SelectTrigger><SelectValue placeholder="Level" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All levels</SelectItem>
                  {LEVEL_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Select value={severityFilter} onValueChange={(value) => setSeverityFilter(value as IssueSeverity | "all")}>
                <SelectTrigger><SelectValue placeholder="Severity" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All severity</SelectItem>
                  {SEVERITY_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Select value={resolvedFilter} onValueChange={(value) => setResolvedFilter(value as "all" | "yes" | "no")}>
                <SelectTrigger><SelectValue placeholder="Resolution" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All</SelectItem>
                  <SelectItem value="no">Unresolved</SelectItem>
                  <SelectItem value="yes">Resolved</SelectItem>
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
                  <TableHead>Issue</TableHead>
                  <TableHead>Client</TableHead>
                  <TableHead>Attached Record</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Level</TableHead>
                  <TableHead>Severity</TableHead>
                  <TableHead>Resolved</TableHead>
                  <TableHead>Updated</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading && issues.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} className="h-24 text-center">Loading issues...</TableCell>
                  </TableRow>
                ) : issues.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} className="h-24 text-center">No issues found.</TableCell>
                  </TableRow>
                ) : (
                  issues.map((issue) => (
                    <TableRow key={issue.id}>
                      <TableCell className="max-w-[320px] whitespace-normal">
                        <div className="font-medium">{issue.title}</div>
                        <p className="mt-1 text-xs text-muted-foreground">{issue.complaint}</p>
                      </TableCell>
                      <TableCell className="max-w-[220px] whitespace-normal">
                        <div className="font-medium">{issue.clientName}</div>
                        <div className="text-xs text-muted-foreground">{issue.clientEmail}</div>
                      </TableCell>
                      <TableCell className="max-w-[280px] whitespace-normal">
                        <div className="text-sm font-medium">{issue.subjectType}</div>
                        <div className="text-xs text-muted-foreground">{issue.subjectLabel || issue.subjectId || "-"}</div>
                      </TableCell>
                      <TableCell>
                        <Select
                          value={issue.status}
                          onValueChange={(value) => handleWorkflowUpdate(issue.id, { status: value as IssueStatus })}
                          disabled={updatingId === issue.id}
                        >
                          <SelectTrigger className="w-[150px]">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            {STATUS_OPTIONS.map((option) => (
                              <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </TableCell>
                      <TableCell>
                        <Select
                          value={issue.level}
                          onValueChange={(value) => handleWorkflowUpdate(issue.id, { level: value as IssueLevel })}
                          disabled={updatingId === issue.id}
                        >
                          <SelectTrigger className="w-[100px]">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            {LEVEL_OPTIONS.map((option) => (
                              <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </TableCell>
                      <TableCell>
                        <Select
                          value={issue.severity}
                          onValueChange={(value) => handleWorkflowUpdate(issue.id, { severity: value as IssueSeverity })}
                          disabled={updatingId === issue.id}
                        >
                          <SelectTrigger className="w-[120px]">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            {SEVERITY_OPTIONS.map((option) => (
                              <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </TableCell>
                      <TableCell>{issue.isResolved ? <Badge className="bg-emerald-100 text-emerald-800">Resolved</Badge> : statusBadge(issue.status)}</TableCell>
                      <TableCell className="text-xs text-muted-foreground">{formatDateTime(issue.updatedAt)}</TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
          {hasMore && (
            <div className="mt-4 flex justify-center">
              <Button variant="outline" onClick={() => loadIssues(false)} disabled={loading}>
                {loading ? "Loading..." : "Load More"}
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
