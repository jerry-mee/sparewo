import { Card, CardContent } from "./card";
import { ReactNode } from "react";

interface StatCardProps {
  title: string;
  value: number | string;
  icon: ReactNode;
  change?: string;
  changeDirection?: 'up' | 'down';
  color?: string;
}

export function StatCard({
  title,
  value,
  icon,
  change,
  changeDirection = 'up',
  color = 'bg-indigo-600',
}: StatCardProps) {
  return (
    <Card>
      <CardContent className="p-4 md:p-6">
        <div className="flex items-center">
          <div className={`p-3 rounded-full ${color} mr-4 flex-shrink-0`}>
            {icon}
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400 truncate">{title}</p>
            <p className="text-2xl font-semibold truncate">{value}</p>
            {change && (
              <div className="flex items-center mt-1">
                <span className={`text-xs font-medium ${
                  changeDirection === 'up' ? 'text-green-500' : 'text-red-500'
                }`}>
                  {change}
                </span>
                <span className="text-xs ml-1 text-gray-500 dark:text-gray-400">from last month</span>
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
