import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

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
export function formatDate(date: Date | null | undefined | any): string {
  if (!date) return '';
  
  // Handle Firestore timestamps
  if (typeof date === 'object' && date.toDate && typeof date.toDate === 'function') {
    date = date.toDate();
  }
  
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(new Date(date));
}

// Format date with time
export function formatDateTime(date: Date | null | undefined | any): string {
  if (!date) return '';
  
  // Handle Firestore timestamps
  if (typeof date === 'object' && date.toDate && typeof date.toDate === 'function') {
    date = date.toDate();
  }
  
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(date));
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