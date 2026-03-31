"use client";

import { ThemeProvider } from './theme-provider';
import { AuthProvider } from './auth-provider';
import { NotificationProvider } from './notification-provider';
import { ProductionConsoleGuard } from './production-console-guard';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider
      attribute="class"
      defaultTheme="light"
      enableSystem
      disableTransitionOnChange
    >
      <ProductionConsoleGuard />
      <AuthProvider>
        <NotificationProvider>{children}</NotificationProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}
