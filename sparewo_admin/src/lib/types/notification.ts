export interface Notification {
  id: string;
  userId: string;
  recipientId?: string;
  title: string;
  message: string;
  type: 'info' | 'success' | 'warning' | 'error';
  link?: string;
  read: boolean;
  isRead?: boolean;
  createdAt: any;
  updatedAt: any;
}
