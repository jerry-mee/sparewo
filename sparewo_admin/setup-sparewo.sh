#!/bin/bash

# SpareWo Admin Dashboard Setup Script
# This script sets up the initial structure and core components for the SpareWo Admin Dashboard

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set the project directory
PROJECT_DIR="/Users/jeremy/Development/sparewo/sparewo_admin_revamp"

# Print header
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  SpareWo Admin Dashboard Setup Script  ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Clean directory - IMPORTANT: This will delete everything in the directory
echo -e "${YELLOW}⚠️  This script will delete all contents of: ${PROJECT_DIR}${NC}"
read -p "Are you sure you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Setup aborted${NC}"
    exit 1
fi

# Clean directory but keep the script itself
SCRIPT_NAME=$(basename "$0")
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${BLUE}🧹 Cleaning project directory...${NC}"
    # Create temp directory for the script
    mkdir -p /tmp/sparewo_script_backup
    # Copy this script to temp
    cp "$PROJECT_DIR/$SCRIPT_NAME" /tmp/sparewo_script_backup/
    # Remove all contents
    rm -rf "$PROJECT_DIR"/*
    # Recreate directory
    mkdir -p "$PROJECT_DIR"
    # Move script back
    mv /tmp/sparewo_script_backup/$SCRIPT_NAME "$PROJECT_DIR/"
    echo -e "${GREEN}✅ Directory cleaned successfully${NC}"
else
    echo -e "${BLUE}📁 Creating project directory: $PROJECT_DIR${NC}"
    mkdir -p "$PROJECT_DIR"
fi

# Navigate to project directory
cd "$PROJECT_DIR"

# Initialize Next.js project with TypeScript
echo -e "${BLUE}🚀 Initializing Next.js project...${NC}"
npx create-next-app@latest temp-app --ts --tailwind --eslint --app --src-dir --import-alias "@/*" --no-git

# Check if temp-app directory was created
if [ ! -d "temp-app" ]; then
    echo -e "${RED}❌ Failed to create Next.js project${NC}"
    exit 1
fi

# Move all contents from temp-app to current directory
echo -e "${BLUE}📦 Setting up project structure...${NC}"
mv temp-app/* .
mv temp-app/.* . 2>/dev/null || true  # Move hidden files, ignore errors for . and ..
rmdir temp-app

# Verify package.json exists
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json not found. Project initialization failed.${NC}"
    exit 1
fi

# Update package name in package.json
sed -i '' 's/"name": "temp-app"/"name": "sparewo_admin_revamp"/g' package.json

# Install required dependencies
echo -e "${BLUE}📦 Installing dependencies...${NC}"
npm install --legacy-peer-deps firebase react-hook-form zod @hookform/resolvers next-themes lucide-react clsx tailwind-merge

# Install shadcn CLI
echo -e "${BLUE}🎨 Setting up shadcn components...${NC}"
npm install --legacy-peer-deps -D @shadcn/ui

# Initialize shadcn (using the project that already exists)
echo -e "${BLUE}✨ Initializing shadcn...${NC}"

# Create a components.json configuration file manually instead of using the shadcn init command
echo -e "${BLUE}📝 Creating shadcn configuration...${NC}"
cat > components.json << 'EOL'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "src/app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils"
  }
}
EOL

# Create utils.ts for shadcn
mkdir -p src/lib
cat > src/lib/utils.ts << 'EOL'
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"
 
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOL

# Install shadcn components individually
echo -e "${BLUE}🧩 Installing UI components...${NC}"
components=("button" "card" "input" "label" "avatar" "dropdown-menu" "table" "tabs" "toggle" "dialog" "select" "badge")

# Install sonner for toast notifications instead of toast component
npm install --legacy-peer-deps sonner

for component in "${components[@]}"; do
    echo -e "${BLUE}⚙️  Installing ${component} component...${NC}"
    npx shadcn@latest add $component --yes
done

# Create sonner toast provider
mkdir -p src/components/ui
cat > src/components/ui/toaster.tsx << 'EOL'
"use client";

import { Toaster as SonnerToaster } from "sonner";

export function Toaster() {
  return (
    <SonnerToaster 
      position="bottom-right"
      toastOptions={{
        style: {
          background: "hsl(var(--card))",
          color: "hsl(var(--card-foreground))",
          border: "1px solid hsl(var(--border))"
        },
      }}
    />
  );
}
EOL

# Create directory structure
echo -e "${BLUE}📂 Creating directory structure...${NC}"
mkdir -p src/app/\(auth\)/login
mkdir -p src/app/\(auth\)/forgot-password
mkdir -p src/app/\(dashboard\)/vendors/pending
mkdir -p src/app/\(dashboard\)/vendors/\[id\]
mkdir -p src/app/\(dashboard\)/products/pending
mkdir -p src/app/\(dashboard\)/products/\[id\]
mkdir -p src/components/layout
mkdir -p src/components/dashboard
mkdir -p src/components/ui
mkdir -p src/components/vendor
mkdir -p src/components/product
mkdir -p src/components/providers
mkdir -p src/lib/firebase/{auth,db,vendors,products}
mkdir -p src/lib/context
mkdir -p src/lib/hooks
mkdir -p src/lib/types
mkdir -p src/lib/utils
mkdir -p public/images

# Create theme provider component
cat > src/components/providers/theme-provider.tsx << 'EOL'
"use client";

import * as React from "react";
import { ThemeProvider as NextThemesProvider } from "next-themes";
import { type ThemeProviderProps } from "next-themes/dist/types";

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}
EOL

# Create base utils.ts
cat > src/lib/utils/index.ts << 'EOL'
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

// Merge Tailwind classes with clsx for conditional classes
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Format currency
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-UG', {
    style: 'currency',
    currency: 'UGX',
  }).format(amount);
}

// Format date
export function formatDate(date: Date | null | undefined): string {
  if (!date) return '';
  
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(date);
}

// Format date with time
export function formatDateTime(date: Date | null | undefined): string {
  if (!date) return '';
  
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
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
EOL

# Create type definitions
cat > src/lib/types/index.ts << 'EOL'
export interface AdminUser {
  id: string;
  email: string;
  displayName: string;
  role: 'superAdmin' | 'admin' | 'viewer';
  createdAt: any;
  updatedAt: any;
}

export interface VendorStatus {
  value: 'pending' | 'approved' | 'rejected';
  label: string;
  color: string;
}

export interface ProductStatus {
  value: 'pending' | 'approved' | 'rejected';
  label: string;
  color: string;
}

export const VENDOR_STATUSES: VendorStatus[] = [
  { value: 'pending', label: 'Pending Review', color: 'bg-status-pending' },
  { value: 'approved', label: 'Approved', color: 'bg-status-approved' },
  { value: 'rejected', label: 'Rejected', color: 'bg-status-rejected' },
];

export const PRODUCT_STATUSES: ProductStatus[] = [
  { value: 'pending', label: 'Pending Review', color: 'bg-status-pending' },
  { value: 'approved', label: 'Approved', color: 'bg-status-approved' },
  { value: 'rejected', label: 'Rejected', color: 'bg-status-rejected' },
];
EOL

# Create .env.local file for Firebase configuration
echo -e "${BLUE}📝 Creating .env.local file template...${NC}"
cat > .env.local << 'EOL'
# Firebase configuration
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=

# Application settings
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOL

# Update tailwind.config.js/ts with SpareWo colors
echo -e "${BLUE}🎨 Configuring Tailwind with SpareWo theme colors...${NC}"

# Create tailwind.config.js
cat > tailwind.config.js << 'EOL'
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        // SpareWo Theme Colors from theme.dart
        primary: {
          DEFAULT: "#FF9800", // VendorColors.primary
          foreground: "#ffffff",
        },
        secondary: {
          DEFAULT: "#1A1B4B", // VendorColors.secondary
          foreground: "#ffffff",
        },
        background: "#F5F5F5", // VendorColors.background
        card: "#FFFFFF", // VendorColors.cardBackground
        text: {
          DEFAULT: "#2D2D2D", // VendorColors.text
          light: "#757575", // VendorColors.textLight
        },
        status: {
          error: "#D32F2F", // VendorColors.error
          success: "#388E3C", // VendorColors.success
          pending: "#FFA726", // VendorColors.pending
          approved: "#66BB6A", // VendorColors.approved
          rejected: "#EF5350", // VendorColors.rejected
        },
        border: "#E0E0E0", // VendorColors.divider
        input: "#FFFFFF",
        ring: "#FF9800",
        destructive: {
          DEFAULT: "#D32F2F",
          foreground: "#FFFFFF",
        },
        muted: {
          DEFAULT: "#F5F5F5",
          foreground: "#757575",
        },
        accent: {
          DEFAULT: "#1A1B4B",
          foreground: "#FFFFFF",
        },
        popover: {
          DEFAULT: "#FFFFFF",
          foreground: "#2D2D2D",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      fontFamily: {
        sans: ["var(--font-poppins)"],
      },
      keyframes: {
        "accordion-down": {
          from: { height: 0 },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: 0 },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
EOL

# Update next.config.js
echo -e "${BLUE}⚙️ Creating Next.js configuration...${NC}"
cat > next.config.js << 'EOL'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['firebasestorage.googleapis.com'],
  },
  webpack: (config) => {
    return config;
  },
}

module.exports = nextConfig
EOL

# Create basic app layout file
echo -e "${BLUE}📝 Creating app layout file...${NC}"
cat > src/app/layout.tsx << 'EOL'
import { Poppins } from "next/font/google";
import { ThemeProvider } from "@/components/providers/theme-provider";
import { Toaster } from "@/components/ui/toaster";
import "./globals.css";

import type { Metadata } from "next";

const poppins = Poppins({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-poppins",
});

export const metadata: Metadata = {
  title: "SpareWo Admin Dashboard",
  description: "Admin dashboard for the SpareWo auto parts marketplace",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${poppins.variable} font-sans`}>
        <ThemeProvider
          attribute="class"
          defaultTheme="light"
          enableSystem
          disableTransitionOnChange
        >
          {children}
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}
EOL

# Create simple dashboard placeholder
echo -e "${BLUE}📝 Creating dashboard placeholder...${NC}"
cat > src/app/page.tsx << 'EOL'
import { redirect } from "next/navigation";

export default function Home() {
  redirect("/dashboard");
}
EOL

cat > src/app/\(dashboard\)/page.tsx << 'EOL'
"use client";

import React from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function Dashboard() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-text dark:text-white">Dashboard</h1>
        <p className="mt-1 text-text-light dark:text-gray-400">
          Welcome to SpareWo Admin Dashboard
        </p>
      </div>
      
      <Card>
        <CardHeader>
          <CardTitle>Getting Started</CardTitle>
          <CardDescription>Your admin dashboard is ready!</CardDescription>
        </CardHeader>
        <CardContent>
          <p>You can now create the core components and functionality for:</p>
          <ul className="list-disc pl-5 mt-2 space-y-1">
            <li>Vendor management</li>
            <li>Product approval</li>
            <li>Catalog management</li>
            <li>Order processing</li>
          </ul>
        </CardContent>
      </Card>
    </div>
  );
}
EOL

# Create minimal dashboard layout
echo -e "${BLUE}📝 Creating dashboard layout...${NC}"
cat > src/app/\(dashboard\)/layout.tsx << 'EOL'
"use client";

import React, { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Button } from "@/components/ui/button";
import {
  LayoutDashboard,
  Users,
  Package,
  ShoppingCart,
  Settings,
  Menu,
  X,
} from "lucide-react";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const pathname = usePathname();
  
  const toggleSidebar = () => {
    setIsSidebarOpen(!isSidebarOpen);
  };
  
  // Navigation items
  const navItems = [
    {
      title: 'Dashboard',
      href: '/dashboard',
      icon: <LayoutDashboard size={20} />,
      active: pathname === '/dashboard',
    },
    {
      title: 'Vendors',
      href: '/vendors',
      icon: <Users size={20} />,
      active: pathname.startsWith('/vendors'),
    },
    {
      title: 'Products',
      href: '/products',
      icon: <Package size={20} />,
      active: pathname.startsWith('/products'),
    },
    {
      title: 'Orders',
      href: '/orders',
      icon: <ShoppingCart size={20} />,
      active: pathname.startsWith('/orders'),
    },
    {
      title: 'Settings',
      href: '/settings',
      icon: <Settings size={20} />,
      active: pathname.startsWith('/settings'),
    },
  ];
  
  return (
    <div className="flex h-screen bg-background dark:bg-gray-900">
      {/* Sidebar */}
      <div
        className={`${
          isSidebarOpen ? "w-64" : "w-20"
        } bg-secondary fixed inset-y-0 left-0 z-30 transition-all duration-300 ease-in-out flex flex-col`}
      >
        {/* Logo */}
        <div className="flex items-center justify-between h-16 px-4 border-b border-opacity-20 border-gray-600">
          {isSidebarOpen ? (
            <div className="text-lg font-semibold text-white">SpareWo Admin</div>
          ) : (
            <div className="text-lg font-semibold text-white">SW</div>
          )}
          <button onClick={toggleSidebar} className="text-white">
            {isSidebarOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
        
        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-4">
          <div className="px-4 space-y-1">
            {navItems.map((item) => (
              <Link key={item.title} href={item.href}>
                <div
                  className={`flex items-center py-2 px-3 rounded-md cursor-pointer transition-colors ${
                    item.active
                      ? "bg-primary text-white"
                      : "text-gray-300 hover:bg-primary hover:bg-opacity-30 hover:text-white"
                  }`}
                >
                  <div className="flex items-center justify-center">
                    {item.icon}
                  </div>
                  {isSidebarOpen && <span className="ml-3 text-sm">{item.title}</span>}
                </div>
              </Link>
            ))}
          </div>
        </nav>
        
        {/* User */}
        <div className="p-4 border-t border-gray-600 border-opacity-20">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white font-medium">
                A
              </div>
            </div>
            {isSidebarOpen && (
              <div className="ml-3">
                <p className="text-sm font-medium text-white">Admin User</p>
                <p className="text-xs text-gray-300">Admin</p>
              </div>
            )}
          </div>
        </div>
      </div>
      
      {/* Main Content */}
      <div
        className={`flex-1 ${
          isSidebarOpen ? "ml-64" : "ml-20"
        } transition-all duration-300 ease-in-out`}
      >
        {/* Header */}
        <header
          className={`fixed right-0 ${
            isSidebarOpen ? "left-64" : "left-20"
          } h-16 z-20 flex items-center justify-between px-4 border-b bg-background dark:bg-gray-800 border-border dark:border-gray-700 transition-all duration-300`}
        >
          <div className="flex items-center">
            <h1 className="text-xl font-semibold text-text dark:text-white mr-4">
              {pathname === '/dashboard' ? 'Dashboard' : pathname.split('/').pop()?.charAt(0).toUpperCase() + pathname.split('/').pop()?.slice(1)}
            </h1>
          </div>
        </header>
        
        {/* Main content */}
        <main className="pt-24 px-6 pb-6 min-h-screen">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
EOL

# Create middleware.ts for route protection
echo -e "${BLUE}🔒 Creating authentication middleware...${NC}"
cat > src/middleware.ts << 'EOL'
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
 
// This function can be marked `async` if using `await` inside
export function middleware(request: NextRequest) {
  // Get the pathname of the request
  const path = request.nextUrl.pathname;
  
  // Define public paths that don't require authentication
  const isPublicPath = path === '/login' || path === '/forgot-password';
  
  // Get the token from the cookies
  const token = request.cookies.get('auth-token')?.value || '';
  
  // Redirect logic
  if (isPublicPath && token) {
    // If user is authenticated and tries to access login page,
    // redirect to dashboard
    return NextResponse.redirect(new URL('/', request.url));
  }
  
  if (!isPublicPath && !token) {
    // If user is not authenticated and tries to access protected route,
    // redirect to login page
    return NextResponse.redirect(new URL('/login', request.url));
  }
}
 
// See "Matching Paths" below to learn more
export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
EOL

echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Edit the ${YELLOW}.env.local${NC} file with your Firebase configuration"
echo -e "2. Run ${YELLOW}npm run dev${NC} to start the development server"
echo -e "3. Visit ${YELLOW}http://localhost:3000${NC} to see your application"
echo ""
echo -e "${YELLOW}⚠️ Important:${NC} You now need to create the actual components and pages."
echo -e "This script has only set up the project structure and dependencies."