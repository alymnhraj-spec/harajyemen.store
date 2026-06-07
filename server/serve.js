/**
 * Standalone production server for Expo static builds.
 *
 * Serves the output of build.js (static-build/) with two special routes:
 * - GET / or /manifest with expo-platform header → platform manifest JSON
 * - GET / without expo-platform → landing page HTML
 * Everything else falls through to static file serving from ./static-build/.
 *
 * Zero external dependencies — uses only Node.js built-ins (http, fs, path).
 */

const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const DB_DIR = path.dirname(path.resolve(process.env.DB_PATH || path.join(__dirname, "db.sqlite")));
const IMAGE_DIR = path.join(DB_DIR, "images");
fs.mkdirSync(IMAGE_DIR, { recursive: true });
const {
  bootstrap,
  findUserByPhone,
  findUserByEmail,
  signIn,
  signInWithEmail,
  signOut,
  updateUser,
  getListings,
  addListing,
  deleteListing,
  incrementViews,
  toggleFavorite,
  sendMessage,
  seedConversationOnce,
  getSessionUser,
} = require("./sqlite-store");
const { sendOtpEmail } = require("./mailer");
const { saveOtp, verifyOtp, consumeVerified, consumeResetVerified } = require("./otp-store");
const { getAdmin } = require("./firebase-admin");

const STATIC_ROOT = path.resolve(__dirname, "..", "public-web");
const basePath = (process.env.BASE_PATH || "/").replace(/\/+$/, "");

const MIME_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf",
  ".otf": "font/otf",
  ".map": "application/json",
};

function getAppName() {
  try {
    const appJsonPath = path.resolve(__dirname, "..", "app.json");
    const appJson = JSON.parse(fs.readFileSync(appJsonPath, "utf-8"));
    return appJson.expo?.name || "App Landing Page";
  } catch {
    return "App Landing Page";
  }
}

function serveManifest(platform, res) {
  const manifestPath = path.join(STATIC_ROOT, platform, "manifest.json");

  if (!fs.existsSync(manifestPath)) {
    res.writeHead(404, { "content-type": "application/json" });
    res.end(
      JSON.stringify({ error: `Manifest not found for platform: ${platform}` }),
    );
    return;
  }

  const manifest = fs.readFileSync(manifestPath, "utf-8");
  res.writeHead(200, {
    "content-type": "application/json",
    "expo-protocol-version": "1",
    "expo-sfv-version": "0",
  });
  res.end(manifest);
}

function serveWebPage(req, res) {
  const forwardedProto = req.headers["x-forwarded-proto"];
  const protocol = forwardedProto || "https";
  const host = req.headers["x-forwarded-host"] || req.headers["host"];
  const baseUrl = `${protocol}://${host}`;
  const expsUrl = `${host}`;

  const indexPath = path.join(STATIC_ROOT, "index.html");
  if (!fs.existsSync(indexPath)) {
    res.writeHead(404);
    res.end("Not Found");
    return;
  }

  let html = fs.readFileSync(indexPath, "utf-8");
  html = html
    .replace(/REPLIT_DEV_DOMAIN/g, expsUrl)
    .replace(/BASE_URL_PLACEHOLDER/g, baseUrl);

  res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
  res.end(html);
}

function serveStaticFile(urlPath, res) {
  const safePath = path.normalize(urlPath).replace(/^(\.\.(\/|\\|$))+/, "");
  const filePath = path.join(STATIC_ROOT, safePath);

  if (!filePath.startsWith(STATIC_ROOT)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    res.writeHead(404);
    res.end("Not Found");
    return;
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || "application/octet-stream";
  const content = fs.readFileSync(filePath);
  const isImmutable = [".woff", ".woff2", ".ttf", ".otf"].includes(ext);
  const cacheControl = isImmutable
    ? "public, max-age=31536000, immutable"
    : "no-cache, must-revalidate";
  res.writeHead(200, { "content-type": contentType, "cache-control": cacheControl });
  res.end(content);
}

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    "content-type": "application/json; charset=utf-8",
    "access-control-allow-origin": "*",
    "access-control-allow-headers": "content-type",
    "access-control-allow-methods": "GET,POST,PATCH,DELETE,OPTIONS",
  });
  res.end(JSON.stringify(payload));
}

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", (chunk) => {
      raw += chunk;
      if (raw.length > 10 * 1024 * 1024) {
        reject(new Error("Payload too large"));
      }
    });
    req.on("end", () => {
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch {
        reject(new Error("Invalid JSON"));
      }
    });
    req.on("error", reject);
  });
}

async function resolveSessionToken(req) {
  const token = req.headers["x-session-token"] || "";
  if (token && getSessionUser(token)) return token;

  const firebaseToken = req.headers["x-firebase-token"] || "";
  if (!firebaseToken) return token;
  const admin = getAdmin();
  if (!admin) return token;
  try {
    const decoded = await admin.auth().verifyIdToken(firebaseToken);
    const email = decoded.email;
    if (!email) return token;
    const name = decoded.name || email.split("@")[0] || "مستخدم";
    const { sessionToken } = signInWithEmail(email, name);
    return sessionToken;
  } catch {
    return token;
  }
}

async function handleApi(req, res, url) {
  if (req.method === "OPTIONS") {
    sendJson(res, 204, {});
    return true;
  }

  if (url.pathname === "/api/bootstrap" && req.method === "GET") {
    sendJson(res, 200, bootstrap(req.headers["x-session-token"] || ""));
    return true;
  }

  if (url.pathname === "/api/auth/signin" && req.method === "POST") {
    const body = await readJsonBody(req);
    sendJson(res, 200, signIn(body.phone, body.name));
    return true;
  }

  if (url.pathname === "/api/auth/lookup" && req.method === "GET") {
    const phone = url.searchParams.get("phone") || "";
    sendJson(res, 200, { user: findUserByPhone(phone) });
    return true;
  }

  if (url.pathname === "/api/auth/lookup-email" && req.method === "GET") {
    const email = url.searchParams.get("email") || "";
    sendJson(res, 200, { user: findUserByEmail(email) });
    return true;
  }

  if (url.pathname === "/api/auth/send-otp" && req.method === "POST") {
    const body = await readJsonBody(req);
    const email = String(body.email || "").trim().toLowerCase();
    const purpose = String(body.purpose || "login");
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      sendJson(res, 400, { error: "بريد إلكتروني غير صحيح" });
      return true;
    }
    const code = String(Math.floor(1000 + Math.random() * 9000));
    saveOtp(email, code, purpose);
    try {
      await sendOtpEmail(email, code);
    } catch (err) {
      console.error(`[OTP] send failed for ${email}:`, err.message);
      sendJson(res, 502, { error: "تعذّر إرسال رمز التحقق. تحقّق من إعداد البريد (Resend)." });
      return true;
    }
    sendJson(res, 200, { success: true });
    return true;
  }

  if (url.pathname === "/api/auth/verify-otp" && req.method === "POST") {
    const body = await readJsonBody(req);
    const email = String(body.email || "").trim().toLowerCase();
    const purpose = String(body.purpose || "login");
    const ok = verifyOtp(email, body.otp, purpose);
    if (!ok) {
      sendJson(res, 400, { error: "رمز التحقق غير صحيح أو انتهت صلاحيته" });
      return true;
    }
    if (purpose === "reset") {
      sendJson(res, 200, { verified: true });
      return true;
    }
    const user = findUserByEmail(email);
    if (user?.name) {
      const result = signInWithEmail(email, user.name);
      sendJson(res, 200, { verified: true, signedIn: true, user: result.user, sessionToken: result.sessionToken });
    } else {
      sendJson(res, 200, { verified: true, signedIn: false });
    }
    return true;
  }

  if (url.pathname === "/api/auth/reset-password" && req.method === "POST") {
    const body = await readJsonBody(req);
    const email = String(body.email || "").trim().toLowerCase();
    const newPassword = String(body.newPassword || "");
    if (!consumeResetVerified(email)) {
      sendJson(res, 401, { error: "يجب التحقق من البريد الإلكتروني أولاً" });
      return true;
    }
    if (!newPassword || newPassword.length < 6) {
      sendJson(res, 400, { error: "كلمة المرور يجب أن تكون 6 أحرف على الأقل" });
      return true;
    }
    const admin = getAdmin();
    if (!admin) {
      sendJson(res, 503, { error: "خدمة إعادة تعيين كلمة المرور غير متاحة حالياً" });
      return true;
    }
    try {
      const userRecord = await admin.auth().getUserByEmail(email);
      await admin.auth().updateUser(userRecord.uid, { password: newPassword });
      sendJson(res, 200, { success: true });
    } catch (err) {
      if (err.code === "auth/user-not-found") {
        sendJson(res, 404, { error: "لا يوجد حساب بهذا البريد الإلكتروني" });
      } else {
        console.error("reset-password error:", err.message);
        sendJson(res, 500, { error: "فشل تغيير كلمة المرور" });
      }
    }
    return true;
  }

  if (url.pathname === "/api/auth/signin-email" && req.method === "POST") {
    const body = await readJsonBody(req);
    const email = String(body.email || "").trim().toLowerCase();
    if (!consumeVerified(email)) {
      sendJson(res, 401, { error: "يجب التحقق من البريد الإلكتروني أولاً" });
      return true;
    }
    sendJson(res, 200, signInWithEmail(email, body.name));
    return true;
  }

  if (url.pathname === "/api/auth/signout" && req.method === "POST") {
    signOut(req.headers["x-session-token"] || "");
    sendJson(res, 200, { success: true });
    return true;
  }

  if (url.pathname === "/api/users/me" && req.method === "PATCH") {
    const body = await readJsonBody(req);
    try {
      const user = updateUser(req.headers["x-session-token"] || "", body);
      if (!user) {
        sendJson(res, 401, { error: "Unauthorized" });
        return true;
      }
      sendJson(res, 200, { user });
    } catch (error) {
      sendJson(res, error.statusCode || 400, { error: error.message || "Update failed" });
    }
    return true;
  }

  if (url.pathname === "/api/listings" && req.method === "GET") {
    sendJson(res, 200, { listings: getListings() });
    return true;
  }

  if (url.pathname === "/api/images" && req.method === "POST") {
    const body = await readJsonBody(req);
    const raw = String(body.data || "");
    const base64 = raw.replace(/^data:image\/\w+;base64,/, "");
    if (!base64) { sendJson(res, 400, { error: "No image data" }); return true; }
    const filename = `${Date.now()}_${crypto.randomBytes(4).toString("hex")}.jpg`;
    fs.writeFileSync(path.join(IMAGE_DIR, filename), Buffer.from(base64, "base64"));
    const proto = req.headers["x-forwarded-proto"] || "https";
    const host = req.headers["x-forwarded-host"] || req.headers["host"];
    sendJson(res, 200, { url: `${proto}://${host}/api/images/${filename}` });
    return true;
  }

  if (url.pathname.startsWith("/api/images/") && req.method === "GET") {
    const filename = path.basename(url.pathname);
    const imagePath = path.join(IMAGE_DIR, filename);
    if (!fs.existsSync(imagePath)) { res.writeHead(404); res.end("Not Found"); return true; }
    const content = fs.readFileSync(imagePath);
    res.writeHead(200, { "content-type": "image/jpeg", "cache-control": "public, max-age=31536000, immutable" });
    res.end(content);
    return true;
  }

  if (url.pathname === "/api/listings" && req.method === "POST") {
    const body = await readJsonBody(req);
    const token = await resolveSessionToken(req);
    const listing = addListing(token, body);
    if (!listing) {
      sendJson(res, 401, { error: "Unauthorized" });
      return true;
    }
    sendJson(res, 200, { listing });
    return true;
  }

  if (url.pathname.startsWith("/api/listings/") && req.method === "DELETE") {
    const listingId = decodeURIComponent(url.pathname.split("/").pop());
    const token = await resolveSessionToken(req);
    const success = deleteListing(token, listingId);
    sendJson(res, success ? 200 : 403, { success });
    return true;
  }

  if (url.pathname.endsWith("/views") && req.method === "POST") {
    const segments = url.pathname.split("/");
    const listingId = decodeURIComponent(segments[3]);
    const listing = incrementViews(listingId);
    sendJson(res, listing ? 200 : 404, { listing });
    return true;
  }

  if (url.pathname === "/api/favorites/toggle" && req.method === "POST") {
    const body = await readJsonBody(req);
    const favorites = toggleFavorite(req.headers["x-session-token"] || "", body.listingId);
    if (!favorites) {
      sendJson(res, 401, { error: "Unauthorized" });
      return true;
    }
    sendJson(res, 200, { favorites });
    return true;
  }

  if (url.pathname === "/api/messages" && req.method === "POST") {
    const body = await readJsonBody(req);
    try {
      const message = sendMessage(req.headers["x-session-token"] || "", body);
      if (!message) {
        sendJson(res, 401, { error: "Unauthorized" });
        return true;
      }
      sendJson(res, 200, { message });
    } catch (error) {
      sendJson(res, error.statusCode || 400, { error: error.message || "Message failed" });
    }
    return true;
  }

  if (url.pathname === "/api/messages/seed" && req.method === "POST") {
    const body = await readJsonBody(req);
    const seeded = seedConversationOnce(req.headers["x-session-token"] || "", body);
    sendJson(res, 200, { message: seeded });
    return true;
  }

  return false;
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url || "/", `http://${req.headers.host}`);
  let pathname = url.pathname;

  Promise.resolve()
    .then(async () => {
      if (pathname.startsWith("/api/")) {
        const handled = await handleApi(req, res, url);
        if (handled) return;
      }

      if (basePath && pathname.startsWith(basePath)) {
        pathname = pathname.slice(basePath.length) || "/";
      }

      if (pathname === "/" || pathname === "/manifest") {
        const platform = req.headers["expo-platform"];
        if (platform === "ios" || platform === "android") {
          return serveManifest(platform, res);
        }

        if (pathname === "/") {
          return serveWebPage(req, res);
        }
      }

      serveStaticFile(pathname, res);
    })
    .catch((error) => {
      sendJson(res, 500, { error: error.message || "Internal Server Error" });
    });
});

const port = parseInt(process.env.PORT || "3000", 10);
server.listen(port, "0.0.0.0", () => {
  console.log(`Serving static Expo build on port ${port}`);
});
