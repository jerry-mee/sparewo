'use client';

import React, { useState, useEffect } from 'react';
import Breadcrumb from '@/components/Breadcrumbs/Breadcrumb';
import userService, { UserRole, UserStatus } from '@/services/user.service';
import { Eye, UserPlus, Mail, Ban, CheckCircle, Shield } from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';

interface User {
  id: string;
  email: string;
  displayName?: string;
  phoneNumber?: string;
  role: UserRole;
  status: UserStatus;
  photoURL?: string;
  createdAt?: any;
  lastLoginAt?: any;
  [key: string]: any;
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [roleFilter, setRoleFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [newUser, setNewUser] = useState({
    email: '',
    password: '',
    displayName: '',
    role: UserRole.ADMIN
  });
  const [resetModal, setResetModal] = useState<{show: boolean, email: string}>({show: false, email: ''});
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        let fetchedUsers: User[];
        
        if (roleFilter !== 'all') {
          // Fix: Type assertion to ensure returned data matches User interface
          const result = await userService.getUsersByRole(roleFilter as UserRole);
          fetchedUsers = result as User[];
        } else {
          // Fix: Type assertion to ensure returned data matches User interface
          const result = await userService.getAllUsers();
          fetchedUsers = result as User[];
        }
        
        setUsers(fetchedUsers);
        setLoading(false);
      } catch (error) {
        console.error('Error fetching users:', error);
        setLoading(false);
      }
    };
    
    fetchUsers();
  }, [roleFilter]);

  const filteredUsers = statusFilter === 'all' 
    ? users 
    : users.filter(user => user.status === statusFilter);

  const handleStatusChange = async (id: string, newStatus: UserStatus) => {
    try {
      setStatusUpdating(id);
      await userService.updateUserStatus(id, newStatus);
      
      // Update the local state to reflect the change
      setUsers(prevUsers => 
        prevUsers.map(user => 
          user.id === id ? { ...user, status: newStatus } : user
        )
      );
      
      setStatusUpdating(null);
    } catch (error) {
      console.error('Error updating user status:', error);
      setStatusUpdating(null);
    }
  };

  const handleRoleChange = async (id: string, newRole: UserRole) => {
    try {
      setStatusUpdating(id);
      await userService.updateUser(id, { role: newRole });
      
      // Update the local state to reflect the change
      setUsers(prevUsers => 
        prevUsers.map(user => 
          user.id === id ? { ...user, role: newRole } : user
        )
      );
      
      setStatusUpdating(null);
    } catch (error) {
      console.error('Error updating user role:', error);
      setStatusUpdating(null);
    }
  };

  const handleAddUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    
    try {
      await userService.createAdminUser(
        newUser.email,
        newUser.password,
        {
          displayName: newUser.displayName,
          role: newUser.role,
          status: UserStatus.ACTIVE
        }
      );
      
      // Refresh the user list
      // Fix: Type assertion to ensure returned data matches User interface
      const result = await userService.getAllUsers();
      setUsers(result as User[]);
      
      // Reset form and close modal
      setNewUser({
        email: '',
        password: '',
        displayName: '',
        role: UserRole.ADMIN
      });
      setShowAddModal(false);
    } catch (error: any) {
      setError(error.message || 'Failed to create user');
    }
  };

  const sendPasswordReset = async (email: string) => {
    try {
      await userService.sendPasswordReset(email);
      alert(`Password reset email sent to ${email}`);
      setResetModal({show: false, email: ''});
    } catch (error: any) {
      alert(`Error: ${error.message}`);
    }
  };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const getStatusClass = (status: string) => {
    switch (status) {
      case UserStatus.ACTIVE: return 'badge badge-success';
      case UserStatus.INACTIVE: return 'badge badge-warning';
      case UserStatus.SUSPENDED: return 'badge badge-danger';
      default: return 'badge';
    }
  };

  const getRoleBadgeClass = (role: string) => {
    switch (role) {
      case UserRole.ADMIN: return 'badge badge-info';
      case UserRole.VENDOR: return 'badge badge-warning';
      case UserRole.CUSTOMER: return 'badge badge-success';
      default: return 'badge';
    }
  };

  return (
    <>
      <Breadcrumb pageName="Users" />

      <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h2 className="text-title-md2 font-semibold">
          User Management
        </h2>
        <div className="flex items-center gap-3">
          <select
            className="form-input py-2"
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
          >
            <option value="all">All Roles</option>
            <option value={UserRole.ADMIN}>Admins</option>
            <option value={UserRole.VENDOR}>Vendors</option>
            <option value={UserRole.CUSTOMER}>Customers</option>
          </select>
          
          <select
            className="form-input py-2"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="all">All Statuses</option>
            <option value={UserStatus.ACTIVE}>Active</option>
            <option value={UserStatus.INACTIVE}>Inactive</option>
            <option value={UserStatus.SUSPENDED}>Suspended</option>
          </select>
          
          <button 
            className="btn btn-primary"
            onClick={() => setShowAddModal(true)}
          >
            <UserPlus size={18} className="mr-2" />
            Add User
          </button>
        </div>
      </div>

      <div className="card">
        <div className="overflow-x-auto">
          <table className="table">
            <thead>
              <tr>
                <th className="min-w-[250px]">User Details</th>
                <th>Role</th>
                <th>Status</th>
                <th>Created</th>
                <th>Last Login</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} className="text-center p-4">
                    <div className="flex justify-center">
                      <div className="h-6 w-6 spin"></div>
                    </div>
                  </td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center p-4">
                    No users found
                  </td>
                </tr>
              ) : (
                filteredUsers.map((user) => (
                  <tr key={user.id}>
                    <td>
                      <div className="flex items-center gap-3">
                        <div className="h-10 w-10 overflow-hidden rounded-full">
                          {user.photoURL ? (
                            <Image 
                              src={user.photoURL} 
                              alt={user.displayName || user.email} 
                              width={40} 
                              height={40}
                              className="h-full w-full object-cover"
                            />
                          ) : (
                            <div className="flex h-full w-full items-center justify-center bg-primary text-white">
                              {(user.displayName || user.email).charAt(0).toUpperCase()}
                            </div>
                          )}
                        </div>
                        <div>
                          <h5 className="font-medium">{user.displayName || 'No Name'}</h5>
                          <p className="text-sm">{user.email}</p>
                          {user.phoneNumber && <p className="text-sm">{user.phoneNumber}</p>}
                        </div>
                      </div>
                    </td>
                    <td>
                      <span className={getRoleBadgeClass(user.role)}>
                        {user.role === UserRole.ADMIN && <Shield size={14} className="mr-1" />}
                        {user.role}
                      </span>
                    </td>
                    <td>
                      <span className={getStatusClass(user.status)}>
                        {user.status}
                      </span>
                    </td>
                    <td>{formatDate(user.createdAt)}</td>
                    <td>{formatDate(user.lastLoginAt) || 'Never'}</td>
                    <td>
                      <div className="flex items-center space-x-2">
                        {statusUpdating === user.id ? (
                          <div className="h-4 w-4 spin"></div>
                        ) : (
                          <>
                            <select 
                              className="form-input py-1 px-2 text-sm"
                              value={user.status}
                              onChange={(e) => handleStatusChange(user.id, e.target.value as UserStatus)}
                              title="Change status"
                            >
                              <option value={UserStatus.ACTIVE}>Active</option>
                              <option value={UserStatus.INACTIVE}>Inactive</option>
                              <option value={UserStatus.SUSPENDED}>Suspended</option>
                            </select>
                            
                            <select 
                              className="form-input py-1 px-2 text-sm"
                              value={user.role}
                              onChange={(e) => handleRoleChange(user.id, e.target.value as UserRole)}
                              title="Change role"
                            >
                              <option value={UserRole.ADMIN}>Admin</option>
                              <option value={UserRole.VENDOR}>Vendor</option>
                              <option value={UserRole.CUSTOMER}>Customer</option>
                            </select>
                            
                            <button 
                              className="p-1 text-primary"
                              onClick={() => setResetModal({show: true, email: user.email})}
                              title="Reset password"
                            >
                              <Mail size={18} />
                            </button>
                            
                            <Link href={`/users/${user.id}`}>
                              <Eye size={18} className="p-1 hover:text-primary" />
                            </Link>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add User Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="card w-full max-w-md">
            <h3 className="text-lg font-semibold mb-4">Add New User</h3>
            
            {error && (
              <div className="mb-4 p-3 bg-danger bg-opacity-10 text-danger rounded-md">
                {error}
              </div>
            )}
            
            <form onSubmit={handleAddUser}>
              <div className="mb-4">
                <label className="form-label" htmlFor="email">Email</label>
                <input
                  id="email"
                  type="email"
                  className="form-input"
                  value={newUser.email}
                  onChange={(e) => setNewUser({...newUser, email: e.target.value})}
                  required
                />
              </div>
              
              <div className="mb-4">
                <label className="form-label" htmlFor="password">Password</label>
                <input
                  id="password"
                  type="password"
                  className="form-input"
                  value={newUser.password}
                  onChange={(e) => setNewUser({...newUser, password: e.target.value})}
                  required
                  minLength={6}
                />
              </div>
              
              <div className="mb-4">
                <label className="form-label" htmlFor="displayName">Display Name</label>
                <input
                  id="displayName"
                  type="text"
                  className="form-input"
                  value={newUser.displayName}
                  onChange={(e) => setNewUser({...newUser, displayName: e.target.value})}
                />
              </div>
              
              <div className="mb-4">
                <label className="form-label" htmlFor="role">Role</label>
                <select
                  id="role"
                  className="form-input"
                  value={newUser.role}
                  onChange={(e) => setNewUser({...newUser, role: e.target.value as UserRole})}
                >
                  <option value={UserRole.ADMIN}>Admin</option>
                  <option value={UserRole.VENDOR}>Vendor</option>
                  <option value={UserRole.CUSTOMER}>Customer</option>
                </select>
              </div>
              
              <div className="flex justify-end space-x-2">
                <button 
                  type="button"
                  className="btn btn-outline"
                  onClick={() => setShowAddModal(false)}
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="btn btn-primary"
                >
                  Create User
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Password Reset Modal */}
      {resetModal.show && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="card w-full max-w-md">
            <h3 className="text-lg font-semibold mb-4">Send Password Reset Email</h3>
            <p className="mb-4">
              Send a password reset email to <strong>{resetModal.email}</strong>?
            </p>
            <div className="flex justify-end space-x-2">
              <button 
                className="btn btn-outline"
                onClick={() => setResetModal({show: false, email: ''})}
              >
                Cancel
              </button>
              <button 
                className="btn btn-primary"
                onClick={() => sendPasswordReset(resetModal.email)}
              >
                Send Reset Email
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}