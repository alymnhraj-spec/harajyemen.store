const { getAdmin } = require("./firebase-admin");

// إعدادات احتياطية قديمة (Resend) — تُستخدم فقط إن لم يُضبَط بريد Gmail
const RESEND_API_KEY = process.env.RESEND_API_KEY;
const RESEND_FROM = process.env.RESEND_FROM_EMAIL || "حراج اليمن <onboarding@resend.dev>";
const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "haraj-yemen-app";

let _cfgCache = null;
let _cfgCacheAt = 0;
const CFG_TTL = 60 * 1000; // دقيقة

function buildOtpHtml(otp) {
  return `
    <div dir="rtl" style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px;">
      <h2 style="color: #1a5c38; margin-bottom: 8px;">حراج اليمن</h2>
      <p style="color: #555; margin-bottom: 24px;">مرحباً، استخدم الرمز التالي لتسجيل الدخول:</p>
      <div style="background: #f0fdf4; border: 2px solid #1a5c38; border-radius: 10px; padding: 20px; text-align: center; margin-bottom: 24px;">
        <span style="font-size: 36px; font-weight: bold; letter-spacing: 12px; color: #1a5c38;">${otp}</span>
      </div>
      <p style="color: #888; font-size: 13px;">صالح لمدة <strong>10 دقائق</strong> فقط. لا تشارك هذا الرمز مع أحد.</p>
    </div>`;
}

// يقرأ إعدادات البريد المُعدّة من لوحة الإدارة (Firestore: settings/email)
async function resolveEmailConfig() {
  if (_cfgCache && Date.now() - _cfgCacheAt < CFG_TTL) return _cfgCache;

  // 1) عبر Firebase Admin SDK (الأكثر أماناً — يحتاج FIREBASE_SERVICE_ACCOUNT)
  const admin = getAdmin();
  if (admin) {
    try {
      const snap = await admin.firestore().collection("settings").doc("email").get();
      const d = snap.exists ? snap.data() : null;
      if (d && d.sender_email && d.app_password) {
        _cfgCache = {
          user: String(d.sender_email).trim(),
          pass: String(d.app_password).replace(/\s/g, ""),
          name: d.sender_name || "حراج اليمن",
        };
        _cfgCacheAt = Date.now();
        return _cfgCache;
      }
    } catch (e) {
      console.error("[OTP] admin Firestore read failed:", e.message);
    }
  }

  // 2) عبر Firestore REST (قراءة عامة — يعمل ما دامت قواعد القراءة عامة)
  try {
    const url = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/settings/email`;
    const resp = await fetch(url);
    if (resp.ok) {
      const json = await resp.json();
      const f = (json && json.fields) || {};
      const user = f.sender_email && f.sender_email.stringValue && f.sender_email.stringValue.trim();
      const pass = f.app_password && f.app_password.stringValue && f.app_password.stringValue.replace(/\s/g, "");
      const name = (f.sender_name && f.sender_name.stringValue) || "حراج اليمن";
      if (user && pass) {
        _cfgCache = { user, pass, name };
        _cfgCacheAt = Date.now();
        return _cfgCache;
      }
    }
  } catch (e) {
    console.error("[OTP] REST Firestore read failed:", e.message);
  }

  // 3) متغيرات البيئة
  if (process.env.GMAIL_USER && process.env.GMAIL_APP_PASSWORD) {
    _cfgCache = {
      user: process.env.GMAIL_USER,
      pass: process.env.GMAIL_APP_PASSWORD.replace(/\s/g, ""),
      name: process.env.GMAIL_SENDER_NAME || "حراج اليمن",
    };
    _cfgCacheAt = Date.now();
    return _cfgCache;
  }

  return null;
}

async function sendViaGmail(cfg, toEmail, otp) {
  const nodemailer = require("nodemailer");
  const transporter = nodemailer.createTransport({
    host: "smtp.gmail.com",
    port: 465,
    secure: true,
    auth: { user: cfg.user, pass: cfg.pass },
  });
  const info = await transporter.sendMail({
    from: `${cfg.name} <${cfg.user}>`,
    to: toEmail,
    subject: "رمز التحقق - حراج اليمن",
    html: buildOtpHtml(otp),
  });
  console.log(`[OTP] Gmail sent id=${info.messageId} from=${cfg.user} to=${toEmail}`);
}

async function sendViaResend(toEmail, otp) {
  if (!RESEND_API_KEY) {
    throw new Error("لا يوجد إعداد بريد: اضبط بريد Gmail من لوحة الإدارة أو RESEND_API_KEY");
  }
  const resp = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: RESEND_FROM,
      to: [toEmail],
      subject: "رمز التحقق - حراج اليمن",
      html: buildOtpHtml(otp),
    }),
  });
  const data = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    const msg = data.message || (data.error && data.error.message) || `Resend error ${resp.status}`;
    console.error(`[OTP] Resend rejected (${resp.status}) for ${toEmail}: ${msg}`);
    throw new Error(msg);
  }
  console.log(`[OTP] Resend accepted id=${data.id || "?"} to=${toEmail}`);
}

async function sendOtpEmail(toEmail, otp) {
  const cfg = await resolveEmailConfig();
  if (cfg) {
    return sendViaGmail(cfg, toEmail, otp);
  }
  console.warn("[OTP] No Gmail config found — falling back to Resend");
  return sendViaResend(toEmail, otp);
}

module.exports = { sendOtpEmail };
