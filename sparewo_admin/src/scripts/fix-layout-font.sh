#!/bin/bash

echo "Fixing layout.tsx font issue..."

# Create a fixed version of layout.tsx
cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from 'next';
import '@/styles/globals.css';
import { Providers } from './providers';
import ErrorBoundary from '@/components/ErrorBoundary';

export const metadata: Metadata = {
  title: 'SpareWo Admin Dashboard',
  description: 'Admin dashboard for the SpareWo platform',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="min-h-screen bg-gray-50 font-sans text-gray-900 antialiased dark:bg-boxdark dark:text-white">
        <Providers>
          <ErrorBoundary>
            {children}
          </ErrorBoundary>
        </Providers>
      </body>
    </html>
  );
}
EOF

echo "✅ Fixed layout.tsx font reference issue"