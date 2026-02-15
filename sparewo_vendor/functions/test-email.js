const admin = require('firebase-admin');
const serviceAccount = require('../sparewoapp-firebase-adminsdk-8eepq-7521b1e5e1.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function testEmailFunction() {
  try {
    console.log('Calling sendVerificationEmail function...');
    const result = await admin.functions().httpsCallable('sendVerificationEmail')({
      to: "pascalslaira@gmail.com",
      code: "1234",
      isVendor: true
    });
    
    console.log('Success:', result.data);
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

testEmailFunction();