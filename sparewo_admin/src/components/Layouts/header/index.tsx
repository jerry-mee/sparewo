'use client';
import React from 'react';
import { Menu } from 'lucide-react';
import DarkModeSwitcher from './DarkModeSwitcher';
import UserMenu from './UserMenu';
import { useSidebarContext } from '../sidebar/sidebar-context';
import NotificationDropdown from './notification';

const Header: React.FC = () => {
  const { toggleSidebar, isMobile } = useSidebarContext();

  return (
    <header className="sticky top-0 z-40 flex w-full bg-white drop-shadow-sm dark:bg-boxdark dark:drop-shadow-none">
      <div className="flex flex-grow items-center justify-between px-4 py-4 shadow-sm md:px-6 2xl:px-8">
        <div className="flex items-center gap-2">
          {/* Mobile Menu Toggle */}
          {isMobile && (
            <button
              onClick={toggleSidebar}
              aria-label="Toggle Menu"
              className="flex rounded-lg p-1.5 text-slate-500 transition-colors hover:bg-gray-100 dark:text-slate-400 dark:hover:bg-boxdark-2"
            >
              <Menu size={24} />
            </button>
          )}
          
          <div className="hidden sm:block">
            {/* Optional: Add search or breadcrumb here */}
          </div>
        </div>

        <div className="flex items-center gap-3 lg:gap-6">
          <div className="flex items-center gap-2">
            {/* Dark Mode Toggler */}
            <DarkModeSwitcher />
            
            {/* Notifications */}
            <NotificationDropdown />
          </div>

          {/* User Menu */}
          <UserMenu />
        </div>
      </div>
    </header>
  );
};

export default Header;