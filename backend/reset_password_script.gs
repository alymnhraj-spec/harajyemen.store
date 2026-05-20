// Google Apps Script - Firebase Password Reset Backend
// Deploy as Web App: Execute as "Me", Access "Anyone"
// Project: haraj-yemen-app (must be run from the Firebase project owner account)

const FIREBASE_PROJECT_ID = 'haraj-yemen-app';
const API_SECRET = 'hY8j3K2mP9q'; // same value in auth_service.dart

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const { email, newPassword, secret } = data;

    if (secret !== API_SECRET) {
      return respond({ success: false, error: 'Unauthorized' });
    }

    const otpCheck = checkOtpVerified(email);
    if (!otpCheck.ok) {
      return respond({ success: false, error: otpCheck.error });
    }

    const uid = getUserUid(email);
    if (!uid) {
      return respond({ success: false, error: 'المستخدم غير موجود' });
    }

    const changed = updateUserPassword(uid, newPassword);
    if (!changed) {
      return respond({ success: false, error: 'فشل تغيير كلمة المرور' });
    }

    deleteOtpDoc(email);
    return respond({ success: true });
  } catch (err) {
    return respond({ success: false, error: err.message });
  }
}

function checkOtpVerified(email) {
  const url = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/password_resets/${encodeURIComponent(email)}`;
  try {
    const res = UrlFetchApp.fetch(url, {
      headers: { Authorization: 'Bearer ' + ScriptApp.getOAuthToken() },
      muteHttpExceptions: true,
    });
    if (res.getResponseCode() === 404) {
      return { ok: false, error: 'لا يوجد طلب إعادة تعيين' };
    }
    const doc = JSON.parse(res.getContentText());
    const verified = doc.fields && doc.fields.verified && doc.fields.verified.booleanValue;
    if (!verified) return { ok: false, error: 'OTP لم يتم التحقق منه' };
    return { ok: true };
  } catch (e) {
    return { ok: false, error: e.message };
  }
}

function getUserUid(email) {
  const url = `https://identitytoolkit.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/accounts:lookup`;
  try {
    const res = UrlFetchApp.fetch(url, {
      method: 'post',
      contentType: 'application/json',
      headers: { Authorization: 'Bearer ' + ScriptApp.getOAuthToken() },
      payload: JSON.stringify({ email: [email] }),
      muteHttpExceptions: true,
    });
    const data = JSON.parse(res.getContentText());
    return (data.users && data.users[0] && data.users[0].localId) || null;
  } catch (e) {
    return null;
  }
}

function updateUserPassword(uid, newPassword) {
  const url = `https://identitytoolkit.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/accounts:update`;
  try {
    const res = UrlFetchApp.fetch(url, {
      method: 'post',
      contentType: 'application/json',
      headers: { Authorization: 'Bearer ' + ScriptApp.getOAuthToken() },
      payload: JSON.stringify({ localId: uid, password: newPassword }),
      muteHttpExceptions: true,
    });
    const data = JSON.parse(res.getContentText());
    return !!data.localId;
  } catch (e) {
    return false;
  }
}

function deleteOtpDoc(email) {
  try {
    const url = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/password_resets/${encodeURIComponent(email)}`;
    UrlFetchApp.fetch(url, {
      method: 'delete',
      headers: { Authorization: 'Bearer ' + ScriptApp.getOAuthToken() },
      muteHttpExceptions: true,
    });
  } catch (e) {}
}

function respond(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
