const nodemailer = require("nodemailer");

const GMAIL_USER = process.env.GMAIL_USER || "alymnhraj@gmail.com";
const GMAIL_PASS = process.env.GMAIL_PASS || "psearpitjgqisqzw";

const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 587,
  secure: false,
  family: 4,
  auth: {
    user: GMAIL_USER,
    pass: GMAIL_PASS,
  },
});

async function sendOtpEmail(toEmail, otp) {
  await transporter.sendMail({
    from: `"حراج اليمن" <${GMAIL_USER}>`,
    to: toEmail,
    subject: "رمز التحقق - حراج اليمن",
    html: `
      <div dir="rtl" style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px;">
        <h2 style="color: #1a5c38; margin-bottom: 8px;">حراج اليمن</h2>
        <p style="color: #555; margin-bottom: 24px;">مرحباً، استخدم الرمز التالي لتسجيل الدخول:</p>
        <div style="background: #f0fdf4; border: 2px solid #1a5c38; border-radius: 10px; padding: 20px; text-align: center; margin-bottom: 24px;">
          <span style="font-size: 36px; font-weight: bold; letter-spacing: 12px; color: #1a5c38;">${otp}</span>
        </div>
        <p style="color: #888; font-size: 13px;">صالح لمدة <strong>10 دقائق</strong> فقط. لا تشارك هذا الرمز مع أحد.</p>
      </div>
    `,
  });
}

module.exports = { sendOtpEmail };
