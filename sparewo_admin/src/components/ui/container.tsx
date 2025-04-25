
import * as React from "react"
import { cn } from "@/lib/utils"

interface ContainerProps extends React.HTMLAttributes<HTMLDivElement> {
  size?: "default" | "sm" | "lg" | "full"
}

export function Container({
  children,
  className,
  size = "default",
  ...props
}: ContainerProps) {
  return (
    <div
      className={cn(
        "mx-auto px-4 md:px-6",
        {
          "max-w-6xl": size === "default",
          "max-w-4xl": size === "sm",
          "max-w-7xl": size === "lg",
          "w-full": size === "full",
        },
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}

