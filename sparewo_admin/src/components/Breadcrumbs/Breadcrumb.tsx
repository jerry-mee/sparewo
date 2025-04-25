import React from 'react';
import Link from 'next/link';
import { ChevronRight, Home } from 'lucide-react';

interface BreadcrumbItem {
  href: string;
  label: string;
}

interface BreadcrumbProps {
  pageName: string;
  items?: BreadcrumbItem[];
}

const Breadcrumb = ({ pageName, items = [] }: BreadcrumbProps) => {
  return (
    <div className="mb-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h2 className="text-2xl font-semibold text-gray-900 dark:text-white">
          {pageName}
        </h2>

        <nav>
          <ol className="flex items-center gap-2">
            <li>
              <Link 
                href="/" 
                className="flex items-center text-sm font-medium text-gray-500 hover:text-primary dark:text-gray-400"
              >
                <Home size={16} className="mr-1" />
                Home
              </Link>
            </li>
            
            {items.map((item, index) => (
              <React.Fragment key={index}>
                <li className="flex items-center text-gray-400">
                  <ChevronRight size={14} />
                </li>
                <li>
                  <Link
                    href={item.href}
                    className="text-sm font-medium text-gray-500 hover:text-primary dark:text-gray-400"
                  >
                    {item.label}
                  </Link>
                </li>
              </React.Fragment>
            ))}
            
            <li className="flex items-center text-gray-400">
              <ChevronRight size={14} />
            </li>
            <li className="text-sm font-medium text-primary">
              {pageName}
            </li>
          </ol>
        </nav>
      </div>
    </div>
  );
};

export default Breadcrumb;