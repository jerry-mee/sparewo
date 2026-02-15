# SpareWo Admin Dashboard Documentation

## 1. Introduction

The SpareWo Admin Dashboard is a web-based control panel for managing SpareWo's auto parts marketplace. It provides interfaces for vendor approval, product management, catalog curation, and order processing. This document outlines the structure, functionality, and integrations of the dashboard.

## 2. System Architecture

### 2.1 Technology Stack

- **Frontend Framework**: Next.js 15.x with App Router
- **UI Framework**: Tailwind CSS with shadcn/ui components
- **State Management**: React Context API and Hooks
- **Authentication**: Firebase Authentication
- **Database**: Firebase Firestore
- **Storage**: Firebase Storage
- **Hosting**: Vercel

### 2.2 Project Structure

```
src/
├── app/
│   ├── (auth)/                   # Authentication routes (grouped)
│   │   ├── login/                # Login page
│   │   └── forgot-password/      # Password recovery
│   ├── dashboard/                # Dashboard routes
│   │   ├── layout.tsx            # Dashboard layout with sidebar/header
│   │   ├── page.tsx              # Dashboard home/overview
│   │   ├── products/             # Product management
│   │   │   ├── [id]/             # Product details
│   │   │   └── pending/          # Pending products
│   │   └── vendors/              # Vendor management
│   │       ├── [id]/             # Vendor details
│   │       └── pending/          # Pending vendors
│   ├── layout.tsx                # Root layout
│   └── page.tsx                  # Root page (redirects to dashboard)
├── components/
│   ├── dashboard/                # Dashboard-specific components
│   ├── layout/                   # Layout components
│   ├── product/                  # Product management components
│   ├── providers/                # Context providers
│   ├── ui/                       # Shadcn UI components
│   └── vendor/                   # Vendor management components
├── lib/
│   ├── context/                  # Context providers
│   ├── firebase/                 # Firebase integration
│   │   ├── auth/                 # Authentication functions
│   │   ├── db/                   # Database operations
│   │   ├── products/             # Product operations
│   │   └── vendors/              # Vendor operations
│   ├── hooks/                    # Custom hooks
│   ├── types/                    # TypeScript type definitions
│   └── utils/                    # Utility functions
└── middleware.ts                 # Authentication middleware
```

## 3. Layout and UI Components

### 3.1 Core Layouts

- **Root Layout**: Provides theme context and global styling
- **Dashboard Layout**: Implements the main application layout with:
  - Responsive sidebar navigation
  - Top header with theme toggle and notifications
  - Main content area
  - User profile section

### 3.2 UI Components

- **Sidebar**: Collapsible navigation with active state indicators
- **Header**: Page title display with theme toggle and notifications
- **Stat Card**: Displays key metrics with icons and change indicators
- **Activity Item**: Shows recent activities with status indicators
- **Action Buttons**: Quick access buttons for common actions
- **Data Tables**: For listing vendors, products, and orders
- **Forms**: For data entry and editing
- **Modal Dialogs**: For confirmations and quick edits

## 4. Pages and Features

### 4.1 Authentication

- **Login Page**: Email/password authentication
- **Password Recovery**: Reset password functionality
- **Route Protection**: Redirects unauthenticated users to login

### 4.2 Dashboard Overview

- **Stats Overview**: Displays key metrics (vendors, products, approvals, orders)
- **Recent Activity**: Shows recent system activities
- **Quick Actions**: Provides shortcuts to common tasks

### 4.3 Vendor Management

- **Vendor Listing**: Displays all vendors with filtering and search
- **Vendor Details**: Shows vendor information and associated products
- **Vendor Approval**: Workflow for reviewing and approving/rejecting vendors
- **Vendor Metrics**: Statistics on vendor performance

### 4.4 Product Management

- **Product Listing**: Displays all products with filtering and search
- **Product Details**: Shows product information with images
- **Product Approval**: Workflow for reviewing and approving/rejecting products
- **Catalog Integration**: Controls which products appear in the client-facing catalog

### 4.5 Order Management

- **Order Listing**: Displays all orders with status filtering
- **Order Details**: Shows order information and items
- **Order Assignment**: Workflow for assigning orders to vendors
- **Order Status Tracking**: Monitors order progress

## 5. Firebase Integration

### 5.1 Authentication

- User sign-in with email/password
- User session management
- Password reset functionality
- Role-based access control

### 5.2 Firestore Database

The dashboard uses the following collections:

- **adminUsers**: Dashboard users with roles
- **vendors**: Vendor profiles and approval status
- **products**: Product details and approval status
- **orders**: Order information and tracking

### 5.3 Firebase Storage

Used for storing:

- Vendor logos and verification documents
- Product images
- Other associated files

## 6. Functionality and Workflows

### 6.1 Vendor Approval Process

1. Vendor registers via the vendor app
2. Admin receives notification of pending vendor
3. Admin reviews vendor details
4. Admin approves or rejects the vendor
5. Vendor receives notification of decision

### 6.2 Product Approval Process

1. Vendor uploads products via the vendor app
2. Admin receives notification of pending products
3. Admin reviews product details and images
4. Admin approves or rejects the product
5. Admin can add the product to the client-facing catalog

### 6.3 Order Management Process

1. Client places order via the client app
2. Admin receives notification of new order
3. Admin assigns order to appropriate vendor
4. Admin tracks order fulfillment
5. Admin marks order as complete when delivered

## 7. Theming and Responsiveness

### 7.1 Theme Support

- Light/dark mode toggle
- Persistent theme preference
- SpareWo brand colors integration

### 7.2 Responsive Design

- Mobile-first approach
- Collapsible sidebar for smaller screens
- Responsive tables and cards
- Touch-friendly interface elements

## 8. Deployment Configuration

### 8.1 Vercel Deployment

- Automatic deployments from GitHub
- Environment variable configuration
- Custom domain setup
- Preview deployments for branches

### 8.2 Required Environment Variables

- Firebase configuration variables
- Application settings

## 9. Security Considerations

- Route protection for authenticated sections
- Role-based access control
- Firebase security rules for data protection
- Encrypted communication via HTTPS

## 10. Future Extensions

The modular architecture allows for easy extension with:

- Advanced analytics dashboard
- Bulk operations for products/vendors
- Enhanced communication tools
- Integrated reporting system
- API integrations with other services