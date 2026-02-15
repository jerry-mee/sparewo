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

Key integration points:
- Admin dashboard approves vendors and products for visibility to clients
- Two separate catalogs maintained (vendor-facing and client-facing)
- Order fulfillment coordinated between vendors and clients
- Notification system for cross-platform communication

## 2. Admin User Journey

### 2.1 Admin User Flow

```
┌───────────┐     ┌───────────────┐     ┌───────────────────┐
│ Admin     │     │Dashboard      │     │ Vendor            │
│ Login     │────▶│Overview       │────▶│ Management        │
└───────────┘     └───────────────┘     └───────────────────┘
                                                 │
                                                 ▼
┌───────────┐     ┌───────────────┐     ┌───────────────────┐
│ Order     │◀────│ Catalog       │◀────│ Product           │
│ Management│     │ Management    │     │ Approval          │
└───────────┘     └───────────────┘     └───────────────────┘
      │                                        │
      │                                        │
      ▼                                        ▼
┌───────────┐                          ┌───────────────────┐
│ AutoHub   │                          │ Notification      │
│ Requests  │                          │ Management        │
└───────────┘                          └───────────────────┘
```

### 2.2 Detailed Flow Description

1. **Admin Login**
   - Secure authentication via Firebase Auth
   - Role-based access control for admin privileges
   - Session management and persistence

2. **Dashboard Overview**
   - Key metrics and statistics at a glance
   - Pending approvals for vendors and products
   - Recent orders and system activity
   - Quick action links to main functions

3. **Vendor Management**
   - Review and approve vendor applications
   - Manage vendor information and status
   - View vendor performance metrics
   - Suspend or revoke vendor access when needed

4. **Product Approval**
   - Review products submitted by vendors
   - Verify product information and compatibility
   - Approve or reject products for client visibility
   - Manage product categories and attributes

5. **Catalog Management**
   - Maintain separate vendor and client catalogs
   - Control which approved products appear in client store
   - Organize products by categories
   - Set featured products and promotions

6. **Order Management**
   - Track orders from placement to fulfillment
   - Assign orders to appropriate vendors
   - Monitor delivery status
   - Handle order issues and special requests

7. **AutoHub Requests**
   - Manage garage service requests
   - Coordinate vehicle repair services
   - Track service appointments and status
   - Communicate with service providers

8. **Notification Management**
   - Create and send system notifications
   - Target notifications to specific user groups
   - Track notification delivery and read status
   - Manage email communications

## 3. Technical Implementation

### 3.1 Core Technologies

- **Framework**: Next.js (React, TypeScript)
- **Styling**: Tailwind CSS
- **State Management**: React Context API + Custom Hooks
- **Backend**: Firebase (Authentication, Firestore, Storage, Functions)
- **Architecture**: App Router with Server Components
- **UI Components**: Custom component library
- **Navigation**: Next.js App Router
- **Error Handling**: Custom error boundaries and handlers

### 3.2 Authentication System

The app implements Firebase Authentication for admin access control:

```
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Sign-in Screen │      │ Firebase Auth  │      │ Firestore      │
│ (UI Layer)     │      │ (Identity)     │      │ (User Data)    │
└───────┬────────┘      └───────┬────────┘      └───────┬────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ AuthContext    │      │ useAuth Hook   │      │ User Service   │
│ (State)        │◀────▶│ (Custom Hook)  │◀────▶│ (Data Access)  │
└───────┬────────┘      └────────────────┘      └────────────────┘
        │
        ▼
┌────────────────┐
│ Layout Router  │
│ (Protection)   │
└────────────────┘
```

Key files:
- `/context/AuthContext.tsx`: Central auth state management
- `/hooks/useAuth.ts`: Custom hook for auth operations
- `/services/firebase.service.ts`: Firebase integration
- `/components/Auth/Signin.tsx`: Authentication UI
- `/app/auth/sign-in/page.tsx`: Sign-in page
- `/middleware.ts`: Route protection middleware

### 3.3 Catalog Management System

The catalog management system handles both the general and client-facing product catalogs:

```
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Catalog UI     │      │ Firestore      │      │ Storage        │
│ (Page)         │      │ (Products DB)  │      │ (Images)       │
└───────┬────────┘      └───────┬────────┘      └───────┬────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Product State  │      │ Product Service│      │ Image Upload   │
│ (Context)      │◀────▶│ (Data Layer)   │◀────▶│ (Utility)      │
└────────────────┘      └────────────────┘      └────────────────┘
```

Key files:
- `/app/catalogs/page.tsx`: Catalog management UI
- `/app/products/page.tsx`: Product listing interface
- `/app/products/[id]/page.tsx`: Product detail view
- `/app/products/new/page.tsx`: Product creation form
- `/services/firebase.service.ts`: Product data operations

### 3.4 Vendor Management System

The vendor management system handles vendor verification and management:

```
┌────────────────┐      ┌────────────────┐      
│ Vendor UI      │      │ Firestore      │      
│ (Pages)        │      │ (Vendor DB)    │      
└───────┬────────┘      └───────┬────────┘      
        │                       │                
        ▼                       ▼                
┌────────────────┐      ┌────────────────┐      
│ Vendor State   │      │ Vendor Service │      
│ (Context)      │◀────▶│ (Data Layer)   │      
└────────────────┘      └────────────────┘      
```

Key files:
- `/app/vendors/page.tsx`: Vendor listing interface
- `/app/vendors/[id]/page.tsx`: Vendor detail view
- `/app/vendors/pending/page.tsx`: Pending vendor approvals
- `/services/firebase.service.ts`: Vendor data operations

### 3.5 Order Management System

The order management system handles the complete order lifecycle:

```
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Order UI       │      │ Firestore      │      │ Email Service  │
│ (Pages)        │      │ (Orders DB)    │      │ (Notifications)│
└───────┬────────┘      └───────┬────────┘      └───────┬────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Order State    │      │ Order Service  │      │ Notification   │
│ (Context)      │◀────▶│ (Data Layer)   │◀────▶│ Service        │
└────────────────┘      └────────────────┘      └────────────────┘
```

Key files:
- `/app/orders/page.tsx`: Order management interface
- `/services/firebase.service.ts`: Order data operations
- `/services/email.service.ts`: Email notification service

### 3.6 Notification System

The notification system manages communications across the platform:

```
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Notification UI│      │ Firestore      │      │ Email Service  │
│ (Pages)        │      │ (Notif. DB)    │      │ (Delivery)     │
└───────┬────────┘      └───────┬────────┘      └───────┬────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Notification   │      │ Notification   │      │ Email Templates│
│ State          │◀────▶│ Service        │◀────▶│                │
└────────────────┘      └────────────────┘      └────────────────┘
```

Key files:
- `/app/notifications/page.tsx`: Notification management interface
- `/services/notification.service.ts`: Notification operations
- `/services/email.service.ts`: Email delivery service

## 4. Component Structure

### 4.1 Directory Organization

```
src/
├── app/                          # Next.js App Router pages
│   ├── (home)/                   # Protected home routes
│   │   ├── catalogs/             # Catalog management
│   │   ├── layout.tsx            # Protected layout
│   │   └── page.tsx              # Dashboard home
│   ├── auth/                     # Authentication pages
│   │   └── sign-in/              # Login page
│   ├── autohub/                  # Garage service management
│   ├── notifications/            # Notification management
│   ├── orders/                   # Order management
│   ├── products/                 # Product management
│   │   ├── [id]/                 # Product detail
│   │   ├── new/                  # New product
│   │   └── pending/              # Pending approval
│   ├── settings/                 # App settings
│   ├── users/                    # User management
│   └── vendors/                  # Vendor management
│       ├── [id]/                 # Vendor detail
│       └── pending/              # Pending approval
├── components/                   # Reusable UI components
│   ├── Auth/                     # Authentication components
│   ├── Breadcrumbs/              # Navigation breadcrumbs
│   ├── Layouts/                  # Layout components
│   │   ├── header/               # App header
│   │   └── sidebar/              # Navigation sidebar
│   ├── LoadingScreen.tsx         # Loading indicator
│   └── ui/                       # UI components
├── context/                      # React context providers
│   └── AuthContext.tsx           # Authentication context
├── hooks/                        # Custom React hooks
│   ├── use-click-outside.ts      # Click detection
│   ├── use-mobile.ts             # Responsive detection
│   └── useAuth.ts                # Auth hook
├── services/                     # Backend service layer
│   ├── email.service.ts          # Email operations
│   ├── firebase.service.ts       # Firebase integration
│   ├── notification.service.ts   # Notification operations
│   └── user.service.ts           # User operations
├── styles/                       # Global styling
└── utils/                        # Utility functions
    ├── firebaseErrorHandler.ts   # Error handling
    ├── format-number.ts          # Number formatting
    └── formatDate.ts             # Date formatting
```

### 4.2 Key Components

1. **Layouts**
   - `DefaultLayout`: Main application layout with sidebar and header
   - `PageContainer`: Standardized page structure
   - `Sidebar`: Navigation menu
   - `Header`: Top navigation bar

2. **Authentication**
   - `AuthContext`: Authentication state provider
   - `Signin`: Login form component
   - `useAuth`: Authentication hook

3. **Dashboard**
   - `StatCard`: Metric display components
   - `DashboardCard`: Information card components
   - Dashboard charts and visualizations

4. **Data Management**
   - Table components for data display
   - Form components for data entry
   - Filter and search components

5. **UI Elements**
   - `Breadcrumb`: Navigation breadcrumbs
   - `LoadingScreen`: Loading indicator
   - Modal components
   - Card components

## 5. Implementation Status

### 5.1 Completed Features

- ✅ Admin authentication system
- ✅ Dashboard overview
- ✅ Product listing and detail views
- ✅ Vendor listing and detail views
- ✅ Catalog management
- ✅ Basic order management
- ✅ Dark/light theme support
- ✅ Responsive layout

### 5.2 In Progress

- ⚠️ Enhanced order fulfillment workflows
- ⚠️ Approval workflow optimization
- ⚠️ Advanced filtering and search
- ⚠️ Notification delivery system

### 5.3 Planned Features

- ⬜ Advanced analytics dashboard
- ⬜ Bulk operations for products/vendors
- ⬜ Enhanced communication tools
- ⬜ Integrated reporting system
- ⬜ User role management