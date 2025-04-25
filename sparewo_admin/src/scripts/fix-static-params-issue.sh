#!/bin/bash

echo "Fixing generateStaticParams issue..."

# Fix products/[id]/page.tsx by removing generateStaticParams
if [ -f "src/app/products/[id]/page.tsx" ]; then
  # Create a backup
  cp src/app/products/[id]/page.tsx src/app/products/[id]/page.tsx.backup
  
  # Remove the generateStaticParams function
  sed -i '' '/export async function generateStaticParams/,/}/d' src/app/products/[id]/page.tsx
  
  echo "✅ Fixed products/[id]/page.tsx"
fi

# Fix vendors/[id]/page.tsx by removing generateStaticParams
if [ -f "src/app/vendors/[id]/page.tsx" ]; then
  # Create a backup
  cp src/app/vendors/[id]/page.tsx src/app/vendors/[id]/page.tsx.backup
  
  # Remove the generateStaticParams function
  sed -i '' '/export async function generateStaticParams/,/}/d' src/app/vendors/[id]/page.tsx
  
  echo "✅ Fixed vendors/[id]/page.tsx"
fi

# Update next.config.js to not require generateStaticParams
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  
  // Configure for better client-side rendering
  experimental: {
    // Reduce parallel operations to avoid Firebase initialization errors
    cpus: 1,
    workerThreads: false,
  }
}

module.exports = nextConfig
EOF

echo "✅ Updated next.config.js"

echo "Fix completed! Please rebuild your application."
echo "rm -rf .next && npm run build"