import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils"; // Assuming you have a utility for class names

// Define badge variants using class-variance-authority
const badgeVariants = cva(
  // Base styles for all badges
  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      // Define different visual styles (variants)
      variant: {
        default:
          "border-transparent bg-primary text-primary-foreground hover:bg-primary/80 dark:bg-primary dark:text-white dark:hover:bg-primary/90", // Primary/Default style
        secondary:
          "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80 dark:bg-gray-700 dark:text-gray-200 dark:hover:bg-gray-600", // Secondary style
        destructive:
          "border-transparent bg-red-600 text-white hover:bg-red-600/80 dark:bg-red-700 dark:hover:bg-red-700/90", // Destructive/Error style
        outline:
          "border-stroke text-foreground dark:border-strokedark dark:text-white", // Outline style
        // Semantic status variants
        success:
          "border-transparent bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400", // Success status
        warning:
          "border-transparent bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400", // Warning status
        danger: // Alias for destructive, or slightly different style
           "border-transparent bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400",
        info:
          "border-transparent bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400", // Info status
        pending: // Custom status example
           "border-transparent bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400",
      },
    },
    // Default variant if none is specified
    defaultVariants: {
      variant: "default",
    },
  }
);

// Define the props interface, extending HTML attributes and variant props
export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

// Badge Component Implementation
function Badge({ className, variant, ...props }: BadgeProps) {
  // Render a div with the computed classes
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  );
}

export { Badge, badgeVariants }; // Export the component and variants
