import {
  addDoc,
  collection,
  doc,
  DocumentData,
  getDocs,
  limit,
  orderBy,
  query,
  QueryConstraint,
  serverTimestamp,
  startAfter,
  updateDoc,
  where,
} from "firebase/firestore";

import { db } from "@/lib/firebase/config";
import {
  IssueLevel,
  IssueRecord,
  IssueReferenceOption,
  IssueSeverity,
  IssueStats,
  IssueStatus,
  IssueSubjectType,
} from "@/lib/types/issue";

export interface IssueFilters {
  status?: IssueStatus | "all";
  level?: IssueLevel | "all";
  severity?: IssueSeverity | "all";
  resolved?: "all" | "yes" | "no";
  search?: string;
}

export interface CreateIssueInput {
  title: string;
  complaint: string;
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
  severity: IssueSeverity;
  level: IssueLevel;
  reportedVia: "client_app" | "vendor_app" | "admin" | "phone" | "whatsapp" | "email" | "other";
  assignedTo?: string;
  assignedToName?: string;
}

export interface UpdateIssueWorkflowInput {
  status?: IssueStatus;
  severity?: IssueSeverity;
  level?: IssueLevel;
  assignedTo?: string;
  assignedToName?: string;
  resolutionNotes?: string;
}

const normalize = (value: unknown): string => (typeof value === "string" ? value : "");

const buildIssueRecord = (id: string, data: Record<string, unknown>): IssueRecord => {
  const status = (normalize(data.status) as IssueStatus) || "open";
  return {
    id,
    title: normalize(data.title),
    complaint: normalize(data.complaint),
    status,
    severity: (normalize(data.severity) as IssueSeverity) || "medium",
    level: (normalize(data.level) as IssueLevel) || "l1",
    isResolved: Boolean(data.isResolved || status === "resolved" || status === "closed"),
    clientId: normalize(data.clientId),
    clientName: normalize(data.clientName),
    clientEmail: normalize(data.clientEmail),
    subjectType: (normalize(data.subjectType) as IssueSubjectType) || "other",
    subjectId: normalize(data.subjectId) || undefined,
    subjectLabel: normalize(data.subjectLabel) || undefined,
    vendorId: normalize(data.vendorId) || undefined,
    vendorName: normalize(data.vendorName) || undefined,
    orderId: normalize(data.orderId) || undefined,
    bookingId: normalize(data.bookingId) || undefined,
    productId: normalize(data.productId) || undefined,
    reportedVia: (normalize(data.reportedVia) as IssueRecord["reportedVia"]) || "admin",
    createdBy: normalize(data.createdBy),
    assignedTo: normalize(data.assignedTo) || undefined,
    assignedToName: normalize(data.assignedToName) || undefined,
    resolutionNotes: normalize(data.resolutionNotes) || undefined,
    resolvedAt: data.resolvedAt,
    createdAt: data.createdAt,
    updatedAt: data.updatedAt,
  };
};

export const getIssues = async (
  filters: IssueFilters = {},
  pageSize = 20,
  lastDoc?: DocumentData
): Promise<{ issues: IssueRecord[]; lastDoc: DocumentData | undefined }> => {
  const constraints: QueryConstraint[] = [orderBy("createdAt", "desc"), limit(pageSize)];

  if (filters.status && filters.status !== "all") {
    constraints.push(where("status", "==", filters.status));
  }
  if (filters.level && filters.level !== "all") {
    constraints.push(where("level", "==", filters.level));
  }
  if (filters.severity && filters.severity !== "all") {
    constraints.push(where("severity", "==", filters.severity));
  }
  if (filters.resolved && filters.resolved !== "all") {
    constraints.push(where("isResolved", "==", filters.resolved === "yes"));
  }

  let q = query(collection(db, "issues"), ...constraints);
  if (lastDoc) {
    q = query(q, startAfter(lastDoc));
  }

  const snapshot = await getDocs(q);
  const search = normalize(filters.search).trim().toLowerCase();
  const issues = snapshot.docs
    .map((docSnap) => buildIssueRecord(docSnap.id, docSnap.data() as Record<string, unknown>))
    .filter((item) => {
      if (!search) return true;
      return (
        item.title.toLowerCase().includes(search) ||
        item.complaint.toLowerCase().includes(search) ||
        item.clientName.toLowerCase().includes(search) ||
        item.clientEmail.toLowerCase().includes(search) ||
        item.subjectLabel?.toLowerCase().includes(search) ||
        item.id.toLowerCase().includes(search)
      );
    });

  return {
    issues,
    lastDoc: snapshot.docs.length > 0 ? snapshot.docs[snapshot.docs.length - 1] : undefined,
  };
};

export const createIssue = async (payload: CreateIssueInput, adminUid: string): Promise<string> => {
  const issueData = {
    title: payload.title.trim(),
    complaint: payload.complaint.trim(),
    status: "open",
    severity: payload.severity,
    level: payload.level,
    isResolved: false,
    clientId: payload.clientId,
    clientName: payload.clientName,
    clientEmail: payload.clientEmail,
    subjectType: payload.subjectType,
    subjectId: payload.subjectId || null,
    subjectLabel: payload.subjectLabel || null,
    vendorId: payload.vendorId || null,
    vendorName: payload.vendorName || null,
    orderId: payload.orderId || null,
    bookingId: payload.bookingId || null,
    productId: payload.productId || null,
    reportedVia: payload.reportedVia,
    createdBy: adminUid,
    assignedTo: payload.assignedTo || null,
    assignedToName: payload.assignedToName || null,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };

  const docRef = await addDoc(collection(db, "issues"), issueData);
  return docRef.id;
};

export const updateIssueWorkflow = async (
  issueId: string,
  updates: UpdateIssueWorkflowInput
): Promise<void> => {
  const updatePayload: Record<string, unknown> = {
    ...updates,
    updatedAt: serverTimestamp(),
  };

  if (updates.status) {
    const isResolvedStatus = updates.status === "resolved" || updates.status === "closed";
    updatePayload.isResolved = isResolvedStatus;
    updatePayload.resolvedAt = isResolvedStatus ? serverTimestamp() : null;
  }

  await updateDoc(doc(db, "issues", issueId), updatePayload);
};

export const getIssueStats = async (): Promise<IssueStats> => {
  const [allSnap, openSnap, inProgressSnap, resolvedSnap, criticalSnap] = await Promise.all([
    getDocs(collection(db, "issues")),
    getDocs(query(collection(db, "issues"), where("status", "==", "open"))),
    getDocs(query(collection(db, "issues"), where("status", "==", "in_progress"))),
    getDocs(query(collection(db, "issues"), where("isResolved", "==", true))),
    getDocs(query(collection(db, "issues"), where("severity", "==", "critical"))),
  ]);

  return {
    total: allSnap.size,
    open: openSnap.size,
    inProgress: inProgressSnap.size,
    resolved: resolvedSnap.size,
    critical: criticalSnap.size,
  };
};

export interface IssueReferencePayload {
  clients: IssueReferenceOption[];
  vendors: IssueReferenceOption[];
  products: IssueReferenceOption[];
  orders: IssueReferenceOption[];
  bookings: IssueReferenceOption[];
}

const makeOption = (id: string, label: string, search: string): IssueReferenceOption => ({
  id,
  label,
  search: search.toLowerCase(),
});

export const getIssueReferences = async (): Promise<IssueReferencePayload> => {
  const [usersSnap, vendorsSnap, productsSnap, ordersSnap, bookingsSnap] = await Promise.all([
    getDocs(query(collection(db, "users"), limit(200))),
    getDocs(query(collection(db, "vendors"), limit(200))),
    getDocs(query(collection(db, "catalog_products"), limit(200))),
    getDocs(query(collection(db, "orders"), orderBy("createdAt", "desc"), limit(200))),
    getDocs(query(collection(db, "service_bookings"), orderBy("createdAt", "desc"), limit(200))),
  ]);

  return {
    clients: usersSnap.docs.map((docSnap) => {
      const data = docSnap.data() as Record<string, unknown>;
      const name = normalize(data.name) || "Unknown Client";
      const email = normalize(data.email);
      return makeOption(docSnap.id, `${name} (${email || docSnap.id})`, `${name} ${email} ${docSnap.id}`);
    }),
    vendors: vendorsSnap.docs.map((docSnap) => {
      const data = docSnap.data() as Record<string, unknown>;
      const businessName = normalize(data.businessName) || normalize(data.name) || "Vendor";
      const email = normalize(data.email);
      return makeOption(docSnap.id, `${businessName} (${email || docSnap.id})`, `${businessName} ${email} ${docSnap.id}`);
    }),
    products: productsSnap.docs.map((docSnap) => {
      const data = docSnap.data() as Record<string, unknown>;
      const partName = normalize(data.partName) || normalize(data.name) || "Product";
      const brand = normalize(data.brand);
      const partNumber = normalize(data.partNumber);
      return makeOption(
        docSnap.id,
        `${partName}${brand ? ` • ${brand}` : ""}${partNumber ? ` • ${partNumber}` : ""}`,
        `${partName} ${brand} ${partNumber} ${docSnap.id}`
      );
    }),
    orders: ordersSnap.docs.map((docSnap) => {
      const data = docSnap.data() as Record<string, unknown>;
      const orderNumber = normalize(data.orderNumber) || docSnap.id;
      const customerName = normalize(data.customerName) || normalize(data.userName) || normalize(data.customerId);
      return makeOption(docSnap.id, `${orderNumber} • ${customerName || "Customer"}`, `${orderNumber} ${customerName} ${docSnap.id}`);
    }),
    bookings: bookingsSnap.docs.map((docSnap) => {
      const data = docSnap.data() as Record<string, unknown>;
      const bookingNumber = normalize(data.bookingNumber) || docSnap.id;
      const vehicle = `${normalize(data.vehicleBrand)} ${normalize(data.vehicleModel)}`.trim();
      return makeOption(docSnap.id, `${bookingNumber}${vehicle ? ` • ${vehicle}` : ""}`, `${bookingNumber} ${vehicle} ${docSnap.id}`);
    }),
  };
};
