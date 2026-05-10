const RESEND_API_KEY = process.env.RESEND_API_KEY;
const FROM_EMAIL = "حراج اليمن <noreply@harajyemen.store>";

async function sendOtpEmail(toEmail, otp) {
  if (!RESEND_API_KEY) throw new Error("RESEND_API_KEY not configured");

  const resp = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: FROM_EMAIL,
      to: [toEmail],
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
    }),
  });

  if (!resp.ok) {
    const err = await resp.json().catch(() => ({}));
    throw new Error(err.message || `Resend error ${resp.status}`);
  }
}

module.exports = { sendOtpEmail };
