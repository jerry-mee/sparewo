'use client';

import React, { useState, useEffect } from 'react';
import Breadcrumb from '@/components/Breadcrumbs/Breadcrumb';
import PageContainer from '@/components/Layouts/PageContainer';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { ErrorMessage } from '@/components/ui/error-message';
import { Calendar, Clock, Car, Wrench, User, Phone, CheckCircle, XCircle } from 'lucide-react';

interface GarageRequest {
  id: string;
  customerName: string;
  customerPhone: string;
  carMakeModel: string;
  serviceType: string;
  appointmentDateTime: any; // Firebase Timestamp
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
}

enum GarageRequestStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled'
}

// Demo data for garage requests
const demoGarageRequests: GarageRequest[] = [
  {
    id: '1',
    customerName: 'John Doe',
    customerPhone: '+256 700 123456',
    carMakeModel: 'Toyota Corolla 2019',
    serviceType: 'Brake Replacement',
    appointmentDateTime: { toDate: () => new Date('2023-12-15T10:00:00') },
    status: 'pending'
  },
  {
    id: '2',
    customerName: 'Jane Smith',
    customerPhone: '+256 702 987654',
    carMakeModel: 'Honda Civic 2020',
    serviceType: 'Oil Change',
    appointmentDateTime: { toDate: () => new Date('2023-12-16T14:30:00') },
    status: 'confirmed'
  },
  {
    id: '3',
    customerName: 'Alice Johnson',
    customerPhone: '+256 705 456789',
    carMakeModel: 'Nissan Altima 2018',
    serviceType: 'Engine Diagnostic',
    appointmentDateTime: { toDate: () => new Date('2023-12-17T09:15:00') },
    status: 'completed'
  },
  {
    id: '4',
    customerName: 'Robert Brown',
    customerPhone: '+256 708 321654',
    carMakeModel: 'Mazda 3 2021',
    serviceType: 'Tire Rotation',
    appointmentDateTime: { toDate: () => new Date('2023-12-18T11:45:00') },
    status: 'cancelled'
  },
  {
    id: '5',
    customerName: 'Emily Davis',
    customerPhone: '+256 701 789012',
    carMakeModel: 'Ford Focus 2017',
    serviceType: 'AC Repair',
    appointmentDateTime: { toDate: () => new Date('2023-12-20T13:00:00') },
    status: 'pending'
  }
];

export default function AutoHubPage() {
  const [garageRequests, setGarageRequests] = useState<GarageRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  useEffect(() => {
    // Simulate API call to fetch garage requests
    const fetchGarageRequests = async () => {
      try {
        // In a real app, this would be a Firebase query
        setTimeout(() => {
          setGarageRequests(demoGarageRequests);
          setLoading(false);
        }, 1000);
      } catch (error) {
        console.error('Error fetching garage requests:', error);
        setError('Failed to load garage requests. Please try again.');
        setLoading(false);
      }
    };

    fetchGarageRequests();
  }, []);

  const formatDateTime = (date: Date) => {
    return date.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case GarageRequestStatus.PENDING:
        return <Badge variant='warning'>Pending</Badge>;
      case GarageRequestStatus.CONFIRMED:
        return <Badge variant='secondary'>Scheduled</Badge>;
      case GarageRequestStatus.COMPLETED:
        return <Badge variant='success'>Completed</Badge>;
      case GarageRequestStatus.CANCELLED:
        return <Badge variant='destructive'>Cancelled</Badge>;
      default:
        return <Badge variant='outline'>{status}</Badge>;
    }
  };

  const getServiceIcon = (serviceType: string) => {
    if (serviceType.toLowerCase().includes('brake')) {
      return <Car className='h-10 w-10 text-yellow-500' />;
    } else if (serviceType.toLowerCase().includes('oil')) {
      return <Wrench className='h-10 w-10 text-blue-500' />;
    } else if (serviceType.toLowerCase().includes('engine')) {
      return <Wrench className='h-10 w-10 text-red-500' />;
    } else if (serviceType.toLowerCase().includes('tire')) {
      return <Car className='h-10 w-10 text-gray-500' />;
    } else {
      return <Wrench className='h-10 w-10 text-indigo-500' />;
    }
  };

  // Filter garage requests
  const filteredRequests = garageRequests.filter((request) => {
    const matchesSearch = 
      request.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      request.carMakeModel.toLowerCase().includes(searchTerm.toLowerCase()) ||
      request.serviceType.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = statusFilter === 'all' || request.status === statusFilter;
    
    return matchesSearch && matchesStatus;
  });

  return (
    <PageContainer
      title='Auto Hub Management'
      subtitle='Manage garage service appointments and requests'
    >
      {/* Filters */}
      <div className='mb-6 flex flex-col gap-4 sm:flex-row sm:items-center'>
        <div className='relative flex-1'>
          <Input
            type='text'
            placeholder='Search by customer, car, or service...'
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className='pl-10'
          />
          <div className='absolute left-3 top-3 text-gray-400'>
            <svg
              xmlns='http://www.w3.org/2000/svg'
              className='h-5 w-5'
              fill='none'
              viewBox='0 0 24 24'
              stroke='currentColor'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                strokeWidth={2}
                d='M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z'
              />
            </svg>
          </div>
        </div>
        
        <div className='flex items-center gap-3'>
          <label htmlFor='status-filter' className='text-sm font-medium'>
            Status:
          </label>
          <select
            id='status-filter'
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className='rounded-md border border-gray-300 bg-white px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-800'
          >
            <option value='all'>All Statuses</option>
            <option value='pending'>Pending</option>
            <option value='confirmed'>Scheduled</option>
            <option value='completed'>Completed</option>
            <option value='cancelled'>Cancelled</option>
          </select>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <ErrorMessage
          title='Error Loading Data'
          message={error}
          variant='destructive'
          className='mb-6'
          retryAction={() => {
            setLoading(true);
            setError(null);
            // Retry loading
            setTimeout(() => {
              setGarageRequests(demoGarageRequests);
              setLoading(false);
            }, 1000);
          }}
        />
      )}
      
      {/* Garage Requests */}
      <div className='grid grid-cols-1 gap-6'>
        {loading ? (
          // Loading skeletons
          Array.from({ length: 3 }).map((_, index) => (
            <Card key={index}>
              <CardContent className='p-0'>
                <div className='space-y-3 p-6'>
                  <div className='flex items-center justify-between'>
                    <Skeleton className='h-6 w-48' />
                    <Skeleton className='h-6 w-24' />
                  </div>
                  <div className='flex items-center gap-4'>
                    <Skeleton className='h-10 w-10 rounded-full' />
                    <div className='space-y-2'>
                      <Skeleton className='h-4 w-32' />
                      <Skeleton className='h-4 w-24' />
                    </div>
                  </div>
                  <div className='grid grid-cols-1 gap-3 pt-3 sm:grid-cols-2'>
                    <Skeleton className='h-8 w-full' />
                    <Skeleton className='h-8 w-full' />
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        ) : filteredRequests.length === 0 ? (
          <Card>
            <CardContent className='flex flex-col items-center justify-center py-12'>
              <Calendar className='mb-4 h-12 w-12 text-gray-400' />
              <h3 className='mb-2 text-lg font-medium'>No garage requests found</h3>
              <p className='text-center text-gray-500'>
                {searchTerm || statusFilter !== 'all'
                  ? 'Try adjusting your search or filter'
                  : 'There are no garage service requests at this time'}
              </p>
            </CardContent>
          </Card>
        ) : (
          filteredRequests.map((request) => (
            <Card key={request.id} className='hover:shadow-md'>
              <CardContent className='p-6'>
                <div className='flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between'>
                  <div className='flex items-start gap-4'>
                    <div className='flex h-12 w-12 items-center justify-center rounded-full bg-primary/10'>
                      {getServiceIcon(request.serviceType)}
                    </div>
                    <div>
                      <div className='flex items-center gap-2'>
                        <h3 className='text-lg font-semibold'>{request.customerName}</h3>
                        {getStatusBadge(request.status)}
                      </div>
                      <p className='text-sm text-gray-500'>{request.carMakeModel}</p>
                      <p className='font-medium text-indigo-600'>{request.serviceType}</p>
                    </div>
                  </div>
                  
                  <div className='flex flex-col gap-1'>
                    <div className='flex items-center gap-2 text-sm'>
                      <Calendar className='h-4 w-4 text-gray-500' />
                      <span>{formatDateTime(request.appointmentDateTime.toDate())}</span>
                    </div>
                    <div className='flex items-center gap-2 text-sm'>
                      <Phone className='h-4 w-4 text-gray-500' />
                      <span>{request.customerPhone}</span>
                    </div>
                  </div>
                </div>
                
                {/* Action buttons based on status */}
                <div className='mt-4 flex justify-end gap-2'>
                  {request.status === 'pending' && (
                    <>
                      <Button
                        variant='outline'
                        size='sm'
                        onClick={() => alert('Appointment confirmed')}
                        className='flex items-center gap-1'
                      >
                        <CheckCircle className='h-4 w-4' />
                        <span>Confirm</span>
                      </Button>
                      <Button
                        variant='destructive'
                        size='sm'
                        onClick={() => alert('Appointment cancelled')}
                        className='flex items-center gap-1'
                      >
                        <XCircle className='h-4 w-4' />
                        <span>Cancel</span>
                      </Button>
                    </>
                  )}
                  
                  {request.status === 'confirmed' && (
                    <Button
                      variant='default'
                      size='sm'
                      onClick={() => alert('Marked as completed')}
                      className='flex items-center gap-1'
                    >
                      <CheckCircle className='h-4 w-4' />
                      <span>Mark Complete</span>
                    </Button>
                  )}
                  
                  <Button
                    variant='secondary'
                    size='sm'
                    onClick={() => alert('View details for ' + request.id)}
                  >
                    View Details
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))
        )}
      </div>
    </PageContainer>
  );
}

