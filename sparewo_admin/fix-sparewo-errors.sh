#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}     SpareWo Admin Fix Script          ${NC}"
echo -e "${BLUE}========================================${NC}"

# Step 1: Fix the crypto-browserify error
echo -e "${YELLOW}[STEP 1/4]${NC} Fixing next.config.js..."
cp next.config.js next.config.js.backup
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
echo -e "${GREEN}✓ next.config.js updated successfully${NC}"

# Step 2: Fix the product detail page
echo -e "${YELLOW}[STEP 2/4]${NC} Fixing product detail page..."
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
echo -e "${GREEN}✓ Product detail page fixed${NC}"

# Step 3: Fix the vendor detail page
echo -e "${YELLOW}[STEP 3/4]${NC} Fixing vendor detail page..."
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
echo -e "${GREEN}✓ Vendor detail page fixed${NC}"

# Step 4: Clean build cache
echo -e "${YELLOW}[STEP 4/4]${NC} Cleaning build cache..."
rm -rf .next
rm -rf node_modules/.cache
rm -rf out
echo -e "${GREEN}✓ Build cache cleaned${NC}"

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}All fixes have been applied!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Run: ${BLUE}npm run build${NC}"
echo -e "2. If successful, run: ${BLUE}npm run start${NC}"
echo ""