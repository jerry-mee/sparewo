# SpareWo Admin Dashboard - Technical Documentation

## 1. System Architecture

### 1.1 Overview

SpareWo is a comprehensive auto parts marketplace platform consisting of three main components:

1. **Admin Dashboard** (admin.sparewo.ug): Backend control panel for vetting vendors and products
2. **Vendor App** (vendor.sparewo.ug): Mobile and web application for auto parts suppliers
3. **Client App** (store.sparewo.ug): Consumer-facing marketplace for purchasing auto parts

This document focuses on the Admin Dashboard architecture, which serves as the control center for managing vendors, products, and the overall marketplace ecosystem.

### 1.2 Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       SpareWo Admin Dashboard                    │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────┐ │
│ │  User Interface │ │  Business Logic │ │      Data Layer     │ │
│ ├─────────────────┤ ├─────────────────┤ ├─────────────────────┤ │
│ │ - Next.js UI    │ │ - Context API   │ │ - Firebase Services │ │
│ │ - Tailwind CSS  │ │ - Custom Hooks  │ │ - Service Layer     │ │
│ │ - Components    │ │ - Authentication│ │ - Data Formatting   │ │
│ └─────────────────┘ └─────────────────┘ └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Firebase Backend Services                    │
├─────────────────┬─────────────────┬────────────────┬────────────┤
│ Authentication  │ Cloud Firestore │ Cloud Storage  │ Cloud      │
│ (Admin Accounts)│ (Core Data)     │ (Product Images)│ Functions │
└─────────────────┴─────────────────┴────────────────┴────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Vendor & Client Applications                   │
│ (Data synchronization, notifications, and content management)    │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Integration Architecture

The Admin Dashboard integrates with the broader SpareWo ecosystem through Firebase services:

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   Admin Panel  │────▶│ Firebase Cloud │────▶│  Vendor App    │
│                │◀────│   Platform     │◀────│                │
└────────────────┘     └────────────────┘     └────────────────┘
        │                     │                      │
        │                     │                      │
        ▼                     ▼                      ▼
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│  Client App    │◀───▶│ Order & Product│◀───▶│ Email & Notif. │
│  Marketplace   │     │   Processing   │     │   Services     │
└────────────────┘     └────────────────┘     └────────────────┘
```

## 2. Deployment Configuration

### 2.1 Vercel Deployment

The Admin Dashboard is deployed on Vercel with the following configuration:

#### Essential Files

1. **vercel.json**
```json
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/" }
  ],
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs"
}
```

2. **next.config.js**
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    unoptimized: true,
    domains: ['firebasestorage.googleapis.com'],
  },
  trailingSlash: true,
  webpack: (config, { isServer }) => {
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        child_process: false,
        undici: false,
      };
    }
    return config;
  },
}
module.exports = nextConfig
```

### 2.2 Environment Variables

Required environment variables for Vercel deployment:
- `NEXT_PUBLIC_FIREBASE_API_KEY`
- `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
- `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
- `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`
- `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`
- `NEXT_PUBLIC_FIREBASE_APP_ID`

## 3. Authentication Flow

### 3.1 Protected Routes

The application uses a middleware-based approach for route protection:

1. Unauthenticated users are redirected to `/auth/sign-in`
2. Authenticated users have access to the dashboard
3. Authentication state is managed via Firebase Auth and React Context

### 3.2 Authentication Components

- `AuthContext.tsx`: Manages authentication state and provides auth methods
- `useAuth.ts`: Custom hook for consuming auth context
- `middleware.ts`: Protects routes requiring authentication

## 4. Core Features and Implementation Status

### 4.1 Completed Features

- ✅ Admin authentication system
- ✅ Dashboard overview with navigation
- ✅ Product listing and detail views
- ✅ Vendor listing and detail views
- ✅ Catalog management interface
- ✅ Basic order management
- ✅ Dark/light theme support
- ✅ Responsive layout
- ✅ Vercel deployment configuration

### 4.2 In Progress

- ⚠️ Enhanced order fulfillment workflows
- ⚠️ Approval workflow optimization
- ⚠️ Advanced filtering and search
- ⚠️ Notification delivery system

### 4.3 Planned Features

- ⬜ Advanced analytics dashboard
- ⬜ Bulk operations for products/vendors
- ⬜ Enhanced communication tools
- ⬜ Integrated reporting system
- ⬜ User role management

## 5. Deployment Process

### 5.1 GitHub Repository Structure

```
sparewo/
├── sparewo_vendor/
└── sparewo_admin/
    ├── src/
    ├── public/
    ├── next.config.js
    ├── vercel.json
    └── package.json
```

### 5.2 Vercel Configuration

1. Root directory: `sparewo_admin`
2. Framework: Next.js
3. Build command: `npm run build`
4. Output directory: `.next`

### 5.3 Custom Domain Setup

1. Domain: admin.sparewo.ug
2. DNS Configuration: As per Vercel instructions
3. SSL: Automatically provisioned by Vercel

## 6. Troubleshooting

### 6.1 Common Issues

1. **404 Errors**: Ensure vercel.json with proper rewrites exists
2. **Authentication Failures**: Check Firebase authorized domains
3. **Build Failures**: Verify environment variables are set in Vercel

### 6.2 Debug Checklist

1. Check Vercel build logs
2. Verify root directory setting
3. Confirm environment variables
4. Test Firebase authentication
5. Validate routing configuration

## 7. Future Development

The admin dashboard is structured for expansion with:
- Modular component architecture
- Service-based data management
- Extensible routing system
- Scalable state management
