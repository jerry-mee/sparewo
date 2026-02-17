import { Badge } from "@/components/ui/badge";

type StatusTone =
  | "pending"
  | "approved"
  | "rejected"
  | "suspended"
  | "processing"
  | "confirmed"
  | "in_progress"
  | "completed"
  | "cancelled"
  | "shipped"
  | "delivered"
  | "accepted"
  | "default";

const STATUS_CLASSES: Record<StatusTone, string> = {
  pending: "bg-amber-500 text-white",
  approved: "bg-green-500 text-white",
  rejected: "bg-red-500 text-white",
  suspended: "bg-slate-600 text-white",
  processing: "bg-blue-500 text-white",
  confirmed: "bg-sky-600 text-white",
  in_progress: "bg-indigo-600 text-white",
  completed: "bg-emerald-600 text-white",
  cancelled: "bg-rose-600 text-white",
  shipped: "bg-cyan-600 text-white",
  delivered: "bg-teal-600 text-white",
  accepted: "bg-lime-600 text-white",
  default: "bg-slate-500 text-white",
};

interface StatusPillProps {
  status: string;
  label?: string;
  className?: string;
}

const normalizeStatus = (status: string): StatusTone => {
  const normalized = status.trim().toLowerCase();
  if (normalized in STATUS_CLASSES) {
    return normalized as StatusTone;
  }
  return "default";
};

const toLabel = (status: string): string =>
  status
    .replaceAll("_", " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());

export function StatusPill({ status, label, className = "" }: StatusPillProps) {
  const tone = normalizeStatus(status);
  const text = label || toLabel(status);

  return <Badge className={`${STATUS_CLASSES[tone]} ${className}`}>{text}</Badge>;
}
