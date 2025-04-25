#!/bin/bash

echo "Fixing Babel configuration issues..."

# Update Babel configuration to include private methods transform
cat > .babelrc << 'EOF'
{
  "presets": [
    [
      "next/babel",
      {
        "preset-env": {
          "targets": {
            "browsers": "> 1%, not dead, not ie 11, not op_mini all"
          }
        }
      }
    ]
  ],
  "plugins": [
    "@babel/plugin-transform-private-methods",
    "@babel/plugin-transform-private-property-in-object",
    "@babel/plugin-transform-class-properties"
  ]
}
EOF
echo "✅ Updated .babelrc with necessary plugins"

# Create an optimized Next.js config
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  
  // Configure webpack for better compatibility
  webpack: (config, { isServer }) => {
    // Avoid issues with undici
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        "undici": false
      };
    }
    
    return config;
  },
  
  // Reduce parallel operations
  experimental: {
    cpus: 1,
  },
  
  // Disable font optimization temporarily
  optimizeFonts: false
}

module.exports = nextConfig
EOF
echo "✅ Created optimized next.config.js"

# Install required Babel plugins
echo "Installing required Babel plugins..."
npm install --save-dev @babel/plugin-transform-private-methods @babel/plugin-transform-private-property-in-object @babel/plugin-transform-class-properties

echo "✅ Installed required Babel plugins"

# Clean up build cache
echo "Cleaning up build cache..."
rm -rf .next
rm -rf node_modules/.cache

echo "✅ Build cache cleaned"

# Suggestion for Firebase hosting
echo ""
echo "NEXT STEPS:"
echo "1. Run 'npm run build && npm run start' to build and start your app"
echo ""
echo "FIREBASE HOSTING INFORMATION:"
echo "Yes, Firebase Hosting supports Next.js applications. Here's how to deploy:"
echo ""
echo "1. Install Firebase CLI if not already installed:"
echo "   npm install -g firebase-tools"
echo ""
echo "2. Initialize Firebase (if not already done):"
echo "   firebase login"
echo "   firebase init hosting"
echo ""
echo "3. During initialization, select these options:"
echo "   - Build directory: out"
echo "   - Configure as single-page app: No"
echo "   - Set up automatic builds: No (for now)"
echo ""
echo "4. Update your package.json with a build script:"
echo '   "scripts": {'
echo '     "build": "next build",'
echo '     "export": "next export",'
echo '     "firebase-deploy": "npm run build && npm run export && firebase deploy --only hosting"'
echo '   }'
echo ""
echo "5. Deploy to Firebase:"
echo "   npm run firebase-deploy"
echo ""
echo "This will deploy your Next.js application to Firebase Hosting."