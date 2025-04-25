'use client';
import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';

// Define the shape of the context data
interface SidebarContextProps {
  sidebarOpen: boolean; // Is the sidebar visible (mainly for mobile overlay)
  isCollapsed: boolean; // Is the sidebar collapsed (for desktop view)
  toggleSidebar: () => void; // Toggles visibility (mobile)
  toggleCollapse: () => void; // Toggles collapsed state (desktop)
  closeSidebar: () => void; // Closes sidebar (mobile)
  isMobile: boolean; // Flag indicating if the view is considered mobile
}

// Create the context with default values
const SidebarContext = createContext<SidebarContextProps>({
  sidebarOpen: false,
  isCollapsed: false,
  toggleSidebar: () => console.warn('SidebarContext: toggleSidebar called outside of Provider'),
  toggleCollapse: () => console.warn('SidebarContext: toggleCollapse called outside of Provider'),
  closeSidebar: () => console.warn('SidebarContext: closeSidebar called outside of Provider'),
  isMobile: false,
});

// Define the provider component
export const SidebarProvider = ({ children }: { children: React.ReactNode }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false); // Mobile overlay visibility
  const [isCollapsed, setIsCollapsed] = useState(false); // Desktop collapsed state
  const [isMobile, setIsMobile] = useState(false); // Is the current view mobile?

  // Check window size and set mobile/desktop states accordingly
  const checkDeviceSize = useCallback(() => {
    const mobileBreakpoint = 1024; // Tailwind's 'lg' breakpoint
    const currentIsMobile = window.innerWidth < mobileBreakpoint;
    setIsMobile(currentIsMobile);

    if (currentIsMobile) {
      // On mobile: Force close sidebar overlay, collapsed state is irrelevant
      setSidebarOpen(false);
      // setIsCollapsed(false); // Collapse state doesn't apply visually on mobile overlay
    } else {
      // On desktop: Close mobile overlay, restore collapsed state from localStorage
      setSidebarOpen(false); // Ensure mobile overlay is closed
      const storedCollapseState = localStorage.getItem('sidebarCollapsed') === 'true';
      setIsCollapsed(storedCollapseState);
    }
  }, []); // No dependencies needed as it reads directly from window/localStorage

  // Effect to run on mount and window resize
  useEffect(() => {
    // Initial check
    checkDeviceSize();

    // Add resize listener
    window.addEventListener('resize', checkDeviceSize);

    // Cleanup listener on unmount
    return () => window.removeEventListener('resize', checkDeviceSize);
  }, [checkDeviceSize]); // Depend on the memoized checkDeviceSize function

  // Toggle sidebar visibility (primarily for mobile)
  const toggleSidebar = useCallback(() => {
    setSidebarOpen(prev => !prev);
  }, []);

  // Toggle collapsed state (primarily for desktop) and persist to localStorage
  const toggleCollapse = useCallback(() => {
    setIsCollapsed(prev => {
      const newState = !prev;
      localStorage.setItem('sidebarCollapsed', String(newState));
      return newState;
    });
  }, []);

  // Close sidebar (e.g., after navigation on mobile)
  const closeSidebar = useCallback(() => {
    if (isMobile) { // Only close if in mobile view
        setSidebarOpen(false);
    }
  }, [isMobile]);

  // Provide the context value to children
  const value = {
    sidebarOpen,
    isCollapsed,
    toggleSidebar,
    toggleCollapse,
    closeSidebar,
    isMobile,
  };

  return (
    <SidebarContext.Provider value={value}>
      {children}
    </SidebarContext.Provider>
  );
};

// Custom hook to easily consume the sidebar context
export const useSidebarContext = () => {
  const context = useContext(SidebarContext);
  if (context === undefined) {
    throw new Error('useSidebarContext must be used within a SidebarProvider');
  }
  return context;
};
