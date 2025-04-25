import React from 'react';

const LoadingScreen = () => {
  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-background dark:bg-boxdark-2">
      <div className="flex flex-col items-center">
        {/* Enhanced Spinner Animation */}
        <div className="relative h-24 w-24">
          <div className="absolute inset-0 rounded-full border-4 border-gray-200 dark:border-gray-700 opacity-50"></div>
          <div className="absolute inset-0 h-full w-full animate-spin rounded-full border-4 border-t-primary border-l-primary border-r-primary/50 border-b-primary/50 dark:border-t-primary-light dark:border-l-primary-light dark:border-r-primary-light/50 dark:border-b-primary-light/50"></div>
           {/* Optional Inner Element */}
           {/* <div className="absolute inset-2 rounded-full bg-primary/10 dark:bg-primary-light/10"></div> */}
        </div>
        <div className="mt-8 text-center">
          <h2 className="text-xl font-semibold text-gray-800 dark:text-white mb-2 animate-pulse">
            Loading SpareWo Admin...
          </h2>
          <p className="text-gray-500 dark:text-gray-400">
            Please wait while we prepare your dashboard.
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoadingScreen;
