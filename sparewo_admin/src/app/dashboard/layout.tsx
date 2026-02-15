// src/app/dashboard/layout.tsx
"use client";

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { useTheme } from 'next-themes';
import {
  LayoutDashboard,
  Users,
  Store,
  Wrench,
  Package,
  ShoppingCart,
  Settings,
  Menu,
  X,
  Sun,
  Moon,
  LogOut
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { NotificationDropdown } from '@/components/ui/notification-dropdown';
import { useAuth } from '@/lib/context/auth-context';
import { logOut } from '@/lib/firebase/auth';
import { toast } from 'sonner';
import { getInitials } from '@/lib/utils';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isMobile, setIsMobile] = useState(false);
  const pathname = usePathname();
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const { user, adminData } = useAuth();

  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 1024);
      if (window.innerWidth < 1024) {
        setIsSidebarOpen(false);
      } else {
        setIsSidebarOpen(true);
      }
    };

    checkMobile();
    window.addEventListener('resize', checkMobile);
    setMounted(true);

    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const toggleSidebar = () => {
    setIsSidebarOpen(!isSidebarOpen);
  };

  const toggleTheme = () => {
    setTheme(theme === 'dark' ? 'light' : 'dark');
  };

  const handleLogout = async () => {
    try {
      await logOut();
      toast.success('Logged out successfully');
    } catch {
      toast.error('Failed to log out');
    }
  };

  // UPDATED NAVIGATION ITEMS
  const navItems = [
    {
      title: 'Dashboard',
      href: '/dashboard',
      icon: <LayoutDashboard size={20} />,
      active: pathname === '/dashboard',
    },
    {
      title: 'Clients',
      href: '/dashboard/clients',
      icon: <Users size={20} />,
      active: pathname.startsWith('/dashboard/clients'),
    },
    {
      title: 'AutoHub',
      href: '/dashboard/autohub',
      icon: <Wrench size={20} />,
      active: pathname.startsWith('/dashboard/autohub'),
    },
    {
      title: 'Vendors',
      href: '/dashboard/vendors',
      icon: <Store size={20} />,
      active: pathname.startsWith('/dashboard/vendors'),
    },
    {
      title: 'Products',
      href: '/dashboard/products',
      icon: <Package size={20} />,
      active: pathname.startsWith('/dashboard/products'),
    },
    {
      title: 'Orders',
      href: '/dashboard/orders',
      icon: <ShoppingCart size={20} />,
      active: pathname.startsWith('/dashboard/orders'),
    },
    {
      title: 'Settings',
      href: '/dashboard/settings',
      icon: <Settings size={20} />,
      active: pathname.startsWith('/dashboard/settings'),
    },
  ];

  const getCurrentPageTitle = () => {
    if (pathname === '/dashboard') return 'Dashboard';
    const parts = pathname.split('/');
    const lastPart = parts[parts.length - 1];
    
    if (lastPart === 'dashboard') return 'Dashboard';
    
    if (parts.includes('autohub')) return 'AutoHub Manager';
    if (parts.includes('clients')) return 'Client Management';
    if (parts.includes('vendors')) return 'Vendor Management';
    if (parts.includes('products')) return 'Product Catalog';
    if (parts.includes('orders')) return 'Orders';
    if (parts.includes('settings')) return 'Settings';

    return lastPart.charAt(0).toUpperCase() + lastPart.slice(1);
  };

  const sidebarOverlay = isMobile && isSidebarOpen ? (
    <div
      className="fixed inset-0 bg-black/50 z-20 lg:hidden"
      onClick={() => setIsSidebarOpen(false)}
    />
  ) : null;

  return (
    <div className={`flex min-h-screen ${mounted && theme === 'dark' ? 'bg-gray-900 text-white' : 'bg-gray-100'}`}>
      {sidebarOverlay}

      <div
        className={`${
          isSidebarOpen ? "w-64" : "w-0 lg:w-20"
        } ${mounted && theme === 'dark' ? 'bg-gray-800' : 'bg-indigo-900'} fixed inset-y-0 left-0 z-30 transition-all duration-300 ease-in-out flex flex-col overflow-hidden`}
      >
        <div className="flex items-center justify-between h-16 px-4 border-b border-opacity-20 border-gray-600">
          <div className="flex items-center space-x-2">
            {isSidebarOpen && (
              <div className="text-lg font-semibold text-white flex items-center">
                <Image
                  src="/images/logo.png"
                  alt="SpareWo Logo"
                  width={32}
                  height={32}
                  className="mr-2"
                  style={{ width: 'auto', height: 'auto' }}
                />
                SpareWo Admin
              </div>
            )}
          </div>
          <button onClick={toggleSidebar} className="text-white lg:block hidden">
            {isSidebarOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto py-4">
          <div className="px-4 space-y-1">
            {navItems.map((item) => (
              <Link key={item.title} href={item.href}>
                <div
                  className={`flex items-center py-3 px-4 rounded-md cursor-pointer transition-colors ${
                    item.active
                      ? "bg-orange-500 text-white"
                      : "text-gray-300 hover:bg-orange-500 hover:bg-opacity-30 hover:text-white"
                  } ${!isSidebarOpen && 'justify-center'}`}
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

        <div className="p-4 border-t border-gray-600 border-opacity-20">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <div className="w-8 h-8 rounded-full bg-orange-500 flex items-center justify-center text-white font-medium">
                {user ? getInitials(user.displayName || user.email || 'A') : 'A'}
              </div>
            </div>
            {isSidebarOpen && (
              <div className="ml-3 overflow-hidden">
                <p className="text-sm font-medium text-white truncate">
                  {user?.displayName || 'Admin User'}
                </p>
                <p className="text-xs text-gray-300 truncate">
                  {adminData?.role || 'Admin'}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>

      <div
        className={`flex-1 ${
          isSidebarOpen ? "lg:ml-64" : "lg:ml-20"
        } transition-all duration-300 ease-in-out`}
      >
        <header
          className={`fixed right-0 left-0 lg:left-auto ${
            isSidebarOpen ? "lg:left-64" : "lg:left-20"
          } h-16 z-20 flex items-center justify-between px-4 border-b ${
            mounted && theme === 'dark' ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200'
          } transition-all duration-300`}
        >
          <div className="flex items-center">
            <button
              onClick={toggleSidebar}
              className="text-gray-500 dark:text-gray-300 mr-4 lg:hidden"
            >
              <Menu size={20} />
            </button>
            <h1 className="text-xl font-semibold truncate">
              {getCurrentPageTitle()}
            </h1>
          </div>

          <div className="flex items-center space-x-4">
            <button
              onClick={toggleTheme}
              className={`p-1 rounded-full ${theme === 'dark' ? 'text-gray-300 hover:text-white' : 'text-gray-500 hover:text-gray-700'}`}
            >
              {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
            </button>

            <NotificationDropdown />

            <Button
              variant="ghost"
              size="icon"
              onClick={handleLogout}
              aria-label="Log out"
            >
              <LogOut size={20} />
            </Button>
          </div>
        </header>

        <main className="pt-24 px-4 md:px-6 pb-6 min-h-screen">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}