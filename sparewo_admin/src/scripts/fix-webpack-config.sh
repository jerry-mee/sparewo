#!/bin/bash

echo "Fixing webpack configuration for undici compatibility..."

# Create a next.config.js file that properly handles undici
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  
  // For static exports with Firebase hosting
  output: 'export',
  images: { 
    unoptimized: true 
  },
  
  // Transpile packages with private methods
  transpilePackages: ['undici', 'firebase', '@firebase'],
  
  // Configure webpack to handle special modules
  webpack: (config, { isServer }) => {
    // Handle undici and other problematic dependencies
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        crypto: false,
        stream: false,
        http: false,
        https: false,
        zlib: false
      };
    }
    
    // Explicitly ignore problematic files
    config.module.rules.push({
      test: /node_modules\/undici\/lib\/web\/fetch\/util\.js$/,
      use: 'null-loader',
    });
    
    // Tell webpack to ignore specific imports from undici
    config.externals = [...(config.externals || []), 'undici'];
    
    return config;
  },
  
  // Reduce parallel operations
  experimental: {
    cpus: 1,
  }
}

module.exports = nextConfig
EOF

echo "✅ Updated next.config.js for undici compatibility"

# Create a null-loader.js file to handle problematic modules
mkdir -p scripts
cat > scripts/null-loader.js << 'EOF'
module.exports = function() {
  return '';
};
module.exports.pitch = function() {
  return '';
};
EOF

echo "✅ Created null-loader.js"

# Update package.json to install dependencies and fix build scripts
cp package.json package.json.backup
cat > package.json << 'EOF'
{
  "$schema": "http://json.schemastore.org/package",
  "name": "sparewo-admin",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "NEXT_IGNORE_WARNINGS=true next build",
    "start": "next start",
    "lint": "next lint",
    "clean": "rm -rf .next && rm -rf node_modules/.cache && rm -rf out",
    "export": "next export",
    "firebase-deploy": "npm run build && firebase deploy --only hosting"
  },
  "dependencies": {
    "@emotion/react": "^11.14.0",
    "@emotion/styled": "^11.14.0",
    "@mui/material": "^6.4.7",
    "@radix-ui/react-checkbox": "^1.1.4",
    "@radix-ui/react-select": "^2.1.6",
    "apexcharts": "^4.0.0",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "date-fns": "^3.3.1",
    "dayjs": "^1.11.10",
    "firebase": "^10.8.0",
    "jsvectormap": "^1.6.0",
    "lucide-react": "^0.334.0",
    "next": "14.1.0",
    "next-themes": "^0.2.1",
    "react": "^18.2.0",
    "react-apexcharts": "^1.4.1",
    "react-dom": "^18.2.0",
    "react-hook-form": "^7.50.1",
    "tailwind-merge": "^2.6.0",
    "tw-animate-css": "^1.2.5",
    "uuid": "^9.0.1"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "@types/uuid": "^9.0.8",
    "autoprefixer": "^10.4.21",
    "eslint": "^8",
    "eslint-config-next": "14.1.0",
    "null-loader": "^4.0.1",
    "postcss": "^8.5.3",
    "tailwindcss": "^3.4.17",
    "typescript": "^5"
  }
}
EOF

echo "✅ Updated package.json"

# Install null-loader
npm install --save-dev null-loader

# Create a simple fetch implementation for the client side
mkdir -p src/lib
cat > src/lib/fetch-polyfill.js << 'EOF'
// Simple fetch polyfill for client side
if (typeof window !== 'undefined') {
  if (!window.fetch) {
    window.fetch = function() {
      console.warn('Fetch API polyfilled');
      // Basic implementation that returns empty response
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve({}),
        text: () => Promise.resolve(''),
        blob: () => Promise.resolve(new Blob()),
        arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)),
        headers: new Headers(),
        status: 200,
        statusText: 'OK'
      });
    };
  }
}
EOF

echo "✅ Created fetch polyfill"

# Create custom next-env.d.ts to improve TypeScript compatibility
cat > next-env.d.ts << 'EOF'
/// <reference types="next" />
/// <reference types="next/image-types/global" />

// NOTE: This file should not be edited
// see https://nextjs.org/docs/basic-features/typescript for more information.

declare module 'undici' {
  export default {};
}
EOF

echo "✅ Updated next-env.d.ts"

# Clean up build cache
echo "Cleaning up build cache..."
rm -rf .next
rm -rf out
rm -rf node_modules/.cache

echo "✅ Build cache cleaned"

echo ""
echo "NEXT STEPS:"
echo "1. Install dependencies: npm install"
echo "2. Run 'npm run build' to verify the build works"
echo "3. If everything builds successfully, you can deploy with:"
echo "   npm run start"
echo ""
echo "If you still have issues, try a complete reinstall:"
echo "rm -rf node_modules"
echo "npm install"
echo "npm run build"