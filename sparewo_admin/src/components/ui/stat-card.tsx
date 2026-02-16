import { Card, CardContent } from "./card";
import { ReactNode } from "react";

interface StatCardProps {
  title: string;
  value: number | string;
  icon: ReactNode;
  change?: string;
  changeDirection?: "up" | "down";
  color?: string;
}

export function StatCard({
  title,
  value,
  icon,
  change,
  changeDirection = "up",
  color = "bg-secondary",
}: StatCardProps) {
  return (
    <Card className="border-border/90 shadow-soft">
      <CardContent className="p-5">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-wide text-muted-foreground">{title}</p>
            <p className="mt-2 text-3xl font-semibold leading-none">{value}</p>
            {change && (
              <p
                className={`mt-2 text-xs font-medium ${
                  changeDirection === "up" ? "text-emerald-600" : "text-red-600"
                }`}
              >
                {change}
              </p>
            )}
          </div>
          <div className={`flex h-11 w-11 items-center justify-center rounded-xl text-white ${color}`}>
            {icon}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
