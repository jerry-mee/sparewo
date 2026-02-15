const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);
const allowAllOrigins = allowedOrigins.length === 0 && process.env.NODE_ENV !== 'production';

app.use(cors({
  origin: (origin, callback) => {
    if (!origin) {
      callback(null, true);
      return;
    }
    if (allowAllOrigins || allowedOrigins.includes(origin)) {
      callback(null, true);
      return;
    }
    callback(new Error('Not allowed by CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true,
}));

// Proxy configuration
const proxyOptions = {
  target: 'https://sparewo.matchstick.ug',
  changeOrigin: true,
  secure: false,
  pathRewrite: {
    '^/api': '/api'
  },
  onProxyRes: function (proxyRes, req, res) {
    const requestOrigin = req.headers.origin;
    if (allowAllOrigins) {
      proxyRes.headers['Access-Control-Allow-Origin'] = '*';
    } else if (requestOrigin && allowedOrigins.includes(requestOrigin)) {
      proxyRes.headers['Access-Control-Allow-Origin'] = requestOrigin;
      proxyRes.headers['Vary'] = 'Origin';
    }
  },
  logLevel: 'debug'
};

app.use('/api', createProxyMiddleware(proxyOptions));

// Health check endpoint
app.get('/health', (req, res) => {
  res.send('Proxy server is running');
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
  console.log(`Proxy server running on http://localhost:${PORT}`);
});
