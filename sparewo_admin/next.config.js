/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Remove export mode for Vercel deployment
  // output: 'export', // Comment this out for Vercel
  
  // Image optimization works fine with Vercel
  images: {
    unoptimized: true,
    domains: ['firebasestorage.googleapis.com'], // Add your Firebase Storage domain
  },
  
  // Enable trailingSlash for consistent URL structure
  trailingSlash: true,
  
  // Font optimization is fine with Vercel
  optimizeFonts: true,
  
  // Webpack configuration for client-side bundling
  webpack: (config, { isServer }) => {
    if (!isServer) {
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