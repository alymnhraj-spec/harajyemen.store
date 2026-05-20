const fs = require("fs");
const path = require("path");

const DB_PATH = path.resolve(__dirname, "db.json");
const MESSAGE_TTL_MS = 24 * 60 * 60 * 1000;
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
    createdAt: new Date(Date.now() - 86400000).toISOString(),
    views: 234,
    favorites: 45,
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
    createdAt: new Date(Date.now() - 172800000).toISOString(),
    views: 189,
    favorites: 23,
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
    createdAt: new Date(Date.now() - 3600000).toISOString(),
    views: 456,
    favorites: 67,
  },
  {
    id: "4",
    title: "أرض سكنية في تعز",
    description: "أرض سكنية 500 متر مربع، موقع مميز، جاهزة للبناء",
    price: 25000000,
    currency: "yer",
    priceType: "fixed",
    category: "real_estate",
    subcategory: "أراضي",
    governorate: "taiz",
    condition: "new",
    images: [],
    userId: "user4",
    userName: "عبدالله حسن",
    userPhone: "771345678",
    createdAt: new Date(Date.now() - 259200000).toISOString(),
    views: 123,
    favorites: 18,
  },
  {
    id: "5",
    title: "بقر هولشتاين للبيع",
    description: "3 رؤوس بقر هولشتاين عالية الإنتاج، مناسب للمزارع",
    price: 2000000,
    currency: "yer",
    priceType: "negotiable",
    category: "animals",
    subcategory: "مواشي",
    governorate: "dhamar",
    condition: "new",
    images: [],
    userId: "user7",
    userName: "حسن علي",
    userPhone: "777567890",
    createdAt: new Date(Date.now() - 518400000).toISOString(),
    views: 43,
    favorites: 7,
  },
  {
    id: "6",
    title: "خدمة صيانة مكيفات للمنازل والمكاتب",
    description: "خدمة صيانة وتنظيف مكيفات مع زيارة منزلية سريعة داخل أمانة العاصمة.",
    price: 30000,
    currency: "yer",
    priceType: "fixed",
    category: "services",
    subcategory: "صيانة",
    governorate: "sanaa",
    condition: "good",
    images: [],
    userId: "user9",
    userName: "خالد أحمد",
    userPhone: "770100606",
    createdAt: new Date(Date.now() - 28800000).toISOString(),
    views: 38,
    favorites: 5,
  },
];

function defaultDb() {
  return {
    users: [],
    listings: SAMPLE_LISTINGS,
    favoritesByUser: {},
    messages: [],
    seededConversations: {},
  };
}

function ensureDbFile() {
  if (!fs.existsSync(DB_PATH)) {
    fs.writeFileSync(DB_PATH, JSON.stringify(defaultDb(), null, 2), "utf-8");
  }
}

function readDb() {
  ensureDbFile();
  try {
    const raw = fs.readFileSync(DB_PATH, "utf-8");
    const parsed = JSON.parse(raw);
    return {
      ...defaultDb(),
      ...parsed,
      listings: Array.isArray(parsed.listings) ? parsed.listings : SAMPLE_LISTINGS,
      users: Array.isArray(parsed.users) ? parsed.users : [],
      messages: Array.isArray(parsed.messages) ? parsed.messages : [],
      favoritesByUser: parsed.favoritesByUser || {},
      seededConversations: parsed.seededConversations || {},
    };
  } catch {
    return defaultDb();
  }
}

function writeDb(db) {
  fs.writeFileSync(DB_PATH, JSON.stringify(db, null, 2), "utf-8");
}

function purgeExpiredMessages(db) {
  const cutoff = Date.now() - MESSAGE_TTL_MS;
  db.messages = db.messages.filter((message) => {
    return new Date(message.timestamp).getTime() >= cutoff;
  });
  return db;
}

function bootstrap(userId) {
  const db = purgeExpiredMessages(readDb());
  writeDb(db);
  return {
    currentUser: userId ? db.users.find((user) => user.id === userId) || null : null,
    users: db.users,
    listings: db.listings,
    favorites: userId ? db.favoritesByUser[userId] || [] : [],
    messages: userId
      ? db.messages.filter((message) => message.senderId === userId || message.receiverId === userId)
      : [],
  };
}

function signIn(phone, name) {
  const db = readDb();
  const cleanedPhone = String(phone || "").replace(/\D/g, "");
  const userId = `user_${cleanedPhone}`;
  const existing = db.users.find((user) => user.id === userId);
  const user = {
    id: userId,
    name: String(name || "").trim(),
    phone: cleanedPhone,
    avatar: existing?.avatar || "",
  };

  db.users = db.users.filter((entry) => entry.id !== userId);
  db.users.push(user);
  writeDb(db);
  return user;
}

function updateUser(userId, payload) {
  const db = readDb();
  const current = db.users.find((user) => user.id === userId);
  if (!current) return null;

  const nextUser = {
    ...current,
    ...(payload.name ? { name: String(payload.name).trim() } : {}),
    ...(payload.phone ? { phone: String(payload.phone).replace(/\D/g, "") } : {}),
    ...(payload.avatar !== undefined ? { avatar: payload.avatar || "" } : {}),
  };

  db.users = db.users.map((user) => (user.id === userId ? nextUser : user));
  db.listings = db.listings.map((listing) =>
    listing.userId === userId
      ? {
          ...listing,
          userName: nextUser.name,
          userPhone: nextUser.phone,
          userAvatar: nextUser.avatar || "",
        }
      : listing
  );
  writeDb(db);
  return nextUser;
}

function addListing(payload) {
  const db = readDb();
  const listing = {
    ...payload,
    id: `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    createdAt: new Date().toISOString(),
    views: 0,
    favorites: 0,
    userAvatar: payload.userAvatar || "",
  };
  db.listings.unshift(listing);
  writeDb(db);
  return listing;
}

function deleteListing(listingId, userId) {
  const db = readDb();
  const target = db.listings.find((listing) => String(listing.id) === String(listingId));
  if (!target) return false;
  if (userId && target.userId !== userId) return false;
  db.listings = db.listings.filter((listing) => String(listing.id) !== String(listingId));
  writeDb(db);
  return true;
}

function incrementViews(listingId) {
  const db = readDb();
  let updated = null;
  db.listings = db.listings.map((listing) => {
    if (String(listing.id) === String(listingId)) {
      updated = { ...listing, views: (listing.views || 0) + 1 };
      return updated;
    }
    return listing;
  });
  writeDb(db);
  return updated;
}

function toggleFavorite(userId, listingId) {
  const db = readDb();
  const current = db.favoritesByUser[userId] || [];
  const next = current.includes(String(listingId))
    ? current.filter((id) => id !== String(listingId))
    : [...current, String(listingId)];
  db.favoritesByUser[userId] = next;
  writeDb(db);
  return next;
}

function conversationKey(listingId, senderId, receiverId) {
  return `${listingId}__${[senderId, receiverId].sort().join("__")}`;
}

function sendMessage(payload) {
  const db = purgeExpiredMessages(readDb());
  if (payload.mediaType === "image") {
    const imagesInConversation = db.messages.filter((message) => {
      return (
        message.mediaType === "image" &&
        conversationKey(message.listingId, message.senderId, message.receiverId) ===
          conversationKey(payload.listingId, payload.senderId, payload.receiverId)
      );
    }).length;

    if (imagesInConversation >= MAX_CHAT_IMAGES_PER_CONVERSATION) {
      const error = new Error("الحد الأقصى لصور هذه المحادثة هو 3 صور.");
      error.statusCode = 400;
      throw error;
    }
  }

  const message = {
    id: `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    timestamp: new Date().toISOString(),
    isRead: false,
    mediaType: payload.mediaType || "text",
    ...payload,
  };
  db.messages.push(message);
  writeDb(db);
  return message;
}

function seedConversationOnce(payload) {
  const db = purgeExpiredMessages(readDb());
  const key = conversationKey(payload.listingId, payload.senderId, payload.receiverId);
  if (db.seededConversations[key]) {
    writeDb(db);
    return null;
  }

  db.seededConversations[key] = true;
  const message = {
    id: `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    timestamp: new Date().toISOString(),
    isRead: false,
    mediaType: "text",
    ...payload,
  };
  db.messages.push(message);
  writeDb(db);
  return message;
}

module.exports = {
  bootstrap,
  signIn,
  updateUser,
  addListing,
  deleteListing,
  incrementViews,
  toggleFavorite,
  sendMessage,
  seedConversationOnce,
};
