import React, { ReactNode } from 'react';

interface StatCardProps {
  title: string;
  value: string | number;
  icon: ReactNode;
  detail?: string;
  detailColor?: string;
  trend?: {
    value: string;
    isPositive: boolean;
  };
  bgColor?: string;
  iconBgColor?: string;
  iconColor?: string;
  className?: string;
}

/**
 * A stat card component with styling for dashboard metrics
 */
export const StatCard: React.FC<StatCardProps> = ({ 
  title, 
  value, 
  icon, 
  detail, 
  detailColor = "text-gray-500",
  trend,
  bgColor = "bg-white",
  iconBgColor = "bg-primary/10",
  iconColor = "text-primary",
  className = ''
}) => {
  return (
    <div className={`rounded-xl border border-gray-200 ${bgColor} p-5 shadow-sm transition-all hover:shadow-md dark:border-gray-700 dark:bg-boxdark ${className}`}>
      <div className="mb-3 flex items-center justify-between">
        <p className="text-sm font-medium text-gray-500 dark:text-gray-400">{title}</p>
        <div className={`flex h-10 w-10 items-center justify-center rounded-full ${iconBgColor} ${iconColor}`}>
          {icon}
        </div>
      </div>
      <h3 className="mb-1 text-3xl font-bold text-gray-900 dark:text-white">{value}</h3>
      <div className="flex items-center justify-between">
        {detail && <p className={`text-sm ${detailColor}`}>{detail}</p>}
        {trend && (
          <span className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
            trend.isPositive ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'
          }`}>
            {trend.isPositive ? '+' : ''}{trend.value}
          </span>
        )}
      </div>
    </div>
  );
};

export default StatCard;