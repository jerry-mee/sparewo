// test-email-http.js
const https = require('https');
const fs = require('fs');
const { GoogleAuth } = require('google-auth-library');

// Load your service account
const serviceAccount = require('/Users/jeremy/Developed Apps and Projects/sparewo/sparewo_vendor/sparewoapp-firebase-adminsdk-8eepq-7521b1e5e1.json');

async function getIdToken() {
  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: ['https://www.googleapis.com/auth/cloud-platform']
  });
  const client = await auth.getClient();
  const token = await client.getIdToken('https://us-central1-sparewoapp.cloudfunctions.net/');
  return token;
}

async function callFunction() {
  try {
    const token = await getIdToken();
    
    // Prepare request data
    const data = JSON.stringify({
      data: {
        to: "pascalslaira@gmail.com",
        code: "1234", 
        isVendor: true
      }
    });
    
    // Setup request options
    const options = {
      hostname: 'us-central1-sparewoapp.cloudfunctions.net',
      path: '/sendVerificationEmail',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        'Content-Length': data.length
      }
    };
    
    // Make the request
    const req = https.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      res.on('end', () => {
        console.log(`Status: ${res.statusCode}`);
        console.log('Response:', responseData);
      });
    });
    
    req.on('error', (error) => {
      console.error('Error:', error);
    });
    
    req.write(data);
    req.end();
  } catch (error) {
    console.error('Authentication error:', error);
  }
}

callFunction();