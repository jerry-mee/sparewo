// next.config.mjs
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    unoptimized: true,
    domains: ['firebasestorage.googleapis.com'],
  },
  trailingSlash: false,
  
  // Add transpilePackages option to ensure proper handling of problematic modules
  transpilePackages: ['undici'],
  
  webpack: (config, { isServer }) => {
    // Apply these rules regardless of whether it's server or client
    try {
      // Create a more comprehensive null-loader rule
      config.module.rules.push({
        test: /node_modules\/undici\/lib\/web\/fetch\/util\.js$/,
        use: 'null-loader',
      });
      
      // Add additional exclusions for problematic modules
      config.module.rules.push({
        test: /node_modules\/@firebase\/auth\/dist\/node-esm\/index\.js$/,
        use: 'null-loader',
      });
      
      // Set fallbacks for Node.js modules
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        child_process: false,
        "undici": false
      };
      
      // When building for browser (client-side), explicitly set these modules to empty
      if (!isServer) {
        // Update aliases to mock problematic packages
        config.resolve.alias = {
          ...config.resolve.alias,
          "undici": false,
          "node-fetch": false,
        };
      }
    } catch (error) {
      console.error("[Webpack] Failed to configure loaders:", error);
    }
    
    return config;
  },
};

export default nextConfig;