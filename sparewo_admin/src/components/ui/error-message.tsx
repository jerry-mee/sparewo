
import * as React from "react"
import { cn } from "@/lib/utils"
import { AlertCircle, XCircle, RefreshCw } from "lucide-react"
import { Button } from "@/components/ui/button"

interface ErrorMessageProps extends React.HTMLAttributes<HTMLDivElement> {
  title?: string
  message: string
  retryAction?: () => void
  dismissAction?: () => void
  variant?: "default" | "destructive" | "outline"
}

export function ErrorMessage({
  className,
  title = "An error occurred",
  message,
  retryAction,
  dismissAction,
  variant = "default",
  ...props
}: ErrorMessageProps) {
  return (
    <div
      className={cn(
        "rounded-lg border p-4",
        {
          "bg-red-50 border-red-200 text-red-800 dark:bg-red-900/20 dark:border-red-800 dark:text-red-300": variant === "destructive",
          "bg-muted border-border": variant === "outline",
          "bg-destructive/5 border-destructive/10": variant === "default",
        },
        className
      )}
      role="alert"
      {...props}
    >
      <div className="flex items-start">
        <div className="flex-shrink-0">
          {variant === "destructive" ? (
            <XCircle className="h-5 w-5 text-red-500 dark:text-red-400" />
          ) : (
            <AlertCircle className="h-5 w-5 text-destructive" />
          )}
        </div>
        
        <div className="ml-3 w-full">
          <h3 className="text-sm font-medium">{title}</h3>
          <div className="mt-1 text-sm opacity-90">{message}</div>
          
          {(retryAction || dismissAction) && (
            <div className="mt-3 flex gap-2">
              {retryAction && (
                <Button 
                  size="sm" 
                  onClick={retryAction}
                  variant="outline"
                  className="inline-flex items-center"
                >
                  <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
                  Retry
                </Button>
              )}
              
              {dismissAction && (
                <Button 
                  size="sm" 
                  onClick={dismissAction}
                  variant="ghost"
                >
                  Dismiss
                </Button>
              )}
            </div>
          )}
        </div>
        
        {dismissAction && !retryAction && (
          <button
            onClick={dismissAction}
            className="ml-auto -mx-1.5 -my-1.5 inline-flex h-6 w-6 items-center justify-center rounded-md p-1 opacity-70 hover:opacity-100"
          >
            <span className="sr-only">Dismiss</span>
            <XCircle className="h-4 w-4" />
          </button>
        )}
      </div>
    </div>
  )
}

