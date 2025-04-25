#!/bin/bash

echo "Removing Babel configuration completely and switching to SWC..."

# 1. Backup and remove .babelrc
if [ -f ".babelrc" ]; then
  mv .babelrc .babelrc.backup
  echo "✅ Backed up and removed .babelrc"
else
  echo "ℹ️ No .babelrc found"
fi

# 2. Backup and remove babel configuration from package.json if it exists
if grep -q "babel" package.json; then
  cp package.json package.json.backup
  jq 'del(.babel)' package.json > package.json.tmp && mv package.json.tmp package.json
  echo "✅ Removed babel configuration from package.json"
else
  echo "ℹ️ No babel configuration in package.json"
fi

# 3. Update next.config.js to use SWC
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  
  // Use SWC minification
  swcMinify: true,
  
  // For static exports with Firebase hosting
  output: 'export',
  images: { 
    unoptimized: true 
  },
  
  // Reduce parallel operations
  experimental: {
    cpus: 1,
  }
}

module.exports = nextConfig
EOF
echo "✅ Updated next.config.js to use SWC compiler"

# 4. Update package.json for Firebase hosting
echo "Updating package.json for Firebase hosting..."

# Create a temporary file with the updated package.json
cat > package.json.tmp << EOF
{
  "\$schema": "http://json.schemastore.org/package",
  "name": "sparewo-admin",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "clean": "rm -rf .next && rm -rf node_modules/.cache",
    "firebase-deploy": "npm run build && firebase deploy --only hosting"
  },
  "dependencies": {
    "@babel/runtime": "^7.23.8",
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
    "postcss": "^8.5.3",
    "tailwindcss": "^3.4.17",
    "typescript": "^5"
  }
}
EOF

mv package.json.tmp package.json
echo "✅ Updated package.json with Firebase deployment scripts"

# 5. Create firebase.json if not exists
if [ ! -f "firebase.json" ]; then
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
    ]
  }
}
EOF
  echo "✅ Created firebase.json configuration"
fi

# 6. Fix font usage in layout.tsx
if [ -f "src/app/layout.tsx" ]; then
  cp src/app/layout.tsx src/app/layout.tsx.backup
  # Remove font imports
  sed -i '' '/import.*next\/font/d' src/app/layout.tsx
  # Fix className to remove font references
  sed -i '' 's/className="[^"]*"/className="min-h-screen bg-gray-50 font-sans text-gray-900 antialiased dark:bg-boxdark dark:text-white"/' src/app/layout.tsx
  echo "✅ Removed font imports from layout.tsx"
fi

# Clean up build cache
echo "Cleaning up build cache..."
rm -rf .next
rm -rf out
rm -rf node_modules/.cache

echo "✅ Build cache cleaned"

echo ""
echo "NEXT STEPS:"
echo "1. Run 'npm run build' to verify the build works"
echo "2. Run 'firebase init hosting' (if you haven't already)"
echo "3. Deploy with 'npm run firebase-deploy'"