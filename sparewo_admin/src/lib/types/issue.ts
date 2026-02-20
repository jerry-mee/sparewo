export type IssueStatus =
  | "open"
  | "triaged"
  | "in_progress"
  | "waiting_customer"
  | "resolved"
  | "closed";

export type IssueSeverity = "low" | "medium" | "high" | "critical";

export type IssueLevel = "l1" | "l2" | "l3" | "executive";

export type IssueSubjectType =
  | "product"
  | "service"
  | "order"
  | "vendor"
  | "account"
  | "payment"
  | "app"
  | "other";

export interface IssueRecord {
  id: string;
  title: string;
  complaint: string;
  status: IssueStatus;
  severity: IssueSeverity;
  level: IssueLevel;
  isResolved: boolean;
  clientId: string;
  clientName: string;
  clientEmail: string;
  subjectType: IssueSubjectType;
  subjectId?: string;
  subjectLabel?: string;
  vendorId?: string;
  vendorName?: string;
  orderId?: string;
  bookingId?: string;
  productId?: string;
  reportedVia: "client_app" | "vendor_app" | "admin" | "phone" | "whatsapp" | "email" | "other";
  createdBy: string;
  assignedTo?: string;
  assignedToName?: string;
  resolutionNotes?: string;
  resolvedAt?: unknown;
  createdAt: unknown;
  updatedAt: unknown;
}

export interface IssueStats {
  total: number;
  open: number;
  inProgress: number;
  resolved: number;
  critical: number;
}

export interface IssueReferenceOption {
  id: string;
  label: string;
  search: string;
}

