'use client';

import React, { Component, ErrorInfo, ReactNode } from 'react';
import Link from 'next/link';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode; // Optional custom fallback component
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    // Define the initial state
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null
    };
  }

  // Update state when an error is thrown by a child component
  static getDerivedStateFromError(error: Error): Partial<State> {
    // Update state so the next render shows the fallback UI.
    return { hasError: true, error };
  }

  // Catch errors after they have been thrown, log them
  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    // You can log the error to an error reporting service here
    console.error("ErrorBoundary caught an error:", error, errorInfo);
    this.setState({ errorInfo }); // Store errorInfo if needed for display
  }

  // Method to reset the error boundary state, allowing children to re-render
  resetError = () => {
    this.setState({ hasError: false, error: null, errorInfo: null });
    // Optionally: Add logic here to attempt a recovery action if applicable
  }

  render(): ReactNode {
    if (this.state.hasError) {
      // Render the fallback UI if a custom fallback wasn't provided
      if (this.props.fallback) {
        return this.props.fallback;
      }

      // Default fallback UI
      return (
        <div className="flex flex-col items-center justify-center min-h-screen p-4 bg-gray-100 dark:bg-boxdark-2">
          <div className="w-full max-w-lg bg-white dark:bg-boxdark rounded-lg border border-stroke dark:border-strokedark shadow-lg p-6 text-center">
            <AlertTriangle className="mx-auto h-12 w-12 text-red-500 mb-4" />
            <h2 className="text-2xl font-bold text-red-600 dark:text-red-400 mb-3">Oops! Something went wrong.</h2>
            <p className="text-gray-700 dark:text-gray-300 mb-4">
              An unexpected error occurred. Please try again or contact support if the problem persists.
            </p>

            {/* Display error details in development mode or if needed */}
            {process.env.NODE_ENV === 'development' && this.state.error && (
              <div className="bg-gray-100 dark:bg-gray-900 p-3 rounded-md mb-4 text-left overflow-auto max-h-40 border border-stroke dark:border-strokedark">
                <p className="font-mono text-sm text-red-700 dark:text-red-300">
                  <strong>Error:</strong> {this.state.error?.message}
                </p>
                {/* Optionally display stack trace (can be verbose) */}
                {/* <details className="mt-2 text-xs text-gray-600 dark:text-gray-400">
                  <summary>Error Details</summary>
                  <pre className="whitespace-pre-wrap break-all">{this.state.error?.stack}</pre>
                  {this.state.errorInfo && <pre className="whitespace-pre-wrap break-all">{this.state.errorInfo.componentStack}</pre>}
                </details> */}
              </div>
            )}

            <div className="flex justify-center gap-4 mt-6">
              <button
                onClick={this.resetError}
                className="inline-flex items-center px-4 py-2 bg-primary text-white rounded-md hover:bg-primary-dark transition-colors focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2"
              >
                <RefreshCw className="mr-2 h-4 w-4" />
                Try again
              </button>
              <Link
                href="/"
                className="inline-flex items-center px-4 py-2 bg-gray-200 dark:bg-gray-700 text-gray-800 dark:text-gray-200 rounded-md hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2"
              >
                 <Home className="mr-2 h-4 w-4" />
                Go to Dashboard
              </Link>
            </div>
          </div>
        </div>
      );
    }

    // Normally, just render children
    return this.props.children;
  }
}

export default ErrorBoundary;
