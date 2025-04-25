'use client';
import React, { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useClickOutside } from '@/hooks/use-click-outside';
import { Bell, Package, Users, ShoppingBag } from 'lucide-react';

export const Notification = () => {
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [hasUnread, setHasUnread] = useState(true);
  const trigger = useRef<HTMLButtonElement>(null);
  const dropdown = useRef<HTMLDivElement>(null);

  // Close on click outside
  useClickOutside([dropdown, trigger], () => setDropdownOpen(false));

  // Close if the Esc key is pressed
  useEffect(() => {
    const keyHandler = ({ keyCode }: KeyboardEvent) => {
      if (!dropdownOpen || keyCode !== 27) return;
      setDropdownOpen(false);
    };
    document.addEventListener('keydown', keyHandler);
    return () => document.removeEventListener('keydown', keyHandler);
  });

  // Sample notification data
  const notifications = [
    {
      id: '1',
      title: 'New Product Submission',
      message: 'A vendor submitted a new product for review',
      time: '3 min ago',
      link: '/products/pending',
      unread: true,
      icon: <Package size={16} />,
      iconBg: 'bg-blue-100 text-blue-500 dark:bg-blue-900/20'
    },
    {
      id: '2',
      title: 'New Vendor Registration',
      message: 'A new vendor has registered and awaits approval',
      time: '5 hrs ago',
      link: '/vendors/pending',
      unread: true,
      icon: <Users size={16} />,
      iconBg: 'bg-orange-100 text-orange-500 dark:bg-orange-900/20'
    },
    {
      id: '3',
      title: 'Order Status Update',
      message: 'Order #4321 has been fulfilled by vendor',
      time: '1 day ago',
      link: '/orders',
      unread: false,
      icon: <ShoppingBag size={16} />,
      iconBg: 'bg-green-100 text-green-500 dark:bg-green-900/20'
    },
  ];

  return (
    <div className="relative">
      <button
        ref={trigger}
        onClick={() => {
          setDropdownOpen(!dropdownOpen);
          if (hasUnread) setHasUnread(false);
        }}
        className="notification-button"
      >
        {hasUnread && (
          <span className="notification-badge">2</span>
        )}
        <Bell size={20} className="text-gray-500 dark:text-gray-400" />
      </button>

      <div
        ref={dropdown}
        className={`absolute right-0 mt-3 w-80 overflow-hidden rounded-xl border border-gray-100 bg-white shadow-xl dark:border-gray-700 dark:bg-boxdark sm:w-96 transition-all duration-300 ${
          dropdownOpen ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-2 pointer-events-none'
        }`}
      >
        <div className="px-5 py-3 border-b border-gray-100 dark:border-gray-700 flex items-center justify-between">
          <h5 className="text-sm font-semibold text-gray-700 dark:text-gray-300">Notifications</h5>
          <Link href="/notifications" className="text-xs text-primary hover:underline">
            View all
          </Link>
        </div>

        <div className="max-h-96 overflow-y-auto custom-scrollbar">
          {notifications.length === 0 ? (
            <div className="px-5 py-8 text-center">
              <Bell size={36} className="mx-auto mb-3 text-gray-300" />
              <p className="text-sm text-gray-500">No notifications</p>
            </div>
          ) : (
            <div className="p-1">
              {notifications.map((notification) => (
                <Link
                  key={notification.id}
                  href={notification.link}
                  onClick={() => setDropdownOpen(false)}
                  className={`block m-2 p-3 rounded-xl transition-all duration-200 hover:bg-gray-50 dark:hover:bg-gray-800 ${
                    notification.unread ? 'bg-blue-50/40 dark:bg-blue-900/10' : ''
                  }`}
                >
                  <div className="flex gap-3">
                    <div className={`flex h-10 w-10 items-center justify-center rounded-full ${notification.iconBg}`}>
                      {notification.icon}
                    </div>
                    
                    <div className="flex-1">
                      <div className="flex items-center justify-between mb-1">
                        <h6 className="text-sm font-semibold text-gray-700 dark:text-gray-300">
                          {notification.title}
                        </h6>
                        {notification.unread && (
                          <span className="h-2 w-2 rounded-full bg-primary"></span>
                        )}
                      </div>
                      <p className="text-xs text-gray-600 dark:text-gray-400 mb-1">{notification.message}</p>
                      <p className="text-xs text-gray-500">{notification.time}</p>
                    </div>
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Notification;