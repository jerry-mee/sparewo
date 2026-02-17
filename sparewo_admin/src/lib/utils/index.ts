import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

type DateInput =
  | Date
  | null
  | undefined
  | string
  | number
  | { toDate(): Date }
  | { seconds: number; nanoseconds?: number };

// Merge Tailwind classes with clsx for conditional classes
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Format currency (UGX)
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-UG', {
    style: 'currency',
    currency: 'UGX',
  }).format(amount);
}

// Format date
function toValidDate(value: DateInput): Date | null {
  if (!value) return null;

  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }

  if (typeof value === "object") {
    if ("toDate" in value && typeof value.toDate === "function") {
      const converted = value.toDate();
      return Number.isNaN(converted.getTime()) ? null : converted;
    }

    if ("seconds" in value && typeof value.seconds === "number") {
      const millis = value.seconds * 1000 + Math.floor((value.nanoseconds || 0) / 1_000_000);
      const converted = new Date(millis);
      return Number.isNaN(converted.getTime()) ? null : converted;
    }
  }

  const converted = new Date(value as string | number);
  return Number.isNaN(converted.getTime()) ? null : converted;
}

// Format date
export function formatDate(date: DateInput): string {
  const safeDate = toValidDate(date);
  if (!safeDate) return "—";

  return new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  }).format(safeDate);
}

// Format date with time
export function formatDateTime(date: DateInput): string {
  const safeDate = toValidDate(date);
  if (!safeDate) return "—";

  return new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(safeDate);
}

// Truncate text
export function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return `${text.substring(0, maxLength)}...`;
}

// Get initials from name
export function getInitials(name: string): string {
  if (!name) return '';
  
  const parts = name.split(' ');
  if (parts.length === 1) return parts[0].charAt(0).toUpperCase();
  
  return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
}
