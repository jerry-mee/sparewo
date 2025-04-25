'use client';

import React, { createContext, useContext, useState, useCallback, ReactNode } from 'react';
import { X, CheckCircle, AlertTriangle, Info, AlertCircle } from 'lucide-react'; // Added AlertCircle
import { cn } from '@/lib/utils'; // Assuming cn utility

// Define Toast types
type ToastType = 'success' | 'error' | 'info' | 'warning';

// Define Toast structure
interface Toast {
  id: string;
  message: string | ReactNode; // Allow ReactNode for richer content
  type: ToastType;
  duration?: number; // Duration in ms, Infinity for manual close
}

// Define Context shape
interface ToastContextType {
  toasts: Toast[];
  addToast: (message: string | ReactNode, type: ToastType, duration?: number) => string; // Returns ID
  removeToast: (id: string) => void;
}

// Create Context
const ToastContext = createContext<ToastContextType | undefined>(undefined);

// Toast Provider Component
export const ToastProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [toasts, setToasts] = useState<Toast[]>([]);

  // Function to remove a toast
  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(toast => toast.id !== id));
  }, []);

  // Function to add a new toast
  const addToast = useCallback((message: string | ReactNode, type: ToastType, duration = 5000): string => {
    const id = String(Date.now()) + Math.random().toString(36).substring(2, 9); // More unique ID
    const newToast: Toast = { id, message, type, duration };

    setToasts(prev => [newToast, ...prev]); // Add new toast to the beginning

    // Set timeout for auto-removal if duration is not Infinity
    if (duration !== Infinity) {
      setTimeout(() => {
        removeToast(id);
      }, duration);
    }
    return id; // Return the ID in case manual removal is needed elsewhere
  }, [removeToast]);

  // Render Provider and the Toast Container
  return (
    <ToastContext.Provider value={{ toasts, addToast, removeToast }}>
      {children}
      {/* Toast Container - Fixed position */}
      <div className="fixed bottom-4 right-4 z-[100] flex w-full max-w-sm flex-col-reverse gap-3 p-4 md:bottom-6 md:right-6">
        {toasts.map(toast => (
          <ToastComponent key={toast.id} toast={toast} onDismiss={removeToast} />
        ))}
      </div>
    </ToastContext.Provider>
  );
};

// Hook to use the Toast context
export const useToast = () => {
  const context = useContext(ToastContext);
  if (context === undefined) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return context;
};

// --- Internal Toast Component ---
interface ToastComponentProps {
  toast: Toast;
  onDismiss: (id: string) => void;
}

const ToastComponent: React.FC<ToastComponentProps> = ({ toast, onDismiss }) => {
  const { id, message, type } = toast;

  // Define styles and icons based on toast type
  const typeStyles = {
    success: {
      icon: <CheckCircle className="h-5 w-5 text-green-500" />,
      classes: 'bg-green-50 border-green-200 dark:bg-green-900/30 dark:border-green-700/50 text-green-800 dark:text-green-300',
    },
    error: {
      icon: <AlertCircle className="h-5 w-5 text-red-500" />, // Using AlertCircle for error
      classes: 'bg-red-50 border-red-200 dark:bg-red-900/30 dark:border-red-700/50 text-red-800 dark:text-red-300',
    },
    warning: {
      icon: <AlertTriangle className="h-5 w-5 text-yellow-500" />,
      classes: 'bg-yellow-50 border-yellow-200 dark:bg-yellow-900/30 dark:border-yellow-700/50 text-yellow-800 dark:text-yellow-300',
    },
    info: {
      icon: <Info className="h-5 w-5 text-blue-500" />,
      classes: 'bg-blue-50 border-blue-200 dark:bg-blue-900/30 dark:border-blue-700/50 text-blue-800 dark:text-blue-300',
    },
  };

  const { icon, classes } = typeStyles[type];

  // Add animation classes (example using simple fade-in/out)
  // You might replace this with a more sophisticated animation library like framer-motion
  const animationClasses = "animate-toast-in"; // Define 'toast-in' keyframes in your global CSS

  return (
    <div
      role="alert"
      aria-live="assertive" // Important for accessibility
      className={cn(
        "relative flex w-full items-start gap-3 rounded-lg border p-4 shadow-lg",
        classes,
        animationClasses
      )}
    >
      <div className="flex-shrink-0">{icon}</div>
      <div className="flex-1 text-sm font-medium">{message}</div>
      <button
        type="button"
        onClick={() => onDismiss(id)}
        className={cn(
          "absolute top-2 right-2 rounded-md p-1 opacity-70 transition-opacity hover:opacity-100 focus:outline-none focus:ring-2",
          // Adjust focus ring color based on type for better visibility
           type === 'success' ? 'focus:ring-green-400' :
           type === 'error' ? 'focus:ring-red-400' :
           type === 'warning' ? 'focus:ring-yellow-400' :
           'focus:ring-blue-400'
        )}
        aria-label="Dismiss notification"
      >
        <X className="h-4 w-4" />
      </button>
    </div>
  );
};

// Add Keyframes to your global CSS (e.g., styles/globals.css) for animation:
/*
@keyframes toast-in {
  from {
    opacity: 0;
    transform: translateY(1rem) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}
.animate-toast-in {
  animation: toast-in 0.3s ease-out forwards;
}
*/
