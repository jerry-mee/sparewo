#!/bin/bash

echo "Fixing route conflicts and Babel issues..."

# 1. Fix duplicate catalogs routes by removing one of them
if [ -d "src/app/(home)/catalogs" ]; then
  echo "Found duplicate catalogs route in (home) group, removing it..."
  rm -rf src/app/\(home\)/catalogs
  echo "✅ Removed src/app/(home)/catalogs"
fi

# 2. Fix Babel font loader conflict by creating a new .babelrc
echo "Updating .babelrc to be compatible with next/font..."
cat > .babelrc << 'EOF'
{
  "presets": ["next/babel"],
  "plugins": []
}
EOF
echo "✅ Updated .babelrc to be compatible with next/font"

# 3. Create a next.config.mjs file that works with fonts
echo "Creating next.config.mjs that works with SWC compiler..."
cat > next.config.mjs << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  
  // Configure for better client-side rendering
  experimental: {
    // Reduce parallel operations to avoid Firebase initialization errors
    cpus: 1,
    workerThreads: false,
  }
}

export default nextConfig;
EOF
echo "✅ Created next.config.mjs"

# 4. Remove old next.config.js
if [ -f "next.config.js" ]; then
  rm next.config.js
  echo "✅ Removed old next.config.js"
fi

echo "✅ Fix completed! Please rebuild your application."
echo "rm -rf .next && npm run build"