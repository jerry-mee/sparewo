'use client';

import React, { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { Menu, Bell, Settings, LogOut, User } from 'lucide-react';
import { useRouter } from 'next/navigation';

// Define interfaces for menu items
interface DropdownItem {
  label: string;
  href?: string;
  onClick?: () => void;
  icon?: React.ReactNode;
}

const UserInfo = () => {
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const { user, logout } = useAuth();
  const router = useRouter();

  const handleLogout = async () => {
    try {
      await logout();
      router.push('/auth/sign-in');
    } catch (error) {
      console.error('Logout error:', error);
    }
  };

  // User dropdown menu items
  const userMenuItems: DropdownItem[] = [
    { label: 'Profile', href: '/profile', icon: <User size={16} /> },
    { label: 'Settings', href: '/settings', icon: <Settings size={16} /> },
    { label: 'Logout', onClick: handleLogout, icon: <LogOut size={16} /> }
  ];

  // Get user initials for avatar
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
      <div 
        className="header-user"
        onClick={() => setUserMenuOpen(!userMenuOpen)}
      >
        <div className="header-user-avatar">
          {getUserInitials()}
        </div>
        
        <div className="header-user-info">
          <div className="header-user-name">
            {user?.displayName || user?.email || 'Admin User'}
          </div>
          <div className="header-user-role">Administrator</div>
        </div>
      </div>
      
      {userMenuOpen && (
        <div className="dropdown-menu">
          {userMenuItems.map((item: DropdownItem, index: number) => (
            <div key={index} className="dropdown-item">
              {item.href ? (
                <a href={item.href} className="dropdown-link">
                  {item.icon}
                  <span>{item.label}</span>
                </a>
              ) : (
                <button onClick={item.onClick} className="dropdown-button">
                  {item.icon}
                  <span>{item.label}</span>
                </button>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default UserInfo;