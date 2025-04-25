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
