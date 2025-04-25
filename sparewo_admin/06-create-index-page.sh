#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}===== SpareWo Admin: Creating Index Page Fix =====${NC}"
echo -e "This script will create a proper index page for your static export"

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

# Step 1: Create simple index page
echo -e "\n${BLUE}[STEP 1]${NC} Creating a simple index page..."
mkdir -p src/app
cat > src/app/page.tsx << 'EOL'
export default function Home() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-4 text-center">
      <h1 className="text-4xl font-bold mb-4">SpareWo Admin Dashboard</h1>
      <p className="text-xl mb-8">Vendor and Product Management</p>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl">
        <a href="/vendors" className="p-6 bg-blue-100 rounded-lg hover:bg-blue-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Vendors</h2>
          <p>Manage vendor applications and approvals</p>
        </a>
        <a href="/products" className="p-6 bg-green-100 rounded-lg hover:bg-green-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Products</h2>
          <p>Manage product catalog and approvals</p>
        </a>
        <a href="/catalogs" className="p-6 bg-purple-100 rounded-lg hover:bg-purple-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Catalogs</h2>
          <p>Manage general and store catalogs</p>
        </a>
        <a href="/orders" className="p-6 bg-orange-100 rounded-lg hover:bg-orange-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Orders</h2>
          <p>Track and manage customer orders</p>
        </a>
      </div>
    </div>
  );
}
EOL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Successfully created simple index page${NC}"
  print_progress 25
else
  echo -e "${RED}✗ Failed to create index page${NC}"
  exit 1
fi

# Step 2: Update Next.js config
echo -e "\n${BLUE}[STEP 2]${NC} Updating Next.js configuration..."
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
  
  // Ensure an index page is created
  exportPathMap: async function() {
    return {
      '/': { page: '/' }
    };
  },
  
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
  echo -e "${GREEN}✓ Successfully updated Next.js configuration${NC}"
  print_progress 50
else
  echo -e "${RED}✗ Failed to update Next.js configuration${NC}"
  exit 1
fi

# Step 3: Update Firebase configuration
echo -e "\n${BLUE}[STEP 3]${NC} Updating Firebase configuration..."
cat > firebase.json << 'EOL'
{
  "hosting": {
    "target": "admin",
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
    "cleanUrls": true,
    "trailingSlash": false,
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
EOL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Successfully updated Firebase configuration${NC}"
  print_progress 75
else
  echo -e "${RED}✗ Failed to update Firebase configuration${NC}"
  exit 1
fi

# Step 4: Create a build and deploy script
echo -e "\n${BLUE}[STEP 4]${NC} Creating build and deploy script..."
cat > build-and-deploy.sh << 'EOL'
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}===== Building and Deploying SpareWo Admin =====${NC}"

# Clean cache
echo -e "\n${BLUE}[STEP 1]${NC} Cleaning build cache..."
rm -rf .next
rm -rf node_modules/.cache
rm -rf out
echo -e "${GREEN}✓ Cache cleaned${NC}"

# Build the project
echo -e "\n${BLUE}[STEP 2]${NC} Building the project..."
npm run build

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Build failed${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Build completed successfully${NC}"

# Ensure index.html exists
echo -e "\n${BLUE}[STEP 3]${NC} Verifying index.html..."
if [ ! -f "out/index.html" ]; then
  echo -e "${YELLOW}! index.html not found, creating minimal version...${NC}"
  cat > out/index.html << 'HTML_EOL'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SpareWo Admin Dashboard</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      padding: 20px;
      text-align: center;
      background-color: #f9fafb;
    }
    .container {
      max-width: 800px;
      width: 100%;
    }
    h1 {
      color: #111827;
      font-size: 2.25rem;
      margin-bottom: 1rem;
    }
    p {
      color: #4b5563;
      font-size: 1.125rem;
      margin-bottom: 2rem;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(1, 1fr);
      gap: 1.5rem;
      width: 100%;
    }
    @media (min-width: 768px) {
      .grid {
        grid-template-columns: repeat(2, 1fr);
      }
    }
    .card {
      background-color: white;
      border-radius: 0.5rem;
      padding: 1.5rem;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      transition: all 0.2s;
    }
    .card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    .card h2 {
      color: #111827;
      font-size: 1.5rem;
      margin-bottom: 0.5rem;
    }
    .card p {
      color: #6b7280;
      font-size: 1rem;
      margin-bottom: 0;
    }
    .vendors { background-color: #dbeafe; }
    .products { background-color: #dcfce7; }
    .catalogs { background-color: #f3e8ff; }
    .orders { background-color: #ffedd5; }
  </style>
</head>
<body>
  <div class="container">
    <h1>SpareWo Admin Dashboard</h1>
    <p>Vendor and Product Management</p>
    <div class="grid">
      <a href="/vendors" class="card vendors">
        <h2>Vendors</h2>
        <p>Manage vendor applications and approvals</p>
      </a>
      <a href="/products" class="card products">
        <h2>Products</h2>
        <p>Manage product catalog and approvals</p>
      </a>
      <a href="/catalogs" class="card catalogs">
        <h2>Catalogs</h2>
        <p>Manage general and store catalogs</p>
      </a>
      <a href="/orders" class="card orders">
        <h2>Orders</h2>
        <p>Track and manage customer orders</p>
      </a>
    </div>
  </div>
</body>
</html>
HTML_EOL
  echo -e "${GREEN}✓ Created minimal index.html${NC}"
else
  echo -e "${GREEN}✓ index.html exists${NC}"
fi

# Deploy to Firebase
echo -e "\n${BLUE}[STEP 4]${NC} Deploying to Firebase..."
firebase deploy --only hosting:admin

if [ $? -eq 0 ]; then
  echo -e "\n${BOLD}${GREEN}===== Deployment Successful! =====${NC}"
  echo -e "Your admin app is now available at: ${BOLD}https://sparewo-admin.web.app${NC}"
else
  echo -e "${RED}✗ Deployment failed${NC}"
  exit 1
fi
EOL

chmod +x build-and-deploy.sh

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Created build and deploy script${NC}"
  print_progress 100
else
  echo -e "${RED}✗ Failed to create build and deploy script${NC}"
  exit 1
fi

echo -e "\n${BOLD}${GREEN}All setup complete!${NC}"
echo -e "To build and deploy your project, run:"
echo -e "  ${BOLD}./build-and-deploy.sh${NC}"
echo -e "\nThis will create a proper index page, build your project, and deploy it to Firebase."