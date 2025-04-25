'use client';
import React from 'react';
import Link from 'next/link';

interface MenuItem {
  title: string;
  path?: string; // Made optional to match SidebarItem
  icon: React.ReactNode;
  badge?: string;
}

interface MenuItemProps {
  item: MenuItem;
  isCollapsed: boolean;
  pathname: string;
}

const MenuItem: React.FC<MenuItemProps> = ({ item, isCollapsed, pathname }) => {
  // Check if path exists, if not use # as fallback
  const itemPath = item.path || '#';
  const isActive = pathname === itemPath || pathname.startsWith(`${itemPath}/`);

  return (
    <Link
      href={itemPath}
      className={`group flex items-center gap-2.5 rounded-lg px-4 py-2.5 font-medium transition-colors ${
        isActive
          ? 'bg-primary text-white dark:bg-primary'
          : 'text-slate-700 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800'
      }`}
    >
      <span className={`text-xl ${isActive ? 'text-white' : 'text-slate-500 dark:text-slate-400 group-hover:text-slate-700 dark:group-hover:text-white'}`}>
        {item.icon}
      </span>
      
      <span className={`whitespace-nowrap transition-all duration-200 ${
        isCollapsed ? 'opacity-0 invisible w-0' : 'opacity-100 visible w-auto'
      }`}>
        {item.title}
      </span>
      
      {item.badge && !isCollapsed && (
        <span className={`ml-auto flex h-5 min-w-[20px] items-center justify-center rounded-full ${
          isActive 
            ? 'bg-white bg-opacity-20 text-white' 
            : 'bg-primary bg-opacity-10 text-primary'
        } px-1 text-xs font-medium`}>
          {item.badge}
        </span>
      )}
      
      {/* Small dot indicator for badges when collapsed */}
      {item.badge && isCollapsed && (
        <span className="absolute right-3 top-3 h-2 w-2 rounded-full bg-primary"></span>
      )}
    </Link>
  );
};

export default MenuItem;
