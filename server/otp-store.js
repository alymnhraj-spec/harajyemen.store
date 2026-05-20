const OTP_TTL_MS = 10 * 60 * 1000; // 10 minutes

const pending = new Map();        // key -> { code, expiresAt }
const verified = new Set();       // emails verified for login
const resetVerified = new Set();  // emails verified for password reset

function saveOtp(email, code, purpose) {
  const key = purpose === "reset" ? email + ":reset" : email;
  pending.set(key, { code, expiresAt: Date.now() + OTP_TTL_MS });
}

function verifyOtp(email, code, purpose) {
  const key = purpose === "reset" ? email + ":reset" : email;
  const entry = pending.get(key);
  if (!entry) return false;
  if (Date.now() > entry.expiresAt) {
    pending.delete(key);
    return false;
  }
  if (entry.code !== String(code)) return false;
  pending.delete(key);
  if (purpose === "reset") resetVerified.add(email);
  else verified.add(email);
  return true;
}

function consumeVerified(email) {
  const ok = verified.has(email);
  verified.delete(email);
  return ok;
}

function consumeResetVerified(email) {
  const ok = resetVerified.has(email);
  resetVerified.delete(email);
  return ok;
}

module.exports = { saveOtp, verifyOtp, consumeVerified, consumeResetVerified };
