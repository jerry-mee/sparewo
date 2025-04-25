'use client';
import React, { useEffect, useRef, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useClickOutside } from '@/hooks/use-click-outside';
import { useAuth } from '@/hooks/useAuth';
import { Settings, LogOut, User } from 'lucide-react';

export const UserMenu = () => {
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const { user, logout } = useAuth();
  const router = useRouter();

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

  const handleLogout = async () => {
    try {
      setIsLoading(true);
      await logout();
      router.push('/auth/sign-in');
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // Get user initials for avatar fallback
  const getUserInitials = () => {
    if (!user) return 'U';
    
    if (user.displayName) {
      return user.displayName.split(' ')
        .map(name => name[0])
        .join('')
        .toUpperCase();
    }
    
    return user.email?.[0].toUpperCase() || 'U';
  };

  return (
    <div className="relative">
      <button
        ref={trigger}
        onClick={() => setDropdownOpen(!dropdownOpen)}
        className="flex items-center gap-3"
      >
        <span className="hidden text-right lg:block">
          <span className="block text-sm font-medium text-slate-700 dark:text-slate-300">
            {user?.displayName || user?.email || 'Admin User'}
          </span>
          <span className="block text-xs text-slate-500">{user?.email || 'admin@sparewo.ug'}</span>
        </span>

        <div className="flex h-10 w-10 items-center justify-center overflow-hidden rounded-full border border-slate-200 bg-slate-100 dark:border-slate-700 dark:bg-slate-800">
          {user?.photoURL ? (
            <Image
              src={user.photoURL}
              alt={user.displayName || 'User'}
              width={40}
              height={40}
              className="h-full w-full object-cover"
            />
          ) : (
            <span className="text-sm font-semibold text-slate-700 dark:text-slate-300">
              {getUserInitials()}
            </span>
          )}
        </div>
      </button>

      <div
        ref={dropdown}
        className={`absolute right-0 mt-3 w-60 overflow-hidden rounded-lg border border-slate-200 bg-white shadow-lg dark:border-slate-700 dark:bg-boxdark ${
          dropdownOpen ? 'block' : 'hidden'
        }`}
      >
        <div className="border-b border-slate-200 px-4 py-3 dark:border-slate-700">
          <span className="block text-sm font-semibold text-slate-700 dark:text-slate-300">
            {user?.displayName || 'Admin User'}
          </span>
          <span className="block text-xs text-slate-500">{user?.email || 'admin@sparewo.ug'}</span>
        </div>

        <ul className="space-y-0.5 py-2">
          <li>
            <Link
              href="/profile"
              className="flex items-center gap-3 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800"
              onClick={() => setDropdownOpen(false)}
            >
              <User size={16} className="text-slate-500" />
              My Profile
            </Link>
          </li>
          <li>
            <Link
              href="/settings"
              className="flex items-center gap-3 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800"
              onClick={() => setDropdownOpen(false)}
            >
              <Settings size={16} className="text-slate-500" />
              Settings
            </Link>
          </li>
        </ul>

        <div className="border-t border-slate-200 pt-2 dark:border-slate-700">
          <button
            onClick={handleLogout}
            disabled={isLoading}
            className="flex w-full items-center gap-3 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800"
          >
            <LogOut size={16} className="text-slate-500" />
            {isLoading ? 'Signing out...' : 'Sign Out'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default UserMenu;