SpareWo 🚗

Overview
SpareWo is a platform designed to simplify the process of purchasing and installing car spare parts and booking garage services. It connects clients, vendors, and administrators through an integrated ecosystem of mobile apps and a web platform.

Core Features
Client App (iOS & Android):

A user-friendly app for customers to browse a catalog of car spare parts, make purchases, and book garage services.
Track orders and receive real-time updates.
Secure payment options, including online and Cash on Delivery (COD).
Vendor App (Android & Web):

Vendors can sign up and create accounts visible only to administrators.
Upload spare parts with details like pictures, specifications, year of manufacture, and compatible car models.
Inventory management and pending approval workflow for parts.
Super Admin Dashboard & CMS (Web):

Manage app content, including catalogs, vendor accounts, and client orders.
Vet vendor uploads for approval.
Oversee orders, inventory, and payments.
Full control over the platform's operations.
Web App:

Both vendors and clients can log in to manage their activities without needing to download mobile apps.

Technology Stack

Frontend: Flutter (Client & Vendor Apps)

Backend: Firebase

Database: PostgreSQL or Firebase Firestore

Hosting: Firebase

Payment Integration: Flutterwave

Project Structure

Client App: client-app/
The mobile app for customers to browse and purchase spare parts or book garage services.

Vendor App: vendor-app/
The Android app for vendors to manage their inventory and upload spare parts.

Admin Dashboard: admin-dashboard/
A web-based super admin panel to oversee all operations, including content management, order tracking, and vendor approvals.

Web App: web-app/
A unified platform for clients and vendors to access their accounts without downloading the mobile apps.

How It Works
Client Journey:

Browse spare parts or book services.
Place an order and receive real-time updates.
Pay securely online or opt for COD.
Vendor Journey:

Sign up and create a vendor account.
Upload spare parts with specifications, which are vetted and approved by admins.
Manage inventory and get notified of matched client orders.
Admin Journey:

Vet and approve vendor uploads.
Oversee client orders and vendor interactions.
Manage payments, inventory, and app content.
