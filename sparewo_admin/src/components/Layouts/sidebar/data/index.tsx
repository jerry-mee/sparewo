import React from 'react';
import {
  BarChart3,
  ShoppingBag,
  Users,
  Package,
  Settings,
  Home,
  Activity,
  Bell,
  Database,
  Car
} from 'lucide-react';

export interface SidebarItem {
  title: string;
  icon: React.ReactNode;
  path?: string;
  url?: string;
  items?: {
    title: string;
    path?: string;
    url?: string;
  }[];
}

export const NAV_DATA: { label: string; items: SidebarItem[] }[] = [
  {
    label: "Dashboard",
    items: [
      {
        title: "Overview",
        icon: <Home size={18} />,
        path: "/",
      },
    ],
  },
  {
    label: "Management",
    items: [
      {
        title: "Vendors",
        icon: <Users size={18} />,
        items: [
          {
            title: "All Vendors",
            path: "/vendors",
          },
          {
            title: "Pending Approval",
            path: "/vendors/pending",
          },
          {
            title: "Add New Vendor",
            path: "/vendors/new",
          }
        ],
      },
      {
        title: "Catalogs",
        icon: <Database size={18} />,
        path: "/catalogs",
      },
      {
        title: "Products",
        icon: <Package size={18} />,
        items: [
          {
            title: "All Products",
            path: "/products",
          },
          {
            title: "Pending Review",
            path: "/products/pending",
          },
          {
            title: "Add New Product",
            path: "/products/new",
          }
        ],
      },
      {
        title: "Orders",
        icon: <ShoppingBag size={18} />,
        items: [
          {
            title: "All Orders",
            path: "/orders",
          },
          {
            title: "Active Orders",
            path: "/orders/active",
          },
          {
            title: "Completed Orders",
            path: "/orders/completed",
          },
        ],
      },
      {
        title: "AutoHub Requests",
        icon: <Car size={18} />,
        path: "/autohub",
      },
    ],
  },
  {
    label: "Reports",
    items: [
      {
        title: "Analytics",
        icon: <BarChart3 size={18} />,
        path: "/analytics",
      },
      {
        title: "Notifications",
        icon: <Bell size={18} />,
        path: "/notifications",
      },
    ],
  },
  {
    label: "System",
    items: [
      {
        title: "Settings",
        icon: <Settings size={18} />,
        path: "/settings",
      },
      {
        title: "Activity Log",
        icon: <Activity size={18} />,
        path: "/activity",
      },
    ],
  },
];