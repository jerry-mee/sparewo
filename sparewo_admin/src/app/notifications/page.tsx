'use client';

import React, { useState, useEffect } from 'react';
import Breadcrumb from '@/components/Breadcrumbs/Breadcrumb';
import notificationService, { 
  Notification, 
  NotificationType, 
  NotificationTarget 
} from '@/services/notification.service';
import { Send, Bell, BellOff, MessageCircle, Check, Info, AlertTriangle, AlertCircle, Trash2 } from 'lucide-react';

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newNotification, setNewNotification] = useState<Partial<Notification>>({
    title: '',
    message: '',
    type: NotificationType.INFO,
    target: NotificationTarget.ALL,
    sendEmail: false
  });
  const [error, setError] = useState('');

  useEffect(() => {
    // In a real implementation, you would fetch notifications from the database
    // For now, we'll simulate it with some sample data
    const fetchData = async () => {
      try {
        setLoading(true);
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        const sampleNotifications: Notification[] = [
          {
            id: '1',
            title: 'System Maintenance',
            message: 'The system will be down for maintenance on Sunday from 2 AM to 4 AM UTC.',
            type: NotificationType.INFO,
            target: NotificationTarget.ALL,
            createdAt: new Date(Date.now() - 86400000 * 2), // 2 days ago
            read: true
          },
          {
            id: '2',
            title: 'New Vendor Registration',
            message: 'A new vendor has registered and requires approval.',
            type: NotificationType.WARNING,
            target: NotificationTarget.ADMIN,
            createdAt: new Date(Date.now() - 3600000 * 5), // 5 hours ago
            read: false
          },
          {
            id: '3',
            title: 'Product Approval Required',
            message: '15 new products require approval from admins.',
            type: NotificationType.WARNING,
            target: NotificationTarget.ADMIN,
            createdAt: new Date(Date.now() - 3600000 * 2), // 2 hours ago
            read: false
          },
          {
            id: '4',
            title: 'New Feature: Bulk Product Upload',
            message: 'Vendors can now upload multiple products at once using our new CSV upload feature.',
            type: NotificationType.SUCCESS,
            target: NotificationTarget.VENDORS,
            createdAt: new Date(Date.now() - 86400000), // 1 day ago
            read: true
          },
          {
            id: '5',
            title: 'Payment System Error',
            message: 'There was an issue with payment processing. The technical team has been notified.',
            type: NotificationType.ERROR,
            target: NotificationTarget.ALL,
            createdAt: new Date(Date.now() - 3600000 * 8), // 8 hours ago
            read: true
          }
        ];
        
        setNotifications(sampleNotifications);
        setLoading(false);
      } catch (error) {
        console.error('Error fetching notifications:', error);
        setLoading(false);
      }
    };
    
    fetchData();
  }, []);

  const handleCreateNotification = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    
    try {
      // Validate the form
      if (!newNotification.title || !newNotification.message) {
        setError('Title and message are required');
        return;
      }
      
      // In a real implementation, you would save to Firebase here
      // await notificationService.createNotification(newNotification as Notification);
      
      // Simulate successful creation
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Add the new notification to the list (for demo purposes)
      const created: Notification = {
        id: Math.random().toString(36).substring(2, 9), // Generate random ID
        title: newNotification.title!,
        message: newNotification.message!,
        type: newNotification.type!,
        target: newNotification.target!,
        sendEmail: newNotification.sendEmail,
        createdAt: new Date(),
        read: false
      };
      
      setNotifications([created, ...notifications]);
      
      // Reset the form and close the modal
      setNewNotification({
        title: '',
        message: '',
        type: NotificationType.INFO,
        target: NotificationTarget.ALL,
        sendEmail: false
      });
      setShowCreateModal(false);
      
      alert('Notification created successfully');
    } catch (error: any) {
      setError(error.message || 'Failed to create notification');
    }
  };

  const markAsRead = (id: string) => {
    setNotifications(notifications.map(notification => 
      notification.id === id ? { ...notification, read: true } : notification
    ));
  };

  const deleteNotification = (id: string) => {
    setNotifications(notifications.filter(notification => notification.id !== id));
  };

  const formatDate = (date: Date) => {
    return date.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getTypeIcon = (type: NotificationType) => {
    switch (type) {
      case NotificationType.INFO:
        return <Info size={20} className="text-info" />;
      case NotificationType.WARNING:
        return <AlertTriangle size={20} className="text-warning" />;
      case NotificationType.SUCCESS:
        return <Check size={20} className="text-success" />;
      case NotificationType.ERROR:
        return <AlertCircle size={20} className="text-danger" />;
      default:
        return <Bell size={20} />;
    }
  };

  const getTypeClass = (type: NotificationType) => {
    switch (type) {
      case NotificationType.INFO:
        return 'bg-info bg-opacity-10 text-info';
      case NotificationType.WARNING:
        return 'bg-warning bg-opacity-10 text-warning';
      case NotificationType.SUCCESS:
        return 'bg-success bg-opacity-10 text-success';
      case NotificationType.ERROR:
        return 'bg-danger bg-opacity-10 text-danger';
      default:
        return 'bg-gray-100 text-gray-600';
    }
  };

  return (
    <>
      <Breadcrumb pageName="Notifications" />
      
      <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h2 className="text-title-md2 font-semibold">
          Notification Center
        </h2>
        <div className="flex items-center gap-3">
          <button 
            className="btn btn-primary"
            onClick={() => setShowCreateModal(true)}
          >
            <Send size={18} className="mr-2" />
            Send Notification
          </button>
        </div>
      </div>
      
      <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
        <div className="card md:col-span-2">
          <h3 className="mb-4 text-lg font-semibold">Recent Notifications</h3>
          
          {loading ? (
            <div className="flex justify-center py-8">
              <div className="h-8 w-8 spin"></div>
            </div>
          ) : notifications.length === 0 ? (
            <div className="py-8 text-center">
              <BellOff size={36} className="mx-auto mb-4 text-gray-400" />
              <p className="text-lg">No notifications yet</p>
            </div>
          ) : (
            <div className="space-y-4">
              {notifications.map((notification) => (
                <div 
                  key={notification.id} 
                  className={`p-4 rounded-lg ${notification.read ? 'bg-gray-50' : getTypeClass(notification.type)}`}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-3">
                      <div className="mt-1">{getTypeIcon(notification.type)}</div>
                      <div>
                        <h4 className="font-medium">{notification.title}</h4>
                        <p className="mt-1 text-sm">{notification.message}</p>
                        <div className="mt-2 flex items-center text-xs text-gray-500">
                          <span>Sent: {formatDate(notification.createdAt as Date)}</span>
                          <span className="mx-2">•</span>
                          <span>To: {notification.target}</span>
                          {notification.sendEmail && (
                            <>
                              <span className="mx-2">•</span>
                              <span>Email sent</span>
                            </>
                          )}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      {!notification.read && (
                        <button 
                          className="p-1 hover:text-primary"
                          onClick={() => markAsRead(notification.id!)}
                          title="Mark as read"
                        >
                          <Check size={18} />
                        </button>
                      )}
                      <button 
                        className="p-1 hover:text-danger"
                        onClick={() => deleteNotification(notification.id!)}
                        title="Delete"
                      >
                        <Trash2 size={18} />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
        
        <div className="card">
          <h3 className="mb-4 text-lg font-semibold">Notification Stats</h3>
          
          <div className="space-y-4">
            <div>
              <h4 className="mb-2 font-medium">By Type</h4>
              <div className="grid grid-cols-2 gap-4">
                <div className="p-3 bg-info bg-opacity-10 rounded-lg">
                  <div className="flex justify-between items-center">
                    <Info size={18} className="text-info" />
                    <span className="text-xl font-bold">
                      {notifications.filter(n => n.type === NotificationType.INFO).length}
                    </span>
                  </div>
                  <p className="mt-1 text-sm">Info</p>
                </div>
                <div className="p-3 bg-warning bg-opacity-10 rounded-lg">
                  <div className="flex justify-between items-center">
                    <AlertTriangle size={18} className="text-warning" />
                    <span className="text-xl font-bold">
                      {notifications.filter(n => n.type === NotificationType.WARNING).length}
                    </span>
                  </div>
                  <p className="mt-1 text-sm">Warnings</p>
                </div>
                <div className="p-3 bg-success bg-opacity-10 rounded-lg">
                  <div className="flex justify-between items-center">
                    <Check size={18} className="text-success" />
                    <span className="text-xl font-bold">
                      {notifications.filter(n => n.type === NotificationType.SUCCESS).length}
                    </span>
                  </div>
                  <p className="mt-1 text-sm">Success</p>
                </div>
                <div className="p-3 bg-danger bg-opacity-10 rounded-lg">
                  <div className="flex justify-between items-center">
                    <AlertCircle size={18} className="text-danger" />
                    <span className="text-xl font-bold">
                      {notifications.filter(n => n.type === NotificationType.ERROR).length}
                    </span>
                  </div>
                  <p className="mt-1 text-sm">Errors</p>
                </div>
              </div>
            </div>
            
            <div>
              <h4 className="mb-2 font-medium">By Target</h4>
              <div className="grid grid-cols-2 gap-4">
                <div className="p-3 bg-gray-100 rounded-lg">
                  <div className="text-xl font-bold">
                    {notifications.filter(n => n.target === NotificationTarget.ALL).length}
                  </div>
                  <p className="mt-1 text-sm">All Users</p>
                </div>
                <div className="p-3 bg-gray-100 rounded-lg">
                  <div className="text-xl font-bold">
                    {notifications.filter(n => n.target === NotificationTarget.ADMIN).length}
                  </div>
                  <p className="mt-1 text-sm">Admins</p>
                </div>
                <div className="p-3 bg-gray-100 rounded-lg">
                  <div className="text-xl font-bold">
                    {notifications.filter(n => n.target === NotificationTarget.VENDORS).length}
                  </div>
                  <p className="mt-1 text-sm">Vendors</p>
                </div>
                <div className="p-3 bg-gray-100 rounded-lg">
                  <div className="text-xl font-bold">
                    {notifications.filter(n => n.target === NotificationTarget.CUSTOMERS).length}
                  </div>
                  <p className="mt-1 text-sm">Customers</p>
                </div>
              </div>
            </div>
            
            <div className="p-4 border border-dashed border-gray-300 rounded-lg">
              <h4 className="font-medium">Unread Notifications</h4>
              <div className="mt-2 text-2xl font-bold text-primary">
                {notifications.filter(n => !n.read).length}
              </div>
              {notifications.filter(n => !n.read).length > 0 && (
                <button 
                  className="mt-2 text-sm text-primary hover:underline"
                  onClick={() => setNotifications(notifications.map(n => ({ ...n, read: true })))}
                >
                  Mark all as read
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
      
      {/* Create Notification Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="card w-full max-w-lg">
            <h3 className="text-lg font-semibold mb-4">Send New Notification</h3>
            
            {error && (
              <div className="mb-4 p-3 bg-danger bg-opacity-10 text-danger rounded-md">
                {error}
              </div>
            )}
            
            <form onSubmit={handleCreateNotification}>
              <div className="mb-4">
                <label className="form-label" htmlFor="title">Title</label>
                <input
                  id="title"
                  type="text"
                  className="form-input"
                  value={newNotification.title}
                  onChange={(e) => setNewNotification({...newNotification, title: e.target.value})}
                  required
                />
              </div>
              
              <div className="mb-4">
                <label className="form-label" htmlFor="message">Message</label>
                <textarea
                  id="message"
                  className="form-input"
                  rows={4}
                  value={newNotification.message}
                  onChange={(e) => setNewNotification({...newNotification, message: e.target.value})}
                  required
                ></textarea>
              </div>
              
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 mb-4">
                <div>
                  <label className="form-label" htmlFor="type">Type</label>
                  <select
                    id="type"
                    className="form-input"
                    value={newNotification.type}
                    onChange={(e) => setNewNotification({
                      ...newNotification, 
                      type: e.target.value as NotificationType
                    })}
                  >
                    <option value={NotificationType.INFO}>Information</option>
                    <option value={NotificationType.WARNING}>Warning</option>
                    <option value={NotificationType.SUCCESS}>Success</option>
                    <option value={NotificationType.ERROR}>Error</option>
                  </select>
                </div>
                
                <div>
                  <label className="form-label" htmlFor="target">Target Audience</label>
                  <select
                    id="target"
                    className="form-input"
                    value={newNotification.target}
                    onChange={(e) => setNewNotification({
                      ...newNotification, 
                      target: e.target.value as NotificationTarget
                    })}
                  >
                    <option value={NotificationTarget.ALL}>All Users</option>
                    <option value={NotificationTarget.ADMIN}>Admins Only</option>
                    <option value={NotificationTarget.VENDORS}>Vendors Only</option>
                    <option value={NotificationTarget.CUSTOMERS}>Customers Only</option>
                  </select>
                </div>
              </div>
              
              <div className="mb-6">
                <div className="flex items-center">
                  <input
                    id="sendEmail"
                    type="checkbox"
                    className="mr-2 h-4 w-4"
                    checked={newNotification.sendEmail}
                    onChange={(e) => setNewNotification({
                      ...newNotification, 
                      sendEmail: e.target.checked
                    })}
                  />
                  <label htmlFor="sendEmail">Also send as email to recipients</label>
                </div>
              </div>
              
              <div className="flex justify-end space-x-2">
                <button 
                  type="button"
                  className="btn btn-outline"
                  onClick={() => setShowCreateModal(false)}
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="btn btn-primary"
                >
                  Send Notification
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}