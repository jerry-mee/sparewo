'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { orderService, OrderStatus } from '@/services/firebase.service';
import { Eye, Send, ShoppingBag, Package, Truck, XCircle, CheckCircle } from 'lucide-react';

interface Order {
  id: string;
  customerName: string;
  customerEmail: string;
  customerPhone?: string;
  productIds: string[];
  productNames?: string[];
  totalAmount: number;
  status: OrderStatus | string;
  createdAt: any;
  [key: string]: any;
}

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null);
  const [emailModal, setEmailModal] = useState<{show: boolean, orderId: string | null}>({show: false, orderId: null});

  useEffect(() => {
    const unsubscribe = orderService.listenToOrders((ordersList) => {
      setOrders(ordersList);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const filteredOrders = filter === 'all' 
    ? orders 
    : orders.filter(order => order.status === filter);

  const handleStatusChange = async (id: string, newStatus: string) => {
    try {
      setStatusUpdating(id);
      await orderService.updateOrderStatus(id, newStatus as OrderStatus);
      setStatusUpdating(null);
      
      // If status changed to "processing", show email notification modal
      if (newStatus === OrderStatus.PROCESSING) {
        setEmailModal({show: true, orderId: id});
      }
    } catch (error) {
      console.error('Error updating order status:', error);
      setStatusUpdating(null);
    }
  };

  // Format UGX currency
  const formatUGX = (amount: number) => {
    return new Intl.NumberFormat('en-UG', {
      style: 'currency',
      currency: 'UGX',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
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

  const sendStatusUpdateEmail = async (orderId: string) => {
    try {
      const order = orders.find(o => o.id === orderId);
      if (!order) return;
      
      // In a real implementation, this would call a backend API
      console.log(`Sending email to ${order.customerEmail} about order ${orderId} status change to ${order.status}`);
      
      alert(`Status update email sent to ${order.customerEmail}`);
      setEmailModal({show: false, orderId: null});
    } catch (error) {
      console.error('Error sending notification email:', error);
      alert('Failed to send notification email');
    }
  };

  const getStatusClass = (status: string) => {
    switch (status) {
      case OrderStatus.DELIVERED: return 'badge-success';
      case OrderStatus.PENDING: return 'badge-pending';
      case OrderStatus.CANCELLED: return 'badge-danger';
      case OrderStatus.PROCESSING: return 'badge-info';
      case OrderStatus.SHIPPED: return 'badge-warning';
      default: return 'badge-secondary';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case OrderStatus.DELIVERED: return <CheckCircle size={16} />;
      case OrderStatus.PENDING: return <Package size={16} />;
      case OrderStatus.CANCELLED: return <XCircle size={16} />;
      case OrderStatus.PROCESSING: return <Package size={16} />;
      case OrderStatus.SHIPPED: return <Truck size={16} />;
      default: return null;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">Orders</h1>
          <p className="text-sm text-gray-500">Manage and process customer orders</p>
        </div>
        
        <div className="flex flex-wrap gap-3">
          <select
            className="chart-filter"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          >
            <option value="all">All Statuses</option>
            <option value={OrderStatus.PENDING}>Pending</option>
            <option value={OrderStatus.PROCESSING}>Processing</option>
            <option value={OrderStatus.SHIPPED}>Shipped</option>
            <option value={OrderStatus.DELIVERED}>Delivered</option>
            <option value={OrderStatus.CANCELLED}>Cancelled</option>
          </select>
        </div>
      </div>

      <div className="dashboard-card">
        <div className="overflow-x-auto">
          <table className="w-full table-auto">
            <thead className="bg-gray-50 dark:bg-boxdark-2">
              <tr className="border-b border-gray-200 dark:border-gray-700">
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Order ID
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Customer
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Products
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Date
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Total
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Status
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={7} className="p-4 text-center">
                    <div className="mx-auto h-8 w-8 border-2 border-primary border-t-transparent spin"></div>
                  </td>
                </tr>
              ) : filteredOrders.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-4 text-center text-gray-500">
                    No orders found
                  </td>
                </tr>
              ) : (
                filteredOrders.map((order) => (
                  <tr key={order.id} className="border-b border-gray-100 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-boxdark-2">
                    <td className="p-4">
                      <span className="font-medium text-gray-800 dark:text-white">
                        #{order.id.substring(0, 8).toUpperCase()}
                      </span>
                    </td>
                    <td className="p-4">
                      <div>
                        <p className="font-medium text-gray-800 dark:text-white">{order.customerName}</p>
                        <p className="text-sm text-gray-500">{order.customerEmail}</p>
                        {order.customerPhone && <p className="text-sm text-gray-500">{order.customerPhone}</p>}
                      </div>
                    </td>
                    <td className="p-4">
                      <div>
                        <p className="text-gray-700 dark:text-gray-300">{order.productIds?.length || 0} items</p>
                        {order.productNames && order.productNames.length > 0 && (
                          <p className="text-sm text-gray-500">
                            {order.productNames[0]}
                            {order.productNames.length > 1 ? ` +${order.productNames.length - 1} more` : ''}
                          </p>
                        )}
                      </div>
                    </td>
                    <td className="p-4">
                      <p className="text-gray-700 dark:text-gray-300">{formatDate(order.createdAt)}</p>
                    </td>
                    <td className="p-4">
                      <p className="text-gray-700 dark:text-gray-300">{formatUGX(order.totalAmount || 0)}</p>
                    </td>
                    <td className="p-4">
                      <span className={`badge ${getStatusClass(String(order.status))}`}>
                        {getStatusIcon(String(order.status))}
                        <span className="ml-1">
                          {String(order.status).charAt(0).toUpperCase() + String(order.status).slice(1)}
                        </span>
                      </span>
                    </td>
                    <td className="p-4">
                      <div className="flex items-center space-x-3.5">
                        {statusUpdating === order.id ? (
                          <div className="h-4 w-4 border-2 border-primary border-t-transparent spin"></div>
                        ) : (
                          <>
                            <select 
                              className="chart-filter text-xs"
                              value={String(order.status)}
                              onChange={(e) => handleStatusChange(order.id, e.target.value)}
                            >
                              <option value={OrderStatus.PENDING}>Pending</option>
                              <option value={OrderStatus.PROCESSING}>Processing</option>
                              <option value={OrderStatus.SHIPPED}>Shipped</option>
                              <option value={OrderStatus.DELIVERED}>Delivered</option>
                              <option value={OrderStatus.CANCELLED}>Cancelled</option>
                            </select>
                            
                            <button 
                              className="text-gray-500 hover:text-primary"
                              onClick={() => setEmailModal({show: true, orderId: order.id})}
                              title="Send notification"
                            >
                              <Send className="h-5 w-5" />
                            </button>
                            
                            <Link href={`/orders/${order.id}`} className="text-gray-500 hover:text-primary">
                              <Eye className="h-5 w-5" />
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

      {/* Email Notification Modal */}
      {emailModal.show && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="dashboard-card w-full max-w-md">
            <h3 className="text-lg font-semibold mb-4 text-gray-800 dark:text-white">Send Status Update Notification</h3>
            <p className="mb-4 text-gray-700 dark:text-gray-300">
              Send an email notification to the customer about their order status change.
            </p>
            <div className="flex justify-end space-x-2">
              <button 
                className="chart-filter"
                onClick={() => setEmailModal({show: false, orderId: null})}
              >
                Cancel
              </button>
              <button 
                className="rounded-lg bg-primary px-4 py-2 text-white hover:bg-primary-dark"
                onClick={() => emailModal.orderId && sendStatusUpdateEmail(emailModal.orderId)}
              >
                Send Email
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}