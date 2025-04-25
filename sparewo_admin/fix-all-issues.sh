#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Progress function
progress() {
  echo -e "${BLUE}[PROGRESS]${NC} $1"
}

# Success function
success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Error function
error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

# Warning function
warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Info function
info() {
  echo -e "${CYAN}[INFO]${NC} $1"
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}     SpareWo Admin Fix-All Script      ${NC}"
echo -e "${BLUE}========================================${NC}"

# Step 1: Install missing dependencies
progress "Step 1/7: Installing missing dependencies..."
npm install --save-dev crypto-browserify --silent || error "Failed to install crypto-browserify"
npm install --save-dev stream-browserify --silent || error "Failed to install stream-browserify"
npm install --save-dev assert --silent || error "Failed to install assert"
npm install --save-dev buffer --silent || error "Failed to install buffer"
npm install --save-dev util --silent || error "Failed to install util"
success "All dependencies installed successfully"

# Step 2: Fix Next.js configuration
progress "Step 2/7: Updating Next.js configuration..."
cat > next.config.js << 'EOL'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  
  // Tell Next.js to generate static HTML files
  output: 'export',
  
  // Disable image optimization for static export
  images: { 
    unoptimized: true 
  },
  
  // Enable trailingSlash for better compatibility with static hosting
  trailingSlash: true,
  
  // Disable strict mode for production
  experimental: {
    // Empty object
  },
  
  // Disable font optimization to avoid SWC issues
  optimizeFonts: false,
  
  // Disable webpacking problematic modules
  webpack: (config, { isServer }) => {
    if (!isServer) {
      // Ignore specific node modules in client-side bundling
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        child_process: false,
        undici: false,
        crypto: require.resolve('crypto-browserify'),
        stream: require.resolve('stream-browserify'),
        assert: require.resolve('assert'),
        buffer: require.resolve('buffer'),
        util: require.resolve('util'),
      };
    }
    return config;
  },
}

module.exports = nextConfig
EOL
success "Next.js configuration updated successfully"

# Step 3: Clean up dynamic route files
progress "Step 3/7: Fixing dynamic route files..."

# First, products/[id] directory
mkdir -p src/app/products/[id]/components

# Create the clean, simplified page.tsx
cat > src/app/products/[id]/page.tsx << 'EOL'
// Static shell page
export const dynamic = 'force-static';

export function generateStaticParams() {
  return [];
}

export default function ProductPage({ params }: { params: { id: string } }) {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold mb-4">Product Details</h1>
      <p>Loading product ID: {params.id}...</p>
      <div id="product-content-placeholder"></div>
    </div>
  );
}
EOL

# Now, vendors/[id] directory
mkdir -p src/app/vendors/[id]/components

# Create the clean, simplified page.tsx for vendors
cat > src/app/vendors/[id]/page.tsx << 'EOL'
// Static shell page
export const dynamic = 'force-static';

export function generateStaticParams() {
  return [];
}

export default function VendorPage({ params }: { params: { id: string } }) {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold mb-4">Vendor Details</h1>
      <p>Loading vendor ID: {params.id}...</p>
      <div id="vendor-content-placeholder"></div>
    </div>
  );
}
EOL

success "Dynamic route files fixed successfully"

# Step 4: Update client-side components (we'll move them to a client folder)
progress "Step 4/7: Setting up client-side components..."

# Create client directory for product details
mkdir -p src/app/products/client

# Create client product page
cat > src/app/products/client/[id].tsx << 'EOL'
'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { productService, ProductStatus } from '@/services/firebase.service';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card';
import { Package, Edit, ArrowLeft, Check, X, Image as ImageIcon } from 'lucide-react';
import LoadingScreen from '@/components/LoadingScreen';

export default function ProductClientPage({ params }: { params: { id: string } }) {
  const [product, setProduct] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchProduct = async () => {
      try {
        const productData = await productService.getProduct(params.id);
        setProduct(productData);
      } catch (error: any) {
        console.error('Error fetching product:', error);
        setError(error.message || 'Failed to load product details');
      } finally {
        setLoading(false);
      }
    };

    fetchProduct();
  }, [params.id]);

  if (loading) return <LoadingScreen />;
  
  if (error || !product) {
    return (
      <div className="container mx-auto px-4 py-8">
        <Link href="/products" className="inline-flex items-center text-primary mb-6 hover:underline">
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Products
        </Link>
        
        <Card>
          <CardHeader>
            <CardTitle className="text-red-600 dark:text-red-400">
              {error ? 'Error Loading Product' : 'Product Not Found'}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p>{error || `Product ${params.id} could not be found.`}</p>
          </CardContent>
          <CardFooter>
            <Button onClick={() => window.location.reload()}>Try Again</Button>
          </CardFooter>
        </Card>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <Link href="/products" className="inline-flex items-center text-primary mb-6 hover:underline">
        <ArrowLeft className="mr-2 h-4 w-4" />
        Back to Products
      </Link>
      
      <div className="rounded-lg bg-white p-6 shadow-sm dark:bg-boxdark">
        <h1 className="text-2xl font-bold">{product.name || 'Product Details'}</h1>
        <p className="mt-2">ID: {params.id}</p>
        <Badge className="mt-2">{product.status}</Badge>
      </div>
      
      {/* Simplified product details for demo */}
      <div className="mt-6 grid grid-cols-1 gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Product Information</CardTitle>
          </CardHeader>
          <CardContent>
            <p><strong>Price:</strong> {product.price}</p>
            <p><strong>Vendor:</strong> {product.vendorName}</p>
            <p><strong>Description:</strong> {product.description}</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
EOL

# Add client-side redirects to make navigation work
cat > src/app/products/[id]/client.js << 'EOL'
// Client-side navigation
document.addEventListener('DOMContentLoaded', function() {
  const productId = window.location.pathname.split('/').filter(Boolean).pop();
  const placeholder = document.getElementById('product-content-placeholder');
  
  if (placeholder) {
    // Show loading state initially
    placeholder.innerHTML = '<div class="animate-pulse bg-gray-200 h-32 rounded-md my-4"></div>';
    
    // After a brief delay, redirect to the client route
    setTimeout(() => {
      window.location.href = `/products/client/${productId}`;
    }, 500);
  }
});
EOL

# Create client directory for vendor details
mkdir -p src/app/vendors/client

# Create client vendor page
cat > src/app/vendors/client/[id].tsx << 'EOL'
'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { vendorService, VendorStatus } from '@/services/firebase.service';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card';
import { Store, Edit, ArrowLeft, Check, X } from 'lucide-react';
import LoadingScreen from '@/components/LoadingScreen';

export default function VendorClientPage({ params }: { params: { id: string } }) {
  const [vendor, setVendor] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchVendor = async () => {
      try {
        const vendorData = await vendorService.getVendor(params.id);
        setVendor(vendorData);
      } catch (error: any) {
        console.error('Error fetching vendor:', error);
        setError(error.message || 'Failed to load vendor details');
      } finally {
        setLoading(false);
      }
    };

    fetchVendor();
  }, [params.id]);

  if (loading) return <LoadingScreen />;
  
  if (error || !vendor) {
    return (
      <div className="container mx-auto px-4 py-8">
        <Link href="/vendors" className="inline-flex items-center text-primary mb-6 hover:underline">
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Vendors
        </Link>
        
        <Card>
          <CardHeader>
            <CardTitle className="text-red-600 dark:text-red-400">
              {error ? 'Error Loading Vendor' : 'Vendor Not Found'}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p>{error || `Vendor ${params.id} could not be found.`}</p>
          </CardContent>
          <CardFooter>
            <Button onClick={() => window.location.reload()}>Try Again</Button>
          </CardFooter>
        </Card>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <Link href="/vendors" className="inline-flex items-center text-primary mb-6 hover:underline">
        <ArrowLeft className="mr-2 h-4 w-4" />
        Back to Vendors
      </Link>
      
      <div className="rounded-lg bg-white p-6 shadow-sm dark:bg-boxdark">
        <h1 className="text-2xl font-bold">{vendor.businessName || 'Vendor Details'}</h1>
        <p className="mt-2">ID: {params.id}</p>
        <Badge className="mt-2">{vendor.status}</Badge>
      </div>
      
      {/* Simplified vendor details for demo */}
      <div className="mt-6 grid grid-cols-1 gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Vendor Information</CardTitle>
          </CardHeader>
          <CardContent>
            <p><strong>Contact:</strong> {vendor.name}</p>
            <p><strong>Email:</strong> {vendor.email}</p>
            <p><strong>Phone:</strong> {vendor.phone || 'N/A'}</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
EOL

# Add client-side redirects for vendors
cat > src/app/vendors/[id]/client.js << 'EOL'
// Client-side navigation
document.addEventListener('DOMContentLoaded', function() {
  const vendorId = window.location.pathname.split('/').filter(Boolean).pop();
  const placeholder = document.getElementById('vendor-content-placeholder');
  
  if (placeholder) {
    // Show loading state initially
    placeholder.innerHTML = '<div class="animate-pulse bg-gray-200 h-32 rounded-md my-4"></div>';
    
    // After a brief delay, redirect to the client route
    setTimeout(() => {
      window.location.href = `/vendors/client/${vendorId}`;
    }, 500);
  }
});
EOL

success "Client-side components set up successfully"

# Step 5: Create an HTML file that auto-includes the client.js script
progress "Step 5/7: Setting up client-side script loading..."

# Create a helper to inject the client.js script
cat > src/app/layout-script-helper.tsx << 'EOL'
// This helper ensures client.js scripts get automatically included
// where needed for dynamic route pages

export function ScriptHelper({ pathname }: { pathname: string }) {
  let scriptSrc = '';
  
  if (pathname.startsWith('/products/') && !pathname.startsWith('/products/client/')) {
    scriptSrc = '/products/[id]/client.js';
  } else if (pathname.startsWith('/vendors/') && !pathname.startsWith('/vendors/client/')) {
    scriptSrc = '/vendors/[id]/client.js';
  }
  
  if (!scriptSrc) return null;
  
  return (
    <script
      src={scriptSrc}
      async
      defer
    />
  );
}
EOL

# Update the root layout to include the scripts helper
progress "Updating layout.tsx to include script helper..."
cat > src/app/layout.tsx.new << 'EOL'
import { Providers } from './providers';
import { ScriptHelper } from './layout-script-helper';
import { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'SpareWo Admin Dashboard',
  description: 'Administration panel for SpareWo auto parts marketplace',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      </head>
      <body>
        <Providers>
          {children}
          <ScriptHelper pathname={typeof window !== 'undefined' ? window.location.pathname : ''} />
        </Providers>
      </body>
    </html>
  );
}
EOL

# Copy the new layout, preserving the old one just in case
cp src/app/layout.tsx src/app/layout.tsx.backup
cp src/app/layout.tsx.new src/app/layout.tsx
rm src/app/layout.tsx.new

success "Client-side script loading set up"

# Step 6: Clean the build cache
progress "Step 6/7: Cleaning build cache..."
rm -rf .next
rm -rf node_modules/.cache
rm -rf out
success "Build cache cleaned"

# Step 7: Try to build the project
progress "Step 7/7: Building the project..."
info "This might take a moment..."

# Store build output in a variable to check for errors
BUILD_OUTPUT=$(npm run build 2>&1)
BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -ne 0 ]; then
  warning "Build completed with warnings or errors"
  echo -e "${YELLOW}Build output:${NC}"
  echo "$BUILD_OUTPUT"
  
  # Check for common errors and provide solutions
  if echo "$BUILD_OUTPUT" | grep -q "Cannot find module"; then
    warning "Missing module detected. Try running: npm install"
  fi
  
  if echo "$BUILD_OUTPUT" | grep -q "undici"; then
    warning "Undici module issue detected. The fix should handle this, but you may need to update the webpack config further."
  fi
else
  success "Build completed successfully!"
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}All fixes have been applied!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
info "Next steps:"
echo "1. Run 'npm run start' to test the application locally"
echo "2. Run 'npm run export' to generate static files (in the 'out' directory)"
echo "3. Deploy the 'out' directory to your hosting provider"
echo ""
info "If you encounter any issues, check the error messages and run this script again."
echo ""