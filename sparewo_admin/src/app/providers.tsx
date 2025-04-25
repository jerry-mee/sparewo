'use client';

import React from 'react';
import { ThemeProvider } from 'next-themes';
import { AuthProvider } from '@/context/AuthContext'; // Assuming AuthContext exists
import { ToastProvider } from '@/components/ui/toast-provider'; // Import the ToastProvider
import { SidebarProvider } from '@/components/Layouts/sidebar/sidebar-context'; // Import SidebarProvider

// Consolidate all application-wide context providers here
export function Providers({ children }: { children: React.ReactNode }) {
  return (
    // Theme Provider (for dark/light mode)
    // attribute="class" enables class-based theming (e.g., <html class="dark">)
    // defaultTheme="system" respects user's OS preference
    // enableSystem allows switching between light, dark, and system themes
    <ThemeProvider
        attribute="class"
        defaultTheme="system"
        enableSystem
        disableTransitionOnChange // Optional: Prevent theme transition flashing
    >
      {/* Authentication Provider (manages user session) */}
      <AuthProvider>
        {/* Toast Notification Provider */}
        <ToastProvider>
           {/* Sidebar State Provider */}
           <SidebarProvider>
              {/* Render the actual application content */}
              {children}
            </SidebarProvider>
        </ToastProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}
