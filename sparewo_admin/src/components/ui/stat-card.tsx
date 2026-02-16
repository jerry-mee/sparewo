import Link from "next/link";
import { ReactNode } from "react";

import { Card, CardContent } from "./card";

interface StatCardProps {
  title: string;
  value: number | string;
  icon: ReactNode;
  change?: string;
  changeDirection?: "up" | "down";
  color?: string;
  href?: string;
}

export function StatCard({
  title,
  value,
  icon,
  change,
  changeDirection = "up",
  color = "bg-secondary",
  href,
}: StatCardProps) {
  const body = (
    <Card
      className={`border-border/90 shadow-soft transition-all ${
        href ? "hover:border-primary/40 hover:shadow-md" : ""
      }`}
    >
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

  if (!href) {
    return body;
  }

  return (
    <Link href={href} className="block rounded-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">
      {body}
    </Link>
  );
}
