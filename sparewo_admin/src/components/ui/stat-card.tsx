import React, { ReactNode } from "react"
import { cn } from "@/lib/utils"
import { Card } from "@/components/ui/card"

interface StatCardProps {
  title: string
  value: string | number
  icon: ReactNode
  detail?: ReactNode
  detailColor?: string
  trend?: {
    value: string
    isPositive: boolean
  }
  iconColor?: string
  iconBgColor?: string
  className?: string
  children?: ReactNode
}

export function StatCard({
  title,
  value,
  icon,
  detail,
  detailColor = "text-muted-foreground",
  trend,
  iconColor = "text-primary",
  iconBgColor = "bg-primary/10",
  className,
  children,
  ...props
}: StatCardProps) {
  return (
    <Card className={cn("overflow-hidden", className)} {...props}>
      <div className="p-6">
        <div className="flex items-center justify-between">
          <p className="text-sm font-medium text-muted-foreground">{title}</p>
          <div className={cn("flex h-10 w-10 items-center justify-center rounded-full", iconBgColor)}>
            <div className={iconColor}>{icon}</div>
          </div>
        </div>
        <div className="mt-4">
          <div className="text-3xl font-bold">{value}</div>
          <div className="mt-1 flex items-center justify-between">
            {detail && <div className={cn("text-sm", detailColor)}>{detail}</div>}
            {trend && (
              <div
                className={cn(
                  "rounded-full px-2 py-0.5 text-xs font-medium",
                  trend.isPositive
                    ? "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"
                    : "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400"
                )}
              >
                {trend.isPositive ? "+" : ""}{trend.value}
              </div>
            )}
          </div>
        </div>
        {children && <div className="mt-4">{children}</div>}
      </div>
      {/* Optional highlight bar at the bottom */}
      <div className={cn("h-1 w-full bg-gradient-to-r", 
        trend?.isPositive 
          ? "from-green-500 to-green-300"
          : trend 
            ? "from-red-500 to-red-300"
            : "from-primary to-primary/70"
      )} />
    </Card>
  )
}
