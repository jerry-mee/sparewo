"use client";

import { AuthProvider as AuthContextProvider } from '@/lib/context/auth-context';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  return <AuthContextProvider>{children}</AuthContextProvider>;
}
