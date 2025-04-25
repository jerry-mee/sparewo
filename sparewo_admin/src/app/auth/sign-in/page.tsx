'use client';

import React from 'react';
import Signin from '@/components/Auth/Signin';

const SignInPage = () => {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-12 dark:bg-boxdark sm:px-6 lg:px-8">
      <Signin />
    </div>
  );
};

export default SignInPage;