const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');
const fs = require('fs');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'attendance-monitoring-sy-89218.appspot.com'
});

async function run() {
  try {
    fs.writeFileSync('dummy.txt', 'Hello World');
    
    console.log("Attempting to upload to Firebase Storage...");
    const bucket = admin.storage().bucket();
    
    await bucket.upload('dummy.txt', {
      destination: 'profiles/dummy.txt',
      metadata: { contentType: 'text/plain' },
    });
    console.log("Upload successful!");
    
    const url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/profiles%2Fdummy.txt?alt=media`;
    console.log("URL:", url);
  } catch (e) {
    console.error("Firebase Storage Upload Error:");
    console.error(e);
  } finally {
    if (fs.existsSync('dummy.txt')) fs.unlinkSync('dummy.txt');
  }
}

run();
