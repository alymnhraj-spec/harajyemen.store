const OTP_TTL_MS = 10 * 60 * 1000; // 10 minutes

const pending = new Map();   // email -> { code, expiresAt }
const verified = new Set();  // emails that passed OTP check

function saveOtp(email, code) {
  pending.set(email, { code, expiresAt: Date.now() + OTP_TTL_MS });
}

function verifyOtp(email, code) {
  const entry = pending.get(email);
  if (!entry) return false;
  if (Date.now() > entry.expiresAt) {
    pending.delete(email);
    return false;
  }
  if (entry.code !== String(code)) return false;
  pending.delete(email);
  verified.add(email);
  return true;
}

function consumeVerified(email) {
  const ok = verified.has(email);
  verified.delete(email);
  return ok;
}

module.exports = { saveOtp, verifyOtp, consumeVerified };
