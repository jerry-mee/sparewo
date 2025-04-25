import * as React from "react"
import { cn } from "@/lib/utils" // Assuming you have a utility for class names

// Main Card component
const Card = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "rounded-lg border border-stroke bg-white text-black shadow-default", // Base styles
      "dark:border-strokedark dark:bg-boxdark dark:text-white", // Dark mode styles
      className // Allow overriding styles
    )}
    {...props}
  />
))
Card.displayName = "Card"

// Card Header component
const CardHeader = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "flex flex-col space-y-1.5 p-4 md:p-6", // Padding and spacing
      "border-b border-stroke dark:border-strokedark", // Optional bottom border
       className
      )}
    {...props}
  />
))
CardHeader.displayName = "CardHeader"

// Card Title component
const CardTitle = React.forwardRef<
  HTMLParagraphElement, // Changed to h3 or appropriate heading level semantic
  React.HTMLAttributes<HTMLHeadingElement>
>(({ className, children, ...props }, ref) => (
  <h3 // Use h3 for semantic structure (or adjust as needed)
    ref={ref}
    className={cn(
      "text-lg md:text-xl font-semibold leading-none tracking-tight text-black dark:text-white", // Text styles
      className
    )}
    {...props}
  >
    {children}
  </h3>
))
CardTitle.displayName = "CardTitle"

// Card Description component
const CardDescription = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLParagraphElement>
>(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn(
      "text-sm text-gray-600 dark:text-gray-400", // Text styles for description
      className
    )}
    {...props}
  />
))
CardDescription.displayName = "CardDescription"

// Card Content component
const CardContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "p-4 md:p-6 pt-0", // Padding, removing top padding as Header/Title usually handle it
      className
    )}
    {...props}
  />
))
CardContent.displayName = "CardContent"

// Card Footer component
const CardFooter = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "flex items-center p-4 md:p-6 pt-0", // Padding, removing top padding
      "border-t border-stroke dark:border-strokedark", // Optional top border
      className
    )}
    {...props}
  />
))
CardFooter.displayName = "CardFooter"

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent }
