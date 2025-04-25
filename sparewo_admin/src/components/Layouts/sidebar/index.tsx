'use client';
import React, { useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { NAV_DATA } from './data';
import MenuItem from './menu-item';
import { useSidebarContext } from './sidebar-context';
import { ChevronLeft, ChevronRight, X } from 'lucide-react';

const Sidebar = () => {
  const { sidebarOpen, isCollapsed, toggleSidebar, toggleCollapse, closeSidebar, isMobile } = useSidebarContext();
  const pathname = usePathname();

  // Close sidebar when route changes (mobile)
  useEffect(() => {
    if (isMobile && sidebarOpen) {
      closeSidebar();
    }
  }, [pathname, isMobile, sidebarOpen, closeSidebar]);

  return (
    <>
      {/* Mobile Overlay */}
      {isMobile && sidebarOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black bg-opacity-50 transition-opacity"
          onClick={closeSidebar}
          aria-hidden="true"
        ></div>
      )}
      
      {/* Sidebar */}
      <aside 
        className={`fixed left-0 top-0 z-50 flex h-screen flex-col overflow-hidden bg-white transition-all duration-300 dark:bg-boxdark lg:static
          ${sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
          ${isCollapsed ? 'w-20' : 'w-72'}`}
      >
        <div className="flex h-20 items-center justify-between gap-2 px-6 py-5.5 lg:py-6.5">
          <Link href="/" className="flex items-center gap-2.5">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary">
              <span className="text-xl font-bold text-white">SW</span>
            </div>
            <span className={`text-xl font-bold text-black dark:text-white transition-opacity duration-200 ${isCollapsed ? 'opacity-0 invisible' : 'opacity-100 visible'}`}>
              SpareWo
            </span>
          </Link>

          {!isMobile && (
            <button 
              onClick={toggleCollapse}
              className="flex h-8 w-8 items-center justify-center rounded-full text-slate-500 transition-colors hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800"
              aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
            >
              {isCollapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
            </button>
          )}
          
          {isMobile && (
            <button 
              onClick={closeSidebar}
              className="flex h-8 w-8 items-center justify-center rounded-full text-slate-500 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800"
              aria-label="Close sidebar"
            >
              <X size={18} />
            </button>
          )}
        </div>

        <div className="flex flex-col overflow-y-auto px-4 py-5.5 scrollbar-thin scrollbar-track-slate-100 scrollbar-thumb-slate-300 dark:scrollbar-track-slate-700 dark:scrollbar-thumb-slate-500">
          {NAV_DATA.map((section, index) => (
            <div key={index} className="mb-6">
              <h3 className={`mb-3 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 transition-opacity duration-200 ${isCollapsed ? 'opacity-0 h-0 mb-0' : 'opacity-100'}`}>
                {section.label}
              </h3>

              <div className="space-y-1">
                {section.items.map((item, itemIndex) => (
                  <MenuItem 
                    key={itemIndex} 
                    item={item}
                    isCollapsed={isCollapsed}
                    pathname={pathname}
                  />
                ))}
              </div>
            </div>
          ))}
        </div>
      </aside>
    </>
  );
};

export default Sidebar;