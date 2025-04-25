import React, { ReactNode } from 'react';

interface CardProps {
  children: ReactNode;
  className?: string;
}

export const Card = ({ children, className = '' }: CardProps) => {
  return (
    <div className={`bg-white rounded-lg p-6 shadow-sm dark:bg-boxdark ${className}`}>
      {children}
    </div>
  );
};

interface CardHeaderProps {
  title: string;
  action?: ReactNode;
}

export const CardHeader = ({ title, action }: CardHeaderProps) => {
  return (
    <div className="mb-4 flex items-center justify-between">
      <h2 className="text-lg font-semibold text-gray-800 dark:text-white">{title}</h2>
      {action}
    </div>
  );
};

interface ActionCardProps {
  title: string;
  icon: ReactNode;
  detail: string;
  count?: string | number;
  countColor?: string;
  href?: string;
  onClick?: () => void;
}

export const ActionCard = ({ 
  title, 
  icon, 
  detail, 
  count,
  countColor = "text-primary", 
  href, 
  onClick 
}: ActionCardProps) => {
  const CardContent = () => (
    <div className="flex flex-col justify-between rounded-lg border border-gray-200 p-5 transition-all hover:border-primary hover:shadow-md dark:border-gray-700">
      <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-primary/10 text-primary">
        {icon}
      </div>
      <div>
        <h3 className="mb-1 text-lg font-semibold">{title}</h3>
        <p className="mb-4 text-sm text-gray-600 dark:text-gray-400">
          {detail}
        </p>
        {count && (
          <div className={`text-sm font-medium ${countColor}`}>
            {count}
          </div>
        )}
      </div>
    </div>
  );

  if (href) {
    return (
      <a href={href} className="block">
        <CardContent />
      </a>
    );
  }

  return (
    <div onClick={onClick} className={onClick ? "cursor-pointer" : ""}>
      <CardContent />
    </div>
  );
};

interface StatusCardProps {
  title: string;
  items: {
    name: string;
    status: 'online' | 'offline';
  }[];
}

export const StatusCard = ({ title, items }: StatusCardProps) => {
  return (
    <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
      <h3 className="mb-3 font-medium">{title}</h3>
      <div className="space-y-2">
        {items.map((item, index) => (
          <div key={index} className="flex items-center justify-between">
            <span className="text-sm">{item.name}</span>
            <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
              item.status === 'online' 
                ? 'bg-green-100 text-green-600 dark:bg-green-900/20 dark:text-green-400' 
                : 'bg-red-100 text-red-600 dark:bg-red-900/20 dark:text-red-400'
            }`}>
              {item.status === 'online' ? 'Online' : 'Offline'}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};