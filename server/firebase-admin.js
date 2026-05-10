let _admin = null;

function getAdmin() {
  if (_admin) return _admin;
  const sa = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!sa) return null;
  try {
    const admin = require("firebase-admin");
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(JSON.parse(sa)) });
    }
    _admin = admin;
    return admin;
  } catch (e) {
    console.error("Firebase Admin init error:", e.message);
    return null;
  }
}

module.exports = { getAdmin };
