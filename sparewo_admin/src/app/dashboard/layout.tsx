'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTheme } from 'next-themes';
import {
  LayoutDashboard,
  Users,
  Package,
  ShoppingCart,
  Settings,
  Menu,
  X,
  Bell,
  Sun,
  Moon
} from 'lucide-react';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const pathname = usePathname();
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  // Fix hydration issues by only rendering after mount
  useEffect(() => {
    setMounted(true);
  }, []);

  const toggleSidebar = () => {
    setIsSidebarOpen(!isSidebarOpen);
  };

  const toggleTheme = () => {
    setTheme(theme === 'dark' ? 'light' : 'dark');
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
      href: '/dashboard/vendors',
      icon: <Users size={20} />,
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
  
  return (
    <div className={`flex h-screen ${mounted && theme === 'dark' ? 'bg-gray-900 text-white' : 'bg-gray-100'}`}>
      {/* Sidebar */}
      <div
        className={`${
          isSidebarOpen ? "w-64" : "w-20"
        } ${mounted && theme === 'dark' ? 'bg-gray-800' : 'bg-indigo-900'} fixed inset-y-0 left-0 z-30 transition-all duration-300 ease-in-out flex flex-col`}
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
                  className={`flex items-center py-3 px-4 rounded-md cursor-pointer transition-colors ${
                    item.active
                      ? "bg-orange-500 text-white"
                      : "text-gray-300 hover:bg-orange-500 hover:bg-opacity-30 hover:text-white"
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
              <div className="w-8 h-8 rounded-full bg-orange-500 flex items-center justify-center text-white font-medium">
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
          } h-16 z-20 flex items-center justify-between px-4 border-b ${
            mounted && theme === 'dark' ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200'
          } transition-all duration-300`}
        >
          <div className="flex items-center">
            <h1 className="text-xl font-semibold mr-4">
              {pathname === '/dashboard' 
                ? 'Dashboard' 
                : pathname.split('/').pop() 
                  ? (pathname.split('/').pop() || '').charAt(0).toUpperCase() + (pathname.split('/').pop() || '').slice(1) 
                  : 'Dashboard'}
            </h1>
          </div>
          
          <div className="flex items-center space-x-4">
            <button 
              onClick={toggleTheme} 
              className={`p-1 rounded-full ${theme === 'dark' ? 'text-gray-300 hover:text-white' : 'text-gray-500 hover:text-gray-700'}`}
            >
              {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
            </button>
            <button 
              className={`p-1 rounded-full ${theme === 'dark' ? 'text-gray-300 hover:text-white' : 'text-gray-500 hover:text-gray-700'} relative`}
            >
              <Bell size={20} />
              <span className="absolute top-0 right-0 w-3 h-3 bg-red-500 rounded-full"></span>
            </button>
          </div>
        </header>
        
        {/* Main content */}
        <main className="pt-24 px-4 md:px-6 pb-6 min-h-screen">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}