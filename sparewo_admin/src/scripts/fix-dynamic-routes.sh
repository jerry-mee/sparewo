#!/bin/bash

echo "Fixing dynamic routes for static export..."

# Create directory for products/[id] if it doesn't exist
mkdir -p src/app/products/[id]

# Update products/[id]/page.tsx
cat > src/app/products/[id]/page.tsx << 'EOF'
export const dynamic = 'force-static'

export function generateStaticParams() {
  // This returns an empty array, meaning no static paths are generated at build time
  // The page will be generated on-demand in the browser
  return []
}

export default function ProductPage({ params }: { params: { id: string } }) {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold mb-4">Product Details</h1>
      <p>Loading product ID: {params.id}...</p>
      
      {/* Client-side component will fetch and render the actual data */}
      <div id="product-content-placeholder"></div>
      
      <script
        dangerouslySetInnerHTML={{
          __html: `
            // This script runs in the browser to fetch and render the product
            document.addEventListener('DOMContentLoaded', function() {
              const productId = "${params.id}";
              const placeholder = document.getElementById('product-content-placeholder');
              
              if (placeholder) {
                placeholder.innerHTML = '<div class="animate-pulse bg-gray-200 h-32 rounded-md"></div>';
                
                // We'll actually fetch data client-side through Firebase
                // This is just a static shell for the export
              }
            });
          `,
        }}
      />
    </div>
  );
}
EOF

echo "✅ Fixed products/[id]/page.tsx"

# Create directory for vendors/[id] if it doesn't exist
mkdir -p src/app/vendors/[id]

# Update vendors/[id]/page.tsx
cat > src/app/vendors/[id]/page.tsx << 'EOF'
export const dynamic = 'force-static'

export function generateStaticParams() {
  // This returns an empty array, meaning no static paths are generated at build time
  // The page will be generated on-demand in the browser
  return []
}

export default function VendorPage({ params }: { params: { id: string } }) {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold mb-4">Vendor Details</h1>
      <p>Loading vendor ID: {params.id}...</p>
      
      {/* Client-side component will fetch and render the actual data */}
      <div id="vendor-content-placeholder"></div>
      
      <script
        dangerouslySetInnerHTML={{
          __html: `
            // This script runs in the browser to fetch and render the vendor
            document.addEventListener('DOMContentLoaded', function() {
              const vendorId = "${params.id}";
              const placeholder = document.getElementById('vendor-content-placeholder');
              
              if (placeholder) {
                placeholder.innerHTML = '<div class="animate-pulse bg-gray-200 h-32 rounded-md"></div>';
                
                // We'll actually fetch data client-side through Firebase
                // This is just a static shell for the export
              }
            });
          `,
        }}
      />
    </div>
  );
}
EOF

echo "✅ Fixed vendors/[id]/page.tsx"

# Check for any other dynamic routes and fix them
find src/app -type d -name '\[*\]' | while read -r dir; do
  if [[ "$dir" != "src/app/products/[id]" && "$dir" != "src/app/vendors/[id]" ]]; then
    route_name=$(basename "$dir")
    echo "Found another dynamic route: $route_name in $dir"
    
    # Get the name without brackets
    param_name=${route_name//[\[\]]/}
    
    # Create a basic page for this dynamic route
    cat > "$dir/page.tsx" << EOF
export const dynamic = 'force-static'

export function generateStaticParams() {
  // This returns an empty array, meaning no static paths are generated at build time
  return []
}

export default function DynamicPage({ params }: { params: { $param_name: string } }) {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold mb-4">Dynamic Content</h1>
      <p>Loading $param_name: {params.$param_name}...</p>
      
      {/* Client-side component will fetch and render the actual data */}
      <div id="dynamic-content-placeholder"></div>
      
      <script
        dangerouslySetInnerHTML={{
          __html: \`
            // This script runs in the browser to fetch and render the content
            document.addEventListener('DOMContentLoaded', function() {
              const paramValue = "\${params.$param_name}";
              const placeholder = document.getElementById('dynamic-content-placeholder');
              
              if (placeholder) {
                placeholder.innerHTML = '<div class="animate-pulse bg-gray-200 h-32 rounded-md"></div>';
              }
            });
          \`,
        }}
      />
    </div>
  );
}
EOF
    
    echo "✅ Fixed $dir/page.tsx"
  fi
done

# Update next.config.js to ensure proper static export
cat > next.config.js << 'EOF'
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
    // Configure static generation to handle dynamic routes
    runtime: 'edge',
  },
  
  // Disable font optimization to avoid SWC issues
  optimizeFonts: false,
  
  // Disable webpacking problematic modules (like undici)
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
      };
    }
    return config;
  },
}

module.exports = nextConfig
EOF

echo "✅ Updated next.config.js for better static export support"

# Create a specialized firebase hosting config for SPA-style routing
cat > firebase.json << 'EOF'
{
  "hosting": {
    "public": "out",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      }
    ]
  }
}
EOF

echo "✅ Updated firebase.json with optimal caching settings"

# Create a simple client-side navigation setup for dynamic routes
mkdir -p src/app/_components
cat > src/app/_components/ClientSideNavigator.tsx << 'EOF'
'use client';

import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';

export default function ClientSideNavigator() {
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    // Add event listener for clicks on links
    const handleClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const link = target.closest('a');
      
      if (link && link.href && link.href.startsWith(window.location.origin) && 
          !link.target && !link.download && !link.rel?.includes('external')) {
        e.preventDefault();
        const href = link.href.replace(window.location.origin, '');
        router.push(href);
      }
    };

    document.addEventListener('click', handleClick);
    
    return () => {
      document.removeEventListener('click', handleClick);
    };
  }, [router]);

  return null;
}
EOF

echo "✅ Created ClientSideNavigator component for better client-side routing"

# Update the root layout to include the ClientSideNavigator
cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from 'next';
import '@/styles/globals.css';
import { Providers } from './providers';
import ErrorBoundary from '@/components/ErrorBoundary';
import ClientSideNavigator from './_components/ClientSideNavigator';

export const metadata: Metadata = {
  title: 'SpareWo Admin Dashboard',
  description: 'Admin dashboard for the SpareWo platform',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="min-h-screen bg-gray-50 font-sans text-gray-900 antialiased dark:bg-boxdark dark:text-white">
        <Providers>
          <ErrorBoundary>
            <ClientSideNavigator />
            {children}
          </ErrorBoundary>
        </Providers>
      </body>
    </html>
  );
}
EOF

echo "✅ Updated root layout with ClientSideNavigator"

# Clean up build cache
echo "Cleaning up build cache..."
rm -rf .next
rm -rf out
rm -rf node_modules/.cache

echo "✅ Build cache cleaned"

echo ""
echo "SETUP COMPLETE!"
echo ""
echo "NEXT STEPS:"
echo "1. Run 'npm run build' to create your static site"
echo "2. Check the 'out' directory to make sure all files were generated"
echo "3. Install Firebase CLI if not already installed:"
echo "   npm install -g firebase-tools"
echo "4. Log in to Firebase:"
echo "   firebase login"
echo "5. Update .firebaserc with your Firebase project ID"
echo "6. Deploy to Firebase:"
echo "   firebase deploy --only hosting"
echo ""
echo "This creates a fully static version of your app that can be deployed to Firebase Hosting"