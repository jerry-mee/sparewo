#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}===== SpareWo Admin: Next.js Configuration Fix (1/3) =====${NC}"
echo -e "This script will update your Next.js configuration to properly handle static exports."

# Print progress function
print_progress() {
  local width=50
  local percent=$1
  local completed=$((width * percent / 100))
  local remaining=$((width - completed))
  
  printf "[${GREEN}"
  printf "%${completed}s" | tr ' ' '='
  printf ">${NC}"
  printf "%${remaining}s" | tr ' ' ' '
  printf "] %d%%\n" "$percent"
}

# Create a backup of the original configuration
echo -e "\n${BLUE}[STEP 1]${NC} Creating backup of current next.config.js..."
if [ -f "next.config.js" ]; then
  cp next.config.js next.config.js.bak
  echo -e "${GREEN}✓ Backup created: next.config.js.bak${NC}"
  print_progress 25
else
  echo -e "${YELLOW}! No existing next.config.js found. Will create a new one.${NC}"
  print_progress 25
fi

# Create optimized Next.js configuration file
echo -e "\n${BLUE}[STEP 2]${NC} Creating optimized Next.js configuration..."
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
      };
    }
    return config;
  },
}

module.exports = nextConfig
EOL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Successfully created optimized Next.js configuration${NC}"
  print_progress 50
else
  echo -e "${RED}✗ Failed to create Next.js configuration${NC}"
  exit 1
fi

# Install necessary polyfills for browser environment
echo -e "\n${BLUE}[STEP 3]${NC} Installing necessary polyfills for browser environment..."
npm install --save-dev assert buffer crypto-browserify stream-browserify util

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Successfully installed polyfill packages${NC}"
  print_progress 75
else
  echo -e "${RED}✗ Failed to install polyfill packages. Try running the command manually:${NC}"
  echo -e "npm install --save-dev assert buffer crypto-browserify stream-browserify util"
  exit 1
fi

# Create polyfill directory and files
echo -e "\n${BLUE}[STEP 4]${NC} Creating polyfill helper file..."
mkdir -p lib
cat > lib/fetch-polyfill.js << 'EOL'
// Simple fetch polyfill for client side
if (typeof window !== 'undefined') {
  if (!window.fetch) {
    window.fetch = function() {
      console.warn('Fetch API polyfilled');
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
EOL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Successfully created fetch polyfill${NC}"
  print_progress 100
else
  echo -e "${RED}✗ Failed to create fetch polyfill${NC}"
  exit 1
fi

echo -e "\n${BOLD}${GREEN}First fix script completed successfully!${NC}"
echo -e "Please run the next script (02-fix-firebase-service.sh) to continue with the fixes."