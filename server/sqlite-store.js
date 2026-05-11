const path = require("path");
const crypto = require("crypto");
const fs = require("fs");
const { DatabaseSync } = require("node:sqlite");

const DB_PATH = path.resolve(process.env.DB_PATH || path.join(__dirname, "db.sqlite"));
fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
const MESSAGE_TTL_MS = 24 * 60 * 60 * 1000;
const SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000;
const MAX_CHAT_IMAGES_PER_CONVERSATION = 3;

const SAMPLE_LISTINGS = [
  {
    id: "1",
    title: "تويوتا لاندكروزر 2020",
    description: "سيارة بحالة ممتازة، مسير قليل، لون أبيض، جميع الكماليات",
    price: 45000000,
    currency: "yer",
    priceType: "negotiable",
    category: "cars",
    subcategory: "سيارات مستعملة",
    governorate: "sanaa",
    condition: "like_new",
    images: [],
    userId: "user1",
    userName: "أحمد محمد",
    userPhone: "777123456",
    userAvatar: "",
    createdAt: new Date(Date.now() - 86400000).toISOString(),
    views: 234,
    favorites: 45,
    isFeatured: 0,
  },
  {
    id: "2",
    title: "شقة للإيجار في حدة - صنعاء",
    description: "شقة 3 غرف وصالة، الطابق الثالث، موقع مميز في حي حدة",
    price: 400000,
    currency: "yer",
    priceType: "fixed",
    category: "real_estate",
    subcategory: "شقق للإيجار",
    governorate: "sanaa",
    condition: "good",
    images: [],
    userId: "user2",
    userName: "محمد علي",
    userPhone: "712456789",
    userAvatar: "",
    createdAt: new Date(Date.now() - 172800000).toISOString(),
    views: 189,
    favorites: 23,
    isFeatured: 0,
  },
  {
    id: "3",
    title: "آيفون 15 برو ماكس",
    description: "آيفون 15 برو ماكس 256 جيجا، شريط طبيعي، ضمان عام",
    price: 1800000,
    currency: "yer",
    priceType: "negotiable",
    category: "electronics",
    subcategory: "هواتف",
    governorate: "aden",
    condition: "new",
    images: [],
    userId: "user3",
    userName: "سالم أحمد",
    userPhone: "733789012",
    userAvatar: "",
    createdAt: new Date(Date.now() - 3600000).toISOString(),
    views: 456,
    favorites: 67,
    isFeatured: 0,
  },
];

const db = new DatabaseSync(DB_PATH);
db.exec(`
  PRAGMA journal_mode = WAL;
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT DEFAULT '',
    avatar TEXT DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS sessions (
    token TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    expires_at TEXT NOT NULL,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
  );
  CREATE TABLE IF NOT EXISTS listings (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    price REAL NOT NULL,
    currency TEXT NOT NULL DEFAULT 'yer',
    price_type TEXT NOT NULL,
    category TEXT NOT NULL,
    subcategory TEXT,
    governorate TEXT NOT NULL,
    condition TEXT NOT NULL,
    images_json TEXT NOT NULL,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_phone TEXT,
    user_avatar TEXT DEFAULT '',
    created_at TEXT NOT NULL,
    views INTEGER NOT NULL DEFAULT 0,
    favorites INTEGER NOT NULL DEFAULT 0,
    is_featured INTEGER NOT NULL DEFAULT 0
  );
  CREATE TABLE IF NOT EXISTS favorites (
    user_id TEXT NOT NULL,
    listing_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    PRIMARY KEY (user_id, listing_id)
  );
  CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    listing_id TEXT NOT NULL,
    listing_title TEXT NOT NULL,
    sender_id TEXT NOT NULL,
    receiver_id TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    content TEXT NOT NULL,
    media_type TEXT NOT NULL DEFAULT 'text',
    timestamp TEXT NOT NULL,
    is_read INTEGER NOT NULL DEFAULT 0
  );
  CREATE TABLE IF NOT EXISTS seeded_conversations (
    conversation_key TEXT PRIMARY KEY,
    created_at TEXT NOT NULL
  );
`);
try { db.exec(`ALTER TABLE users ADD COLUMN email TEXT DEFAULT ''`); } catch {}

function nowIso() {
  return new Date().toISOString();
}

function makeId(prefix = "") {
  return `${prefix}${Date.now()}_${crypto.randomBytes(4).toString("hex")}`;
}

function normalizePhone(phone) {
  const arabicDigits = "٠١٢٣٤٥٦٧٨٩";
  const englishDigits = "0123456789";
  let normalized = String(phone || "")
    .split("")
    .map((char) => {
      const index = arabicDigits.indexOf(char);
      return index >= 0 ? englishDigits[index] : char;
    })
    .join("")
    .replace(/\D/g, "");

  if (normalized.startsWith("00967")) {
    normalized = normalized.slice(5);
  } else if (normalized.startsWith("967")) {
    normalized = normalized.slice(3);
  }

  if (normalized.length === 10 && normalized.startsWith("0")) {
    normalized = normalized.slice(1);
  }

  return normalized;
}

function rowToUser(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    phone: row.phone,
    email: row.email || "",
    avatar: row.avatar || "",
  };
}

function findUserByPhone(phone) {
  const cleanedPhone = normalizePhone(phone);
  if (!cleanedPhone) return null;
  const row = db.prepare("SELECT * FROM users WHERE phone = ?").get(cleanedPhone);
  return rowToUser(row);
}

function findUserByEmail(email) {
  const cleanEmail = String(email || "").trim().toLowerCase();
  if (!cleanEmail) return null;
  const row = db.prepare("SELECT * FROM users WHERE email = ?").get(cleanEmail);
  return rowToUser(row);
}

function signInWithEmail(email, name) {
  purgeExpired();
  const cleanEmail = String(email || "").trim().toLowerCase();
  const current = db.prepare("SELECT * FROM users WHERE email = ?").get(cleanEmail);
  const timestamp = nowIso();
  const userId = current?.id || makeId("user_");
  const incomingName = String(name || "").trim();

  if (current) {
    const nextName = incomingName || current.name;
    db.prepare("UPDATE users SET name = ?, updated_at = ? WHERE id = ?")
      .run(nextName, timestamp, userId);
  } else {
    db.prepare(`
      INSERT INTO users (id, name, phone, email, avatar, created_at, updated_at)
      VALUES (?, ?, '', ?, '', ?, ?)
    `).run(userId, incomingName, cleanEmail, timestamp, timestamp);
  }

  const user = rowToUser(db.prepare("SELECT * FROM users WHERE id = ?").get(userId));
  const sessionToken = createSession(userId);
  return { user, sessionToken };
}

function rowToListing(row) {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    price: row.price,
    currency: row.currency,
    priceType: row.price_type,
    category: row.category,
    subcategory: row.subcategory || "",
    governorate: row.governorate,
    condition: row.condition,
    images: JSON.parse(row.images_json || "[]"),
    userId: row.user_id,
    userName: row.user_name,
    userPhone: row.user_phone || "",
    userAvatar: row.user_avatar || "",
    createdAt: row.created_at,
    views: row.views || 0,
    favorites: row.favorites || 0,
    isFeatured: !!row.is_featured,
  };
}

function rowToMessage(row) {
  return {
    id: row.id,
    listingId: row.listing_id,
    listingTitle: row.listing_title,
    senderId: row.sender_id,
    receiverId: row.receiver_id,
    senderName: row.sender_name,
    content: row.content,
    mediaType: row.media_type,
    timestamp: row.timestamp,
    isRead: !!row.is_read,
  };
}

function seedListingsIfNeeded() {
  const count = db.prepare("SELECT COUNT(*) AS count FROM listings").get().count;
  if (count > 0) return;

  const insert = db.prepare(`
    INSERT INTO listings (
      id, title, description, price, currency, price_type, category, subcategory, governorate, condition,
      images_json, user_id, user_name, user_phone, user_avatar, created_at, views, favorites, is_featured
    ) VALUES (
      @id, @title, @description, @price, @currency, @priceType, @category, @subcategory, @governorate, @condition,
      @imagesJson, @userId, @userName, @userPhone, @userAvatar, @createdAt, @views, @favorites, @isFeatured
    )
  `);

  for (const listing of SAMPLE_LISTINGS) {
    insert.run({
      id: listing.id,
      title: listing.title,
      description: listing.description,
      price: listing.price,
      currency: listing.currency,
      priceType: listing.priceType,
      category: listing.category,
      subcategory: listing.subcategory,
      governorate: listing.governorate,
      condition: listing.condition,
      userId: listing.userId,
      userName: listing.userName,
      userPhone: listing.userPhone,
      userAvatar: listing.userAvatar,
      createdAt: listing.createdAt,
      views: listing.views,
      favorites: listing.favorites,
      isFeatured: listing.isFeatured,
      imagesJson: JSON.stringify(listing.images || []),
    });
  }
}

function purgeExpired() {
  db.prepare("DELETE FROM messages WHERE timestamp < ?").run(new Date(Date.now() - MESSAGE_TTL_MS).toISOString());
  db.prepare("DELETE FROM sessions WHERE expires_at < ?").run(nowIso());
}

function getSessionUser(token) {
  if (!token) return null;
  purgeExpired();
  const row = db.prepare(`
    SELECT u.* FROM sessions s
    JOIN users u ON u.id = s.user_id
    WHERE s.token = ?
  `).get(token);
  return rowToUser(row);
}

function createSession(userId) {
  const token = crypto.randomBytes(24).toString("hex");
  db.prepare(`
    INSERT INTO sessions (token, user_id, created_at, expires_at)
    VALUES (?, ?, ?, ?)
  `).run(token, userId, nowIso(), new Date(Date.now() + SESSION_TTL_MS).toISOString());
  return token;
}

function signIn(phone, name) {
  purgeExpired();
  const cleanedPhone = normalizePhone(phone);
  const current = db.prepare("SELECT * FROM users WHERE phone = ?").get(cleanedPhone);
  const timestamp = nowIso();
  const userId = current?.id || makeId("user_");
  const incomingName = String(name || "").trim();

  if (current) {
    const nextName = incomingName || current.name;
    db.prepare("UPDATE users SET name = ?, phone = ?, updated_at = ? WHERE id = ?")
      .run(nextName, cleanedPhone, timestamp, userId);
  } else {
    db.prepare(`
      INSERT INTO users (id, name, phone, avatar, created_at, updated_at)
      VALUES (?, ?, ?, '', ?, ?)
    `).run(userId, incomingName, cleanedPhone, timestamp, timestamp);
  }

  const user = rowToUser(db.prepare("SELECT * FROM users WHERE id = ?").get(userId));
  const sessionToken = createSession(userId);
  return { user, sessionToken };
}

function signOut(sessionToken) {
  if (!sessionToken) return;
  db.prepare("DELETE FROM sessions WHERE token = ?").run(sessionToken);
}

function updateUser(sessionToken, payload) {
  const currentUser = getSessionUser(sessionToken);
  if (!currentUser) return null;
  const nextPhone = payload.phone ? normalizePhone(payload.phone) : currentUser.phone;
  const conflict = db.prepare("SELECT id FROM users WHERE phone = ? AND id <> ?").get(nextPhone, currentUser.id);
  if (conflict) {
    const error = new Error("رقم الجوال مستخدم في حساب آخر.");
    error.statusCode = 409;
    throw error;
  }
  const next = {
    name: payload.name ? String(payload.name).trim() : currentUser.name,
    phone: nextPhone,
    avatar: payload.avatar !== undefined ? payload.avatar || "" : currentUser.avatar || "",
  };

  db.prepare("UPDATE users SET name = ?, phone = ?, avatar = ?, updated_at = ? WHERE id = ?")
    .run(next.name, next.phone, next.avatar, nowIso(), currentUser.id);

  db.prepare(`
    UPDATE listings
    SET user_name = ?, user_phone = ?, user_avatar = ?
    WHERE user_id = ?
  `).run(next.name, next.phone, next.avatar, currentUser.id);

  return rowToUser(db.prepare("SELECT * FROM users WHERE id = ?").get(currentUser.id));
}

function bootstrap(sessionToken) {
  purgeExpired();
  const currentUser = getSessionUser(sessionToken);
  const users = db.prepare("SELECT * FROM users ORDER BY datetime(updated_at) DESC").all().map(rowToUser);
  const listings = db.prepare("SELECT * FROM listings ORDER BY datetime(created_at) DESC").all().map(rowToListing);
  const favorites = currentUser
    ? db.prepare("SELECT listing_id FROM favorites WHERE user_id = ?").all(currentUser.id).map((row) => row.listing_id)
    : [];
  const messages = currentUser
    ? db.prepare(`
        SELECT * FROM messages
        WHERE sender_id = ? OR receiver_id = ?
        ORDER BY datetime(timestamp) ASC
      `).all(currentUser.id, currentUser.id).map(rowToMessage)
    : [];

  return {
    currentUser,
    users,
    listings,
    favorites,
    messages,
  };
}

function getListings() {
  const rows = db.prepare("SELECT * FROM listings WHERE status != 'deleted' ORDER BY created_at DESC LIMIT 200").all();
  return rows.map(rowToListing);
}

function addListing(sessionToken, payload) {
  const currentUser = getSessionUser(sessionToken);
  if (!currentUser) return null;
  const listing = {
    id: makeId("listing_"),
    title: payload.title,
    description: payload.description,
    price: Number(payload.price) || 0,
    currency: payload.currency || "yer",
    priceType: payload.priceType || "fixed",
    category: payload.category || "",
    subcategory: payload.subcategory || "",
    governorate: payload.governorate || "",
    condition: payload.condition || "good",
    images: Array.isArray(payload.images) ? payload.images : [],
    userId: currentUser.id,
    userName: currentUser.name,
    userPhone: currentUser.phone,
    userAvatar: currentUser.avatar || "",
    createdAt: nowIso(),
    views: 0,
    favorites: 0,
    isFeatured: 0,
  };

  db.prepare(`
    INSERT INTO listings (
      id, title, description, price, currency, price_type, category, subcategory, governorate, condition,
      images_json, user_id, user_name, user_phone, user_avatar, created_at, views, favorites, is_featured
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0)
  `).run(
    listing.id,
    listing.title,
    listing.description,
    listing.price,
    listing.currency,
    listing.priceType,
    listing.category,
    listing.subcategory,
    listing.governorate,
    listing.condition,
    JSON.stringify(listing.images),
    listing.userId,
    listing.userName,
    listing.userPhone,
    listing.userAvatar,
    listing.createdAt
  );

  return listing;
}

function deleteListing(sessionToken, listingId) {
  const currentUser = getSessionUser(sessionToken);
  if (!currentUser) return false;
  const listing = db.prepare("SELECT user_id FROM listings WHERE id = ?").get(String(listingId));
  if (!listing || listing.user_id !== currentUser.id) return false;
  db.prepare("DELETE FROM listings WHERE id = ?").run(String(listingId));
  db.prepare("DELETE FROM favorites WHERE listing_id = ?").run(String(listingId));
  return true;
}

function incrementViews(listingId) {
  db.prepare("UPDATE listings SET views = views + 1 WHERE id = ?").run(String(listingId));
  const row = db.prepare("SELECT * FROM listings WHERE id = ?").get(String(listingId));
  return row ? rowToListing(row) : null;
}

function toggleFavorite(sessionToken, listingId) {
  const currentUser = getSessionUser(sessionToken);
  if (!currentUser) return null;
  const exists = db.prepare("SELECT 1 FROM favorites WHERE user_id = ? AND listing_id = ?").get(currentUser.id, String(listingId));
  if (exists) {
    db.prepare("DELETE FROM favorites WHERE user_id = ? AND listing_id = ?").run(currentUser.id, String(listingId));
  } else {
    db.prepare("INSERT INTO favorites (user_id, listing_id, created_at) VALUES (?, ?, ?)").run(currentUser.id, String(listingId), nowIso());
  }
  return db.prepare("SELECT listing_id FROM favorites WHERE user_id = ?").all(currentUser.id).map((row) => row.listing_id);
}

function getConversationImageCount(listingId, senderId, receiverId) {
  const keyA = [senderId, receiverId].sort().join("__");
  return db.prepare(`
    SELECT COUNT(*) AS count
    FROM messages
    WHERE listing_id = ?
      AND media_type = 'image'
      AND (
        (sender_id = ? AND receiver_id = ?) OR
        (sender_id = ? AND receiver_id = ?)
      )
  `).get(String(listingId), senderId, receiverId, receiverId, senderId).count;
}

function sendMessage(sessionToken, payload) {
  const currentUser = getSessionUser(sessionToken);
  if (!currentUser) return null;

  if (payload.mediaType === "image" && getConversationImageCount(payload.listingId, currentUser.id, payload.receiverId) >= MAX_CHAT_IMAGES_PER_CONVERSATION) {
    const error = new Error("الحد الأقصى لصور هذه المحادثة هو 3 صور.");
    error.statusCode = 400;
    throw error;
  }

  const message = {
    id: makeId("msg_"),
    listingId: String(payload.listingId),
    listingTitle: payload.listingTitle,
    senderId: currentUser.id,
    receiverId: payload.receiverId,
    senderName: currentUser.name,
    content: payload.content,
    mediaType: payload.mediaType || "text",
    timestamp: nowIso(),
    isRead: false,
  };

  db.prepare(`
    INSERT INTO messages (
      id, listing_id, listing_title, sender_id, receiver_id, sender_name, content, media_type, timestamp, is_read
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
  `).run(
    message.id,
    message.listingId,
    message.listingTitle,
    message.senderId,
    message.receiverId,
    message.senderName,
    message.content,
    message.mediaType,
    message.timestamp
  );

  return message;
}

function seedConversationOnce(sessionToken, payload) {
  const currentUser = getSessionUser(sessionToken);
  if (!currentUser) return null;
  const key = `${payload.listingId}__${[payload.senderId, payload.receiverId].sort().join("__")}`;
  const existing = db.prepare("SELECT 1 FROM seeded_conversations WHERE conversation_key = ?").get(key);
  if (existing) return null;

  db.prepare("INSERT INTO seeded_conversations (conversation_key, created_at) VALUES (?, ?)").run(key, nowIso());
  db.prepare(`
    INSERT INTO messages (
      id, listing_id, listing_title, sender_id, receiver_id, sender_name, content, media_type, timestamp, is_read
    ) VALUES (?, ?, ?, ?, ?, ?, ?, 'text', ?, 0)
  `).run(
    makeId("msg_"),
    String(payload.listingId),
    payload.listingTitle,
    payload.senderId,
    currentUser.id,
    payload.senderName,
    payload.content,
    nowIso()
  );
  return true;
}

seedListingsIfNeeded();

module.exports = {
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
};
