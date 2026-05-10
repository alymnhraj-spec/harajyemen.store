// Haraj Yemen Web App Logic

const YEMEN_GOVERNORATES = [
    { id: "all", name: "كل المحافظات" },
    { id: "sanaa", name: "أمانة العاصمة صنعاء" },
    { id: "sanaa_gov", name: "صنعاء" },
    { id: "aden", name: "عدن" },
    { id: "taiz", name: "تعز" },
    { id: "hodeidah", name: "الحديدة" },
    { id: "ibb", name: "إب" },
    { id: "hadramout", name: "حضرموت" },
    { id: "marib", name: "مأرب" },
    { id: "hajjah", name: "حجة" },
    { id: "dhamar", name: "ذمار" },
    { id: "shabwah", name: "شبوة" },
    { id: "lahij", name: "لحج" },
    { id: "al_baydha", name: "البيضاء" },
    { id: "abyan", name: "أبين" },
    { id: "al_jawf", name: "الجوف" },
    { id: "al_mahwit", name: "المحويت" },
    { id: "saada", name: "صعدة" },
    { id: "amran", name: "عمران" },
    { id: "al_dale", name: "الضالع" },
    { id: "al_mahrah", name: "المهرة" },
    { id: "raymah", name: "ريمة" },
    { id: "soqotra", name: "سقطرى" },
];

const GOVERNORATE_COORDINATES = {
    sanaa: { lat: 15.3694, lng: 44.1910 },
    sanaa_gov: { lat: 15.3547, lng: 44.2067 },
    aden: { lat: 12.7855, lng: 45.0187 },
    taiz: { lat: 13.5795, lng: 44.0209 },
    hodeidah: { lat: 14.7978, lng: 42.9545 },
    ibb: { lat: 13.9667, lng: 44.1833 },
    hadramout: { lat: 15.9229, lng: 48.6258 },
    marib: { lat: 15.4625, lng: 45.3258 },
    hajjah: { lat: 15.6917, lng: 43.6053 },
    dhamar: { lat: 14.5425, lng: 44.4051 },
    shabwah: { lat: 14.5294, lng: 46.8319 },
    lahij: { lat: 13.0567, lng: 44.8819 },
    al_baydha: { lat: 13.9852, lng: 45.5727 },
    abyan: { lat: 13.6343, lng: 46.0563 },
    al_jawf: { lat: 16.7902, lng: 45.2994 },
    al_mahwit: { lat: 15.4701, lng: 43.5448 },
    saada: { lat: 16.9402, lng: 43.7639 },
    amran: { lat: 15.6594, lng: 43.9439 },
    al_dale: { lat: 13.6957, lng: 44.7314 },
    al_mahrah: { lat: 16.6615, lng: 51.1744 },
    raymah: { lat: 14.6949, lng: 43.5872 },
    soqotra: { lat: 12.4634, lng: 53.8237 },
};

const CATEGORIES = [
    { id: "cars", name: "سيارات", icon: "car", subcategories: ["سيارات جديدة", "سيارات مستعملة", "دراجات نارية", "قطع غيار"] },
    { id: "real_estate", name: "عقارات", icon: "house", subcategories: ["شقق للبيع", "شقق للإيجار", "أراضي", "فلل ومنازل", "محلات تجارية"] },
    { id: "electronics", name: "إلكترونيات", icon: "mobile-screen", subcategories: ["هواتف", "أجهزة لوحية", "كمبيوترات", "شاشات", "كاميرات"] },
    { id: "furniture", name: "أثاث ومنزل", icon: "couch", subcategories: ["غرف نوم", "صالات", "مطابخ", "ديكور", "أجهزة منزلية"] },
    { id: "fashion", name: "ملابس وأزياء", icon: "shirt", subcategories: ["رجالي", "نسائي", "أطفال", "أحذية", "حقائب"] },
    { id: "jobs", name: "وظائف", icon: "briefcase", subcategories: ["وظائف حكومية", "قطاع خاص", "عمل حر", "تدريب"] },
    { id: "animals", name: "حيوانات", icon: "paw", subcategories: ["مواشي", "طيور", "حيوانات أليفة"] },
    { id: "agriculture", name: "زراعة ومزارع", icon: "seedling", subcategories: ["أراضي زراعية", "معدات زراعية", "محاصيل"] },
    { id: "services", name: "خدمات", icon: "screwdriver-wrench", subcategories: ["صيانة", "نقل", "تعليم", "تصميم", "مطاعم"] },
    { id: "sports", name: "رياضة وترفيه", icon: "dumbbell", subcategories: ["أجهزة رياضية", "ألعاب", "كتب"] },
];

const PRICE_TYPES = [
    { id: "fixed", name: "سعر ثابت" },
    { id: "negotiable", name: "قابل للتفاوض" },
    { id: "free", name: "مجاناً" },
    { id: "exchange", name: "للمبادلة" },
];

const CURRENCIES = [
    { id: "yer", name: "ريال يمني", symbol: "ر.ي" },
    { id: "usd", name: "دولار", symbol: "$" },
    { id: "sar", name: "ريال سعودي", symbol: "ر.س" },
];

const CONDITION_TYPES = [
    { id: "new", name: "جديد" },
    { id: "like_new", name: "شبه جديد" },
    { id: "good", name: "حالة جيدة" },
    { id: "acceptable", name: "حالة مقبولة" },
];

// ===== Firebase =====
firebase.initializeApp({
    apiKey: "AIzaSyD5RSQ2Z3rVJt3cwPrXI34muFh1d6HMG1w",
    authDomain: "haraj-yemen-app.firebaseapp.com",
    projectId: "haraj-yemen-app",
    storageBucket: "haraj-yemen-app.firebasestorage.app",
    messagingSenderId: "119432231710",
    appId: "1:119432231710:web:20186535e0be5c61cf270f",
});
const fbAuth = firebase.auth();
const fbDb = firebase.firestore();
const fbStorage = firebase.storage();

function getFirebaseErrorMessage(code) {
    const msgs = {
        "auth/user-not-found": "البريد الإلكتروني غير مسجل.",
        "auth/wrong-password": "كلمة المرور غير صحيحة.",
        "auth/invalid-credential": "البريد أو كلمة المرور غير صحيحة.",
        "auth/invalid-login-credentials": "البريد أو كلمة المرور غير صحيحة.",
        "auth/email-already-in-use": "هذا البريد الإلكتروني مسجل بالفعل.",
        "auth/weak-password": "كلمة المرور ضعيفة، يجب أن تكون 6 أحرف على الأقل.",
        "auth/invalid-email": "البريد الإلكتروني غير صحيح.",
        "auth/too-many-requests": "تم تجاوز عدد المحاولات. حاول لاحقًا.",
        "auth/network-request-failed": "خطأ في الاتصال بالإنترنت. حاول مرة أخرى.",
        "auth/user-disabled": "هذا الحساب موقوف.",
        "auth/operation-not-allowed": "تسجيل الدخول بالإيميل غير مفعّل.",
    };
    return msgs[code] || `خطأ: ${code || "غير معروف"}`;
}

const listingsContainer = document.getElementById("listingsContainer");
const categoriesList = document.getElementById("categoriesList");
const subcategoriesBar = document.getElementById("subcategoriesBar");
const subcategoriesList = document.getElementById("subcategoriesList");
const marketToolbar = document.getElementById("marketToolbar");
const listingPage = document.getElementById("listingPage");
const listingPageBody = document.getElementById("listingPageBody");
const listingBackBtn = document.getElementById("listingBackBtn");
const loader = document.getElementById("loader");
const regionFilter = document.getElementById("regionFilter");
const nearbyToggleBtn = document.getElementById("nearbyToggleBtn");
const saveSearchBtn = document.getElementById("saveSearchBtn");
const resultsTitle = document.getElementById("resultsTitle");
const favoritesTrigger = document.getElementById("favoritesTrigger");
const authModal = document.getElementById("authModal");
const closeAuthModal = document.getElementById("closeAuthModal");
const authTrigger = document.getElementById("authTrigger");
const authTriggerText = document.getElementById("authTriggerText");
const authForm = document.getElementById("authForm");
const authSuccessState = document.getElementById("authSuccessState");
const authTitle = document.getElementById("authTitle");
const authDescription = document.getElementById("authDescription");
const authError = document.getElementById("authError");
const emailInput = document.getElementById("emailInput");
const passwordInput = document.getElementById("passwordInput");
const confirmPasswordInput = document.getElementById("confirmPasswordInput");
const nameInput = document.getElementById("nameInput");
const authNameWrap = document.getElementById("authNameWrap");
const authConfirmWrap = document.getElementById("authConfirmWrap");
const authSubmitBtn = document.getElementById("authSubmitBtn");
const loginTabBtn = document.getElementById("loginTabBtn");
const registerTabBtn = document.getElementById("registerTabBtn");
const forgotPasswordBtn = document.getElementById("forgotPasswordBtn");
const closeAuthSuccessBtn = document.getElementById("closeAuthSuccessBtn");
const logoutBtn = document.getElementById("logoutBtn");
const authSuccessName = document.getElementById("authSuccessName");
const authSuccessPhone = document.getElementById("authSuccessPhone");
const authRequiredTriggers = document.querySelectorAll("[data-auth-trigger]");
const messagesTrigger = document.getElementById("messagesTrigger");
const messagesModal = document.getElementById("messagesModal");
const closeMessagesModal = document.getElementById("closeMessagesModal");
const messagesAuthBtn = document.getElementById("messagesAuthBtn");
const messagesEmptyState = document.getElementById("messagesEmptyState");
const messagesList = document.getElementById("messagesList");
const messagesSubtitle = document.getElementById("messagesSubtitle");
const chatView = document.getElementById("chatView");
const backToMessagesBtn = document.getElementById("backToMessagesBtn");
const chatTitle = document.getElementById("chatTitle");
const chatMeta = document.getElementById("chatMeta");
const chatMessages = document.getElementById("chatMessages");
const chatForm = document.getElementById("chatForm");
const chatInput = document.getElementById("chatInput");
const chatImageInput = document.getElementById("chatImageInput");
const chatRecordBtn = document.getElementById("chatRecordBtn");
const chatRecordBtnText = document.getElementById("chatRecordBtnText");
const chatStatus = document.getElementById("chatStatus");
const favoritesModal = document.getElementById("favoritesModal");
const closeFavoritesModalBtn = document.getElementById("closeFavoritesModal");
const favoritesEmptyState = document.getElementById("favoritesEmptyState");
const favoritesList = document.getElementById("favoritesList");
const profileModal = document.getElementById("profileModal");
const closeProfileModalBtn = document.getElementById("closeProfileModal");
const profileAvatar = document.getElementById("profileAvatar");
const profileAvatarInput = document.getElementById("profileAvatarInput");
const profileName = document.getElementById("profileName");
const profilePhone = document.getElementById("profilePhone");
const profileNameInput = document.getElementById("profileNameInput");
const profilePhoneInput = document.getElementById("profilePhoneInput");
const saveProfileBtn = document.getElementById("saveProfileBtn");
const logoutProfileBtn = document.getElementById("logoutProfileBtn");
const profileError = document.getElementById("profileError");
const profileListingsEmpty = document.getElementById("profileListingsEmpty");
const profileListingsList = document.getElementById("profileListingsList");
const postModal = document.getElementById("postModal");
const closePostModal = document.getElementById("closePostModal");
const postForm = document.getElementById("postForm");
const postTitle = document.getElementById("postTitle");
const postPrice = document.getElementById("postPrice");
const postCurrency = document.getElementById("postCurrency");
const postLocation = document.getElementById("postLocation");
const postCategory = document.getElementById("postCategory");
const postSubcategory = document.getElementById("postSubcategory");
const postPriceType = document.getElementById("postPriceType");
const postCondition = document.getElementById("postCondition");
const postDescription = document.getElementById("postDescription");
const postImage = document.getElementById("postImage");
const postImagePreview = document.getElementById("postImagePreview");
const cancelPostBtn = document.getElementById("cancelPostBtn");
const postError = document.getElementById("postError");
const submitPostBtn = document.getElementById("submitPostBtn");
const publishAgreementModal = document.getElementById("publishAgreementModal");
const closeAgreementModal = document.getElementById("closeAgreementModal");
const agreementCheckbox = document.getElementById("agreementCheckbox");
const cancelAgreementBtn = document.getElementById("cancelAgreementBtn");
const confirmAgreementBtn = document.getElementById("confirmAgreementBtn");
const agreementError = document.getElementById("agreementError");
const imageLightboxModal = document.getElementById("imageLightboxModal");
const imageLightboxTarget = document.getElementById("imageLightboxTarget");
const closeImageLightboxBtn = document.getElementById("closeImageLightbox");

const AUTH_STORAGE_KEY = "haraj_web_auth_user";
const MESSAGE_TTL_MS = 24 * 60 * 60 * 1000;
const MAX_CHAT_IMAGES_PER_CONVERSATION = 3;
const API_BASE = `${window.location.origin}/api`;
const PROHIBITED_AD_TERMS = [
    "سكس",
    "اعلان سكس",
    "إعلان سكس",
    "محتوى سكس",
    "نيك",
    "عراب",
    "كس",
    "امك",
    "أمك",
    "تبغ",
    "سجائر",
    "دخان",
    "شيشة",
    "فيب",
    "vape",
    "مخدرات",
    "مخدر",
    "حشيش",
    "هيروين",
    "كوكايين",
    "قات",
    "القات",
    "جنسي",
    "جنس",
    "محتوى جنسي",
    "عري",
    "إباحي",
    "اباحي",
    "الولعه",
    "ولعة",
    "ولاعة",
    "ولاعات"
];

function normalizeArabicText(text) {
    return String(text || "")
        .toLowerCase()
        .replace(/[\u064B-\u065F\u0670]/g, "")
        .replace(/[أإآ]/g, "ا")
        .replace(/ة/g, "ه")
        .replace(/ى/g, "ي")
        .replace(/ؤ/g, "و")
        .replace(/ئ/g, "ي")
        .replace(/[^a-z0-9\u0621-\u064A]+/g, " ")
        .replace(/\s+/g, " ")
        .trim();
}

function hasRequiredFullName(name) {
    const parts = String(name || "")
        .trim()
        .split(/\s+/)
        .filter(Boolean);

    return parts.length >= 2 && parts.every((part) => part.length >= 2);
}

function getCurrencyMeta(currencyId = "yer") {
    return CURRENCIES.find((item) => item.id === currencyId) || CURRENCIES[0];
}

function formatPrice(price, priceType = "fixed", currency = "yer") {
    if (priceType === "free") return "مجاني";
    if (priceType === "exchange") return "مبادلة";
    const numeric = Number(price) || 0;
    const currentCurrency = getCurrencyMeta(currency);
    return `${numeric.toLocaleString("en-US")} ${currentCurrency.symbol}`;
}

function getGovernorateLabel(id) {
    const gov = YEMEN_GOVERNORATES.find((item) => item.id === id);
    if (!gov) return id || "";
    return gov.name === "أمانة العاصمة صنعاء" ? "صنعاء" : gov.name;
}

function getCategoryLabel(id) {
    return CATEGORIES.find((item) => item.id === id)?.name || id || "";
}

function getCategoryById(id) {
    return CATEGORIES.find((item) => item.id === id) || null;
}

function timeAgo(dateStr) {
    const now = Date.now();
    const date = new Date(dateStr).getTime();
    const diff = now - date;
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);
    if (minutes < 1) return "الآن";
    if (minutes < 60) return `منذ ${minutes} دقيقة`;
    if (hours < 24) return `منذ ${hours} ساعة`;
    if (days < 7) return `منذ ${days} يوم`;
    return new Date(dateStr).toLocaleDateString("ar-YE");
}

function getDistanceInKm(from, to) {
    if (!from || !to) return Number.POSITIVE_INFINITY;
    const toRad = (value) => (value * Math.PI) / 180;
    const earthRadiusKm = 6371;
    const latDiff = toRad(to.lat - from.lat);
    const lngDiff = toRad(to.lng - from.lng);
    const a =
        Math.sin(latDiff / 2) * Math.sin(latDiff / 2) +
        Math.cos(toRad(from.lat)) * Math.cos(toRad(to.lat)) *
        Math.sin(lngDiff / 2) * Math.sin(lngDiff / 2);
    return earthRadiusKm * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

function getNearestGovernorateId(coords) {
    let nearestId = "";
    let nearestDistance = Number.POSITIVE_INFINITY;

    Object.entries(GOVERNORATE_COORDINATES).forEach(([id, point]) => {
        const distance = getDistanceInKm(coords, point);
        if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestId = id;
        }
    });

    return nearestId;
}

function requestNearbyLocation() {
    return new Promise((resolve, reject) => {
        if (!navigator.geolocation) {
            reject(new Error("المتصفح لا يدعم تحديد الموقع."));
            return;
        }

        navigator.geolocation.getCurrentPosition(
            (position) => {
                const coords = {
                    lat: position.coords.latitude,
                    lng: position.coords.longitude,
                };
                userCoordinates = coords;
                nearestGovernorateId = getNearestGovernorateId(coords);
                resolve(coords);
            },
            () => {
                reject(new Error("تعذر الوصول إلى موقعك الجغرافي."));
            },
            { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 }
        );
    });
}

let authMode = "login";
let pendingOtpEmail = "";
let pendingOtpFirebaseUser = null;
let forgotPasswordMode = false;
let postImageDataUrls = [];
let activeConversationId = null;
let activeConversationMeta = null;
let mediaRecorder = null;
let recordingStream = null;
let audioChunks = [];
let nearbyOnly = false;
let pendingPostDraft = null;
let userCoordinates = null;
let nearestGovernorateId = "";
let unsubscribeMessages = null;
let unsubscribeInbox = null;
let remoteState = {
    listings: [],
    favorites: [],
    messages: [],
};
let remoteStateReady = false;

async function apiRequest(path, options = {}) {
    const sessionToken = getStoredUser()?.sessionToken;
    const response = await fetch(`${API_BASE}${path}`, {
        headers: {
            "content-type": "application/json",
            ...(sessionToken ? { "x-session-token": sessionToken } : {}),
            ...(options.headers || {}),
        },
        ...options,
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
        throw new Error(payload?.error || "Request failed");
    }
    return payload;
}

function parseFirestoreValue(val) {
    if (val == null) return null;
    if ("stringValue" in val) return val.stringValue;
    if ("integerValue" in val) return parseInt(val.integerValue, 10);
    if ("doubleValue" in val) return val.doubleValue;
    if ("booleanValue" in val) return val.booleanValue;
    if ("timestampValue" in val) return val.timestampValue;
    if ("nullValue" in val) return null;
    if ("arrayValue" in val) return (val.arrayValue.values || []).map(parseFirestoreValue);
    if ("mapValue" in val) {
        const obj = {};
        for (const [k, v] of Object.entries(val.mapValue.fields || {})) {
            obj[k] = parseFirestoreValue(v);
        }
        return obj;
    }
    return null;
}

function parseFirestoreDoc(doc) {
    const id = doc.name.split("/").pop();
    const result = { id };
    for (const [key, val] of Object.entries(doc.fields || {})) {
        result[key] = parseFirestoreValue(val);
    }
    return result;
}

function sortListingsByDate(listings) {
    return listings.sort((a, b) => {
        const getTs = (item) => {
            const ts = item.created_at || item.createdAt;
            if (!ts) return 0;
            if (ts?.toDate) return ts.toDate().getTime();
            return new Date(ts).getTime();
        };
        return getTs(b) - getTs(a);
    });
}

async function refreshRemoteState() {
    let loaded = false;

    try {
        const url = `https://firestore.googleapis.com/v1/projects/haraj-yemen-app/databases/(default)/documents/posts?pageSize=200&key=AIzaSyD5RSQ2Z3rVJt3cwPrXI34muFh1d6HMG1w`;
        const resp = await fetch(url);
        if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
        const data = await resp.json();
        const docs = (data.documents || []).map(parseFirestoreDoc);
        remoteState.listings = sortListingsByDate(
            docs.filter((item) => item.status !== "deleted" && !item.deleted_by_admin)
        );
        loaded = true;
    } catch (_) {}

    if (!loaded) {
        try {
            const snapshot = await fbDb.collection("posts").limit(200).get();
            remoteState.listings = sortListingsByDate(
                snapshot.docs
                    .map((doc) => ({ id: doc.id, ...doc.data() }))
                    .filter((item) => item.status !== "deleted" && !item.deleted_by_admin)
            );
        } catch (sdkErr) {
            console.error("refreshRemoteState error:", sdkErr);
        }
    }

    const user = getStoredUser();
    if (user?.id) {
        remoteState.favorites = JSON.parse(localStorage.getItem(`haraj_favs_${user.id}`) || "[]");
    }

    remoteStateReady = true;
    return remoteState;
}

function setChatStatus(message = "") {
    chatStatus.textContent = message;
    chatStatus.classList.toggle("hidden", !message);
}

function stopRecordingStream() {
    if (recordingStream) {
        recordingStream.getTracks().forEach((track) => track.stop());
        recordingStream = null;
    }
}

function resetRecorderUi() {
    chatRecordBtn.classList.remove("recording");
    chatRecordBtnText.textContent = "تسجيل";
}

function getStoredUser() {
    try {
        const raw = localStorage.getItem(AUTH_STORAGE_KEY);
        return raw ? JSON.parse(raw) : null;
    } catch {
        return null;
    }
}

function setStoredUser(user) {
    localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(user));
}

function clearStoredUser() {
    localStorage.removeItem(AUTH_STORAGE_KEY);
}

async function handleClientLogout() {
    await fbAuth.signOut().catch(() => {});
    clearStoredUser();
    if (emailInput) emailInput.value = "";
    if (passwordInput) passwordInput.value = "";
    if (nameInput) nameInput.value = "";
    remoteState = { listings: [], favorites: [], messages: [] };
    remoteStateReady = false;
    updateAuthNav();
    setAuthMode("login");
    closeMessages();

    const params = new URLSearchParams(window.location.search);
    const listingId = params.get("listing");
    if (listingId) {
        const listing = getListingById(listingId);
        if (listing) {
            renderListingPage(listing);
            return;
        }
    }

    renderCurrentListings();
}

function renderProfileAvatarElement(user) {
    if (!profileAvatar) return;

    const hasImage = !!user?.avatar;
    profileAvatar.classList.toggle("has-image", hasImage);

    if (hasImage) {
        profileAvatar.style.backgroundImage = `url("${user.avatar}")`;
        profileAvatar.textContent = "";
        return;
    }

    profileAvatar.style.backgroundImage = "";
    profileAvatar.textContent = user?.name?.charAt(0) || "م";
}

function getStoredFavorites() {
    const user = getStoredUser();
    if (!user?.id) return [];
    try {
        return JSON.parse(localStorage.getItem(`haraj_favs_${user.id}`) || "[]");
    } catch { return []; }
}

function setStoredFavorites(items) {
    remoteState.favorites = Array.isArray(items) ? items.map(String) : [];
    const user = getStoredUser();
    if (user?.id) {
        localStorage.setItem(`haraj_favs_${user.id}`, JSON.stringify(remoteState.favorites));
    }
}

// ===== Firebase Chat =====

async function getOrCreateConversation(item) {
    const currentUser = getStoredUser();
    const otherUserId = item.user_id || item.userId;
    if (!otherUserId || otherUserId === currentUser.id) return null;

    const snapshot = await fbDb.collection("conversations")
        .where("participants", "array-contains", currentUser.id)
        .get();

    const existing = snapshot.docs.find((doc) => {
        const data = doc.data();
        return (
            Array.isArray(data.participants) &&
            data.participants.includes(otherUserId) &&
            (data.post_id === item.id || data.last_post_title === item.title)
        );
    });

    if (existing) return existing.id;

    const firstImage = (Array.isArray(item.images) ? item.images[0] : null) || "";
    const ref = await fbDb.collection("conversations").add({
        participants: [currentUser.id, otherUserId],
        post_id: item.id,
        last_post_title: item.title,
        last_post_image: typeof firstImage === "string" ? firstImage : (firstImage?.uri || ""),
        last_message: "",
        last_message_time: firebase.firestore.FieldValue.serverTimestamp(),
        created_at: firebase.firestore.FieldValue.serverTimestamp(),
        unread: { [currentUser.id]: 0, [otherUserId]: 0 },
    });

    return ref.id;
}

async function sendFirebaseMessage(conversationId, text, mediaType = "text") {
    const currentUser = getStoredUser();
    const ts = firebase.firestore.FieldValue.serverTimestamp();
    await fbDb.collection("conversations").doc(conversationId)
        .collection("messages").add({ sender_id: currentUser.id, text, timestamp: ts, media_type: mediaType });
    const preview = mediaType === "image" ? "📷 صورة" : mediaType === "audio" ? "🎤 رسالة صوتية" : text;
    await fbDb.collection("conversations").doc(conversationId)
        .set({ last_message: preview, last_message_time: ts }, { merge: true });
}

function listenToConversationMessages(conversationId, onMessages) {
    if (unsubscribeMessages) { unsubscribeMessages(); unsubscribeMessages = null; }
    unsubscribeMessages = fbDb.collection("conversations").doc(conversationId)
        .collection("messages").orderBy("timestamp", "asc")
        .onSnapshot((snap) => {
            onMessages(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        }, () => {});
}

function listenToInbox(onConversations) {
    const currentUser = getStoredUser();
    if (!currentUser) return;
    if (unsubscribeInbox) { unsubscribeInbox(); unsubscribeInbox = null; }
    unsubscribeInbox = fbDb.collection("conversations")
        .where("participants", "array-contains", currentUser.id)
        .orderBy("last_message_time", "desc")
        .onSnapshot((snap) => {
            onConversations(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        }, () => {});
}

function renderChatMessages(messages) {
    const currentUser = getStoredUser();
    chatMessages.innerHTML = "";
    messages.forEach((message) => {
        const isMine = message.sender_id === currentUser?.id;
        const bubble = document.createElement("div");
        bubble.className = `chat-bubble ${isMine ? "mine" : "peer"}`;
        const mediaType = message.media_type || "text";
        if (mediaType === "image") {
            const img = document.createElement("img");
            img.src = message.text;
            img.alt = "صورة مرفقة";
            bubble.appendChild(img);
        } else if (mediaType === "audio") {
            const audio = document.createElement("audio");
            audio.controls = true;
            audio.src = message.text;
            bubble.appendChild(audio);
        } else {
            bubble.textContent = message.text;
        }
        chatMessages.appendChild(bubble);
    });
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

function openFirebaseConversation(conv, otherUserId) {
    activeConversationId = conv.id;
    activeConversationMeta = { conversationId: conv.id, listingTitle: conv.last_post_title || "محادثة", otherUserId };
    chatTitle.textContent = conv.last_post_title || "محادثة";
    chatMeta.textContent = "";
    chatMessages.innerHTML = "";
    messagesList.classList.add("hidden");
    chatView.classList.remove("hidden");
    listenToConversationMessages(conv.id, renderChatMessages);
    chatInput.focus();
}

function isFavoriteListing(id) {
    return getStoredFavorites().includes(String(id));
}

function toggleFavoriteListing(id) {
    const current = getStoredFavorites();
    const key = String(id);
    const next = current.includes(key) ? current.filter((item) => item !== key) : [...current, key];
    setStoredFavorites(next);
    return next.includes(key);
}

function getStoredPosts() {
    return remoteState.listings
        .filter((listing) => listing.userId === getStoredUser()?.id)
        .map(normalizeListing);
}

function setStoredPosts(posts) {
    const currentUser = getStoredUser();
    const otherListings = remoteState.listings.filter((listing) => listing.userId !== currentUser?.id);
    remoteState.listings = [...posts, ...otherListings];
}

function renderCategoryBar() {
    categoriesList.innerHTML = "";

    const home = document.createElement("a");
    home.href = "#";
    home.className = "category-item active";
    home.dataset.categoryId = "";
    home.innerHTML = `<i class="fa-solid fa-border-all"></i>الرئيسية`;
    categoriesList.appendChild(home);

    CATEGORIES.forEach((category) => {
        const item = document.createElement("a");
        item.href = "#";
        item.className = "category-item";
        item.dataset.categoryId = category.id;
        item.innerHTML = `<i class="fa-solid fa-${category.icon}"></i>${category.name}`;
        categoriesList.appendChild(item);
    });
}

function getActiveCategoryId() {
    return document.querySelector(".category-item.active")?.dataset.categoryId || "";
}

function getActiveSubcategory() {
    return document.querySelector(".subcategory-chip.active")?.dataset.subcategory || "";
}

function renderSubcategoryBar() {
    const activeCategory = getActiveCategoryId();
    const category = getCategoryById(activeCategory);
    const items = category?.subcategories || [];

    if (!activeCategory || !items.length) {
        subcategoriesList.innerHTML = "";
        subcategoriesBar.classList.add("hidden");
        return;
    }

    const activeSubcategory = items.includes(getActiveSubcategory()) ? getActiveSubcategory() : "";
    subcategoriesList.innerHTML = `
        <a href="#" class="subcategory-chip ${!activeSubcategory ? "active" : ""}" data-subcategory="">الكل</a>
        ${items.map((item) => `
            <a href="#" class="subcategory-chip ${activeSubcategory === item ? "active" : ""}" data-subcategory="${item}">
                ${item}
            </a>
        `).join("")}
    `;
    subcategoriesBar.classList.remove("hidden");
}

function renderGovernorateOptions() {
    const options = YEMEN_GOVERNORATES.filter((item) => item.id !== "all")
        .map((item) => `<option value="${item.id}">${item.name}</option>`)
        .join("");

    postLocation.innerHTML = `<option value="">اختر المحافظة</option>${options}`;
    regionFilter.innerHTML = `<option value="">كل المناطق</option>${options}`;
}

function renderCategoryOptions() {
    postCategory.innerHTML = `<option value="">اختر القسم</option>${CATEGORIES.map((item) => `<option value="${item.id}">${item.name}</option>`).join("")}`;
    postSubcategory.innerHTML = `<option value="">اختر القسم الفرعي</option>`;
}

function renderPriceTypeOptions() {
    postPriceType.innerHTML = PRICE_TYPES.map((item) => `<option value="${item.id}">${item.name}</option>`).join("");
}

function renderCurrencyOptions() {
    postCurrency.innerHTML = CURRENCIES.map((item) => `<option value="${item.id}">${item.name}</option>`).join("");
}

function renderConditionOptions() {
    postCondition.innerHTML = CONDITION_TYPES.map((item) => `<option value="${item.id}">${item.name}</option>`).join("");
}

function syncSubcategoryOptions() {
    const category = getCategoryById(postCategory.value);
    const items = category?.subcategories || [];
    postSubcategory.innerHTML = `<option value="">اختر القسم الفرعي</option>${items.map((item) => `<option value="${item}">${item}</option>`).join("")}`;
}

function deleteStoredPostById(postId) {
    remoteState.listings = remoteState.listings.filter((l) => String(l.id) !== String(postId));
    fbDb.collection("posts").doc(String(postId)).delete()
        .then(() => refreshRemoteState().then(() => renderCurrentListings()).catch(() => {}))
        .catch(() => {});
}

function mapLegacyCategory(value) {
    const mapping = {
        "سيارات": "cars",
        "عقارات": "real_estate",
        "جوالات": "electronics",
        "أجهزة": "electronics",
        "إلكترونيات": "electronics",
        "أثاث": "furniture",
        "أثاث ومنزل": "furniture",
        "وظائف": "jobs",
        "وضائف": "jobs",
        "خدمات": "services",
        "حيونات": "animals",
        "حيوانات": "animals",
    };
    return mapping[value] || value || "";
}

function mapLegacyGovernorate(value) {
    const mapping = {
        "أمانة العاصمة": "sanaa",
        "صنعاء": "sanaa_gov",
        "عدن": "aden",
        "تعز": "taiz",
        "الحديدة": "hodeidah",
        "إب": "ibb",
        "حضرموت": "hadramout",
        "مأرب": "marib",
        "حجة": "hajjah",
        "ذمار": "dhamar",
        "شبوة": "shabwah",
        "لحج": "lahij",
        "البيضاء": "al_baydha",
        "أبين": "abyan",
        "الجوف": "al_jawf",
        "المحويت": "al_mahwit",
        "صعدة": "saada",
        "عمران": "amran",
        "الضالع": "al_dale",
        "المهرة": "al_mahrah",
        "ريمة": "raymah",
        "سقطرى": "soqotra",
    };
    return mapping[value] || value || "";
}

function normalizeListing(item) {
    const rawImages = Array.isArray(item.images) ? item.images : item.image ? [item.image] : [];
    const images = rawImages.map((img) => {
        if (typeof img === "string") return img;
        return img?.uri || img?.url || img?.downloadURL || "";
    }).filter(Boolean);

    const ts = item.created_at || item.createdAt;
    const createdAt = ts instanceof Date
        ? ts.toISOString()
        : (ts?.toDate?.()?.toISOString() || (typeof ts === "string" ? ts : null) || new Date().toISOString());

    return {
        ...item,
        userId: item.user_id || item.userId || "",
        userName: item.user_name || item.userName || item.author || "المستخدم",
        userPhone: item.user_phone || item.userPhone || item.phone || "",
        userAvatar: item.user_avatar || item.userAvatar || "",
        category: mapLegacyCategory(item.category),
        governorate: item.governorate_id || item.governorate || mapLegacyGovernorate(item.location),
        priceType: item.price_type || item.priceType || "fixed",
        currency: item.currency || "yer",
        condition: item.condition || "good",
        views: item.view_count ?? item.views ?? 0,
        favorites: item.favorites ?? 0,
        createdAt,
        images,
    };
}

function getCurrentUserPhoneForListing(item) {
    const currentUser = getStoredUser();
    if (!currentUser) {
        return item.userPhone || item.phone || "770000000";
    }

    if (item.userId && item.userId === currentUser.id) {
        return currentUser.phone || item.userPhone || item.phone || "770000000";
    }

    return item.userPhone || item.phone || "770000000";
}

function getCurrentUserAvatarForListing(item) {
    const currentUser = getStoredUser();
    if (currentUser && item.userId && item.userId === currentUser.id) {
        return currentUser.avatar || item.userAvatar || "";
    }
    return item.userAvatar || "";
}

function syncStoredPostsWithCurrentUser() {
    return;
}

function setBodyScrollLocked(locked) {
    document.body.style.overflow = locked ? "hidden" : "auto";
}

function setAuthError(message = "") {
    authError.textContent = message;
    authError.classList.toggle("hidden", !message);
}

function setProfileError(message = "") {
    profileError.textContent = message;
    profileError.classList.toggle("hidden", !message);
}

function updateAuthNav() {
    const user = getStoredUser();
    authTriggerText.textContent = user ? user.name : "دخول";
    saveSearchBtn?.classList.toggle("active", getStoredFavorites().length > 0);
}

function setAuthMode(mode) {
    authMode = mode;
    const isRegister = mode === "register";

    authForm?.classList.remove("hidden");
    authSuccessState?.classList.add("hidden");
    document.getElementById("authOtpStep")?.classList.add("hidden");
    hideOtpStep();
    loginTabBtn?.classList.remove("hidden");
    registerTabBtn?.classList.remove("hidden");

    authNameWrap?.classList.toggle("hidden", !isRegister);
    authConfirmWrap?.classList.toggle("hidden", !isRegister);
    forgotPasswordBtn?.classList.toggle("hidden", isRegister);

    loginTabBtn?.classList.toggle("active", !isRegister);
    registerTabBtn?.classList.toggle("active", isRegister);

    if (authSubmitBtn) authSubmitBtn.textContent = isRegister ? "إنشاء حساب" : "تسجيل الدخول";

    if (isRegister) {
        authTitle.textContent = "إنشاء حساب جديد";
        authDescription.textContent = "أدخل بياناتك لإنشاء حساب في حراج اليمن.";
    } else {
        authTitle.textContent = "تسجيل الدخول";
        authDescription.textContent = "أدخل بريدك الإلكتروني وكلمة المرور للمتابعة.";
    }

    emailInput?.focus();
}

async function showOtpStep(email, firebaseUser, purpose) {
    pendingOtpEmail = email;
    pendingOtpFirebaseUser = firebaseUser;

    authForm?.classList.add("hidden");
    authSuccessState?.classList.add("hidden");
    document.getElementById("authResetStep")?.classList.add("hidden");
    document.getElementById("authOtpStep")?.classList.remove("hidden");
    loginTabBtn?.classList.add("hidden");
    registerTabBtn?.classList.add("hidden");

    authTitle.textContent = "رمز التحقق";
    authDescription.textContent = `أدخل الرمز المرسل إلى ${email}`;
    setAuthError("");

    const boxes = document.querySelectorAll(".otp-box");
    boxes.forEach(b => { b.value = ""; b.classList.remove("filled"); });
    boxes[0]?.focus();

    try {
        await fetch(`${API_BASE}/auth/send-otp`, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ email, purpose: purpose || "login" }),
        });
    } catch (_) {}
}

function hideOtpStep() {
    document.getElementById("authOtpStep")?.classList.add("hidden");
    document.getElementById("authResetStep")?.classList.add("hidden");
    pendingOtpEmail = "";
    pendingOtpFirebaseUser = null;
    forgotPasswordMode = false;
}

function showAuthSuccess() {
    const user = getStoredUser();
    authForm?.classList.add("hidden");
    authSuccessState.classList.remove("hidden");
    loginTabBtn?.classList.add("hidden");
    registerTabBtn?.classList.add("hidden");
    authTitle.textContent = "تم تسجيل الدخول";
    authDescription.textContent = "حسابك جاهز الآن داخل حراج اليمن.";
    authSuccessName.textContent = `أهلًا ${user?.name || ""}`;
    authSuccessPhone.textContent = user?.email ? `البريد: ${user.email}` : "";
}

function openAuthModal(mode = "login") {
    setAuthError("");
    authModal.style.display = "flex";
    setBodyScrollLocked(true);

    const user = getStoredUser();
    if (user) {
        showAuthSuccess();
        return;
    }

    setAuthMode("login");

    if (mode === "post") {
        authDescription.textContent = "سجل الدخول أولًا حتى تتمكن من إضافة إعلان جديد.";
    }
}

function closeAuth() {
    authModal.style.display = "none";
    setAuthError("");
    setBodyScrollLocked(false);
    hideOtpStep();
}

function openMessagesModal() {
    const user = getStoredUser();
    messagesModal.style.display = "flex";
    setBodyScrollLocked(true);
    chatView.classList.add("hidden");

    if (!user) {
        messagesSubtitle.textContent = "سجّل الدخول أولًا حتى تصل إلى محادثاتك.";
        messagesEmptyState.classList.remove("hidden");
        messagesList.classList.add("hidden");
        return;
    }

    messagesSubtitle.textContent = `مرحبًا ${user.name}، جاري تحميل محادثاتك...`;
    messagesList.classList.remove("hidden");
    messagesEmptyState.classList.add("hidden");
    listenToInbox(renderMessagesInbox);
}

function closeMessages() {
    if (mediaRecorder && mediaRecorder.state === "recording") {
        mediaRecorder.stop();
    }
    stopRecordingStream();
    resetRecorderUi();
    if (unsubscribeMessages) { unsubscribeMessages(); unsubscribeMessages = null; }
    if (unsubscribeInbox) { unsubscribeInbox(); unsubscribeInbox = null; }
    messagesModal.style.display = "none";
    setBodyScrollLocked(false);
    activeConversationId = null;
    activeConversationMeta = null;
}

function openFavoritesModal() {
    favoritesModal.style.display = "flex";
    setBodyScrollLocked(true);
    const favoriteIds = getStoredFavorites();
    const items = getAllListings().filter((listing) => favoriteIds.includes(String(listing.id)));

    favoritesList.innerHTML = "";
    if (!items.length) {
        favoritesEmptyState.classList.remove("hidden");
        favoritesList.classList.add("hidden");
        return;
    }

    favoritesEmptyState.classList.add("hidden");
    favoritesList.classList.remove("hidden");
    items.forEach((item) => {
        const card = document.createElement("div");
        card.className = "message-card";
        card.innerHTML = `
            <div class="message-thread-body">
                <div class="message-thread-top">
                    <strong class="message-thread-title">${item.title}</strong>
                    <span class="message-thread-time">${formatPrice(item.price, item.priceType, item.currency)}</span>
                </div>
                <div class="message-thread-listing">${getCategoryLabel(item.category)}</div>
                <div class="message-thread-preview">${getGovernorateLabel(item.governorate)} • ${item.userName}</div>
            </div>
        `;
        card.addEventListener("click", () => {
            window.location.href = getListingUrl(item);
        });
        favoritesList.appendChild(card);
    });
}

function closeFavoritesPanel() {
    favoritesModal.style.display = "none";
    setBodyScrollLocked(false);
}

function openProfileModal() {
    const user = getStoredUser();
    if (!user) {
        openAuthModal("login");
        return;
    }

    profileModal.style.display = "flex";
    setBodyScrollLocked(true);
    renderProfileAvatarElement(user);
    profileName.textContent = user.name;
    profilePhone.textContent = `+967 ${user.phone}`;
    profileNameInput.value = user.name;
    profilePhoneInput.value = user.phone;
    profileAvatarInput.value = "";
    setProfileError("");

    const myListings = getAllListings().filter((listing) => listing.userId === user.id);
    profilePhone.insertAdjacentHTML("afterend", `<span class="profile-stat">${myListings.length} إعلاناتي</span>`);
    const duplicatedStats = profileModal.querySelectorAll(".profile-stat");
    if (duplicatedStats.length > 1) {
        duplicatedStats[0].remove();
    }
    profileListingsList.innerHTML = "";
    if (!myListings.length) {
        profileListingsEmpty.classList.remove("hidden");
        profileListingsList.classList.add("hidden");
        return;
    }

    profileListingsEmpty.classList.add("hidden");
    profileListingsList.classList.remove("hidden");
    myListings.forEach((item) => {
        const card = document.createElement("div");
        card.className = "message-card";
        card.innerHTML = `
            <div class="message-thread-body">
                <div class="message-thread-top">
                    <strong class="message-thread-title">${item.title}</strong>
                    <span class="message-thread-time">${timeAgo(item.createdAt)}</span>
                </div>
                <div class="message-thread-listing">${getCategoryLabel(item.category)}</div>
                <div class="message-thread-preview">${formatPrice(item.price, item.priceType, item.currency)} • ${getGovernorateLabel(item.governorate)}</div>
            </div>
        `;
        card.addEventListener("click", () => {
            window.location.href = getListingUrl(item);
        });
        profileListingsList.appendChild(card);
    });
}

function closeProfilePanel() {
    profileModal.style.display = "none";
    setBodyScrollLocked(false);
}

function renderMessagesInbox(conversations) {
    const user = getStoredUser();
    messagesList.innerHTML = "";

    if (!conversations || !conversations.length) {
        messagesSubtitle.textContent = "ابدأ محادثة مع البائع من صفحة الإعلان.";
        messagesEmptyState.classList.remove("hidden");
        messagesList.classList.add("hidden");
        return;
    }

    messagesSubtitle.textContent = `مرحبًا ${user.name}، هذه آخر محادثاتك.`;
    messagesEmptyState.classList.add("hidden");
    messagesList.classList.remove("hidden");

    conversations.forEach((conv) => {
        const otherUserId = (conv.participants || []).find((uid) => uid !== user.id) || "";
        const lastTime = conv.last_message_time?.toDate?.() || new Date();
        const card = document.createElement("div");
        card.className = "message-card";
        card.innerHTML = `
            <div class="message-card-thread">
                <div class="message-avatar">${(conv.last_post_title || "م").charAt(0)}</div>
                <div class="message-thread-body">
                    <div class="message-thread-top">
                        <strong class="message-thread-title">${conv.last_post_title || "محادثة"}</strong>
                        <span class="message-thread-time">${timeAgo(lastTime.toISOString())}</span>
                    </div>
                    <div class="message-thread-preview">${conv.last_message || "لا توجد رسائل بعد"}</div>
                </div>
            </div>
        `;
        card.addEventListener("click", () => openFirebaseConversation(conv, otherUserId));
        messagesList.appendChild(card);
    });
}

async function openListingConversation(item) {
    const user = getStoredUser();
    if (!user) { openAuthModal("login"); return; }

    const otherUserId = item.user_id || item.userId;
    if (!otherUserId || otherUserId === user.id) return;

    messagesModal.style.display = "flex";
    setBodyScrollLocked(true);
    messagesEmptyState.classList.add("hidden");
    messagesList.classList.add("hidden");
    chatView.classList.add("hidden");
    messagesSubtitle.textContent = "جاري تحميل المحادثة...";

    try {
        const convId = await getOrCreateConversation(item);
        if (!convId) return;
        const convDoc = await fbDb.collection("conversations").doc(convId).get();
        openFirebaseConversation({ id: convId, ...convDoc.data() }, otherUserId);
    } catch {
        messagesSubtitle.textContent = "تعذر فتح المحادثة. حاول مرة أخرى.";
        messagesEmptyState.classList.remove("hidden");
    }
}

function openPostModal() {
    postModal.style.display = "flex";
    setBodyScrollLocked(true);
    setPostError("");
    postTitle.focus();
}

function closePostModalHandler() {
    postModal.style.display = "none";
    setBodyScrollLocked(false);
    setPostError("");
    if (!postImage.files?.length) {
        resetPostImagePreview();
    }
}

function setAgreementError(message = "") {
    agreementError.textContent = message;
    agreementError.classList.toggle("hidden", !message);
}

function openAgreementModal(draft) {
    pendingPostDraft = draft;
    agreementCheckbox.checked = false;
    setAgreementError("");
    publishAgreementModal.style.display = "flex";
    setBodyScrollLocked(true);
}

function closeAgreementModalHandler() {
    publishAgreementModal.style.display = "none";
    pendingPostDraft = null;
    agreementCheckbox.checked = false;
    setAgreementError("");
    setBodyScrollLocked(true);
}

async function publishPostDraft(draft) {
    const imageUrls = [];
    for (const dataUrl of draft.images) {
        if (dataUrl && dataUrl.startsWith("data:")) {
            try {
                const ref = fbStorage.ref(`posts/${Date.now()}_${Math.random().toString(36).slice(2)}`);
                await ref.putString(dataUrl, "data_url");
                const url = await ref.getDownloadURL();
                imageUrls.push(url);
            } catch { /* skip failed uploads */ }
        } else if (dataUrl) {
            imageUrls.push(dataUrl);
        }
    }

    const payload = {
        title: draft.title,
        price: draft.priceType === "free" || draft.priceType === "exchange" ? 0 : Number(draft.price) || 0,
        currency: draft.currency || "yer",
        price_type: draft.priceType,
        subcategory: draft.subcategory,
        governorate: draft.governorate,
        condition: draft.condition,
        user_id: draft.user.id,
        user_name: draft.user.name,
        user_phone: draft.user.phone || "",
        user_avatar: draft.user.avatar || "",
        category: draft.category,
        description: draft.description,
        images: imageUrls,
        status: "active",
        created_at: firebase.firestore.FieldValue.serverTimestamp(),
    };

    await fbDb.collection("posts").add(payload);
    await refreshRemoteState().catch(() => {});

    postForm.reset();
    resetPostImagePreview();
    closeAgreementModalHandler();
    closePostModalHandler();
    renderCurrentListings();
}

function setPostError(message = "") {
    postError.textContent = message;
    postError.classList.toggle("hidden", !message);
}

function resetPostImagePreview() {
    postImageDataUrls = [];
    postImagePreview.innerHTML = "";
    postImagePreview.classList.add("hidden");
}

function addWatermarkToImage(dataUrl) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.onload = () => {
            const canvas = document.createElement("canvas");
            canvas.width = img.naturalWidth || img.width;
            canvas.height = img.naturalHeight || img.height;
            const ctx = canvas.getContext("2d");

            if (!ctx) {
                resolve(dataUrl);
                return;
            }

            ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

            const baseSize = Math.max(24, Math.round(Math.min(canvas.width, canvas.height) * 0.045));
            ctx.font = `700 ${baseSize}px Cairo, sans-serif`;
            ctx.textAlign = "right";
            ctx.textBaseline = "bottom";

            const label = "حراج اليمن";
            const padding = Math.round(baseSize * 0.7);
            const metrics = ctx.measureText(label);
            const boxWidth = metrics.width + padding * 1.4;
            const boxHeight = baseSize + padding;
            const x = canvas.width - padding;
            const y = canvas.height - padding;

            ctx.fillStyle = "rgba(0, 0, 0, 0.35)";
            const rectX = canvas.width - boxWidth - padding * 0.35;
            const rectY = canvas.height - boxHeight - padding * 0.2;
            if (typeof ctx.roundRect === "function") {
                ctx.beginPath();
                ctx.roundRect(rectX, rectY, boxWidth, boxHeight, 16);
                ctx.fill();
            } else {
                ctx.fillRect(rectX, rectY, boxWidth, boxHeight);
            }

            ctx.fillStyle = "rgba(255, 255, 255, 0.92)";
            ctx.fillText(label, x, y);

            resolve(canvas.toDataURL("image/jpeg", 0.92));
        };
        img.onerror = reject;
        img.src = dataUrl;
    });
}

function openImageLightbox(src) {
    if (!src) return;
    imageLightboxTarget.src = src;
    imageLightboxModal.style.display = "flex";
    setBodyScrollLocked(true);
}

function closeImageLightbox() {
    imageLightboxModal.style.display = "none";
    imageLightboxTarget.src = "";
    setBodyScrollLocked(false);
}

function getListingImages(item) {
    if (Array.isArray(item.images) && item.images.length > 0) {
        return item.images;
    }
    if (item.image) {
        return [item.image];
    }
    return ["https://via.placeholder.com/800x600?text=Haraj+Yemen"];
}

function getRealListingImages(item) {
    return getListingImages(item).filter((src) => !isPlaceholderImage(src));
}

function isPlaceholderImage(src) {
    return !src || src.includes("via.placeholder.com/800x600?text=Haraj+Yemen");
}

function getListingById(id) {
    return getAllListings().find((listing) => String(listing.id) === String(id)) || null;
}

function getListingUrl(item) {
    return `${window.location.pathname}?listing=${encodeURIComponent(item.id)}`;
}

function showListingsPage() {
    listingPage.classList.add("hidden");
    marketToolbar.classList.remove("hidden");
    listingsContainer.classList.remove("hidden");
}

function navigateToListingsView() {
    closeImageLightbox();
    showListingsPage();
    if (window.location.search.includes("listing=")) {
        window.history.replaceState({}, "", window.location.pathname);
    }
}

function getBlockedAdTerm(text) {
    const raw = String(text || "").toLowerCase();
    const normalized = normalizeArabicText(text);

    for (const term of PROHIBITED_AD_TERMS) {
        const rawTerm = term.toLowerCase();
        const normalizedTerm = normalizeArabicText(term);

        if (raw.includes(rawTerm) || (normalizedTerm && normalized.includes(normalizedTerm))) {
            return term;
        }
    }

    return null;
}

function validatePostDraft() {
    const title = postTitle.value.trim();
    const category = postCategory.value.trim();
    const subcategory = postSubcategory.value.trim();
    const description = postDescription.value.trim();
    const blockedTerm = getBlockedAdTerm(`${title} ${description} ${category} ${subcategory}`);

    if (blockedTerm) {
        setPostError(`ممنوع نشر هذا الإعلان لأن المحتوى يتضمن كلمة محظورة: "${blockedTerm}".`);
        submitPostBtn.disabled = true;
        submitPostBtn.style.opacity = "0.6";
        submitPostBtn.style.cursor = "not-allowed";
        return false;
    }

    setPostError("");
    submitPostBtn.disabled = false;
    submitPostBtn.style.opacity = "1";
    submitPostBtn.style.cursor = "pointer";
    return true;
}

function purgeBlockedStoredPosts() {
    return;
}

function getAllListings() {
    return remoteState.listings.map(normalizeListing);
}

function matchesSubcategoryFilter(listing, activeSubcategory) {
    if (!activeSubcategory) return true;

    if (listing.subcategory === activeSubcategory) {
        return true;
    }

    const normalizedSubcategory = normalizeArabicText(activeSubcategory);

    if (normalizedSubcategory.includes("جديد")) {
        return listing.condition === "new";
    }

    if (normalizedSubcategory.includes("مستعمل")) {
        return ["like_new", "good", "acceptable"].includes(listing.condition);
    }

    return false;
}

function incrementListingViews(listingId) {
    const listing = getListingById(listingId);
    return (listing?.views || 0) + 1;
}

function renderCurrentListings() {
    const activeCategory = getActiveCategoryId();
    const activeSubcategory = getActiveSubcategory();
    const term = searchInput.value.toLowerCase().trim();
    const region = regionFilter?.value?.trim() || "";
    let items = getAllListings();

    if (activeCategory) {
        items = items.filter((listing) => listing.category === activeCategory);
    }

    if (activeSubcategory) {
        items = items.filter((listing) => matchesSubcategoryFilter(listing, activeSubcategory));
    }

    if (region) {
        items = items.filter((listing) => listing.governorate === region);
    }

    if (nearbyOnly) {
        items = items
            .map((listing) => {
                const point = GOVERNORATE_COORDINATES[listing.governorate];
                return {
                    ...listing,
                    _distanceKm: getDistanceInKm(userCoordinates, point),
                };
            })
            .sort((a, b) => a._distanceKm - b._distanceKm);
    }

    if (term) {
        items = items.filter((listing) =>
            listing.title.toLowerCase().includes(term) ||
            listing.description.toLowerCase().includes(term) ||
            getCategoryLabel(listing.category).toLowerCase().includes(term) ||
            getGovernorateLabel(listing.governorate).toLowerCase().includes(term)
        );
    }

    if (resultsTitle) {
        if (activeSubcategory) {
            resultsTitle.textContent = activeSubcategory;
        } else if (activeCategory) {
            resultsTitle.textContent = getCategoryLabel(activeCategory);
        } else if (region) {
            resultsTitle.textContent = `إعلانات ${getGovernorateLabel(region)}`;
        } else if (nearbyOnly) {
            resultsTitle.textContent = nearestGovernorateId
                ? `الأقرب إلى ${getGovernorateLabel(nearestGovernorateId)}`
                : "الإعلانات القريبة";
        } else {
            resultsTitle.textContent = "أحدث الإعلانات";
        }
    }

    renderListings(items);
}

// Render listings
function renderListings(items) {
    listingsContainer.innerHTML = "";
    const currentUser = getStoredUser();
    items.forEach((item, index) => {
        const card = document.createElement("div");
        card.className = "card";
        card.style.animationDelay = `${(index * 0.1)}s`;
        const previewImage = getListingImages(item)[0];
        const hasRealImage = !isPlaceholderImage(previewImage);
        const isOwnPost = !!currentUser && !!item.userId && item.userId === currentUser.id;
        const sellerAvatar = getCurrentUserAvatarForListing(item);
        const sellerBadge = sellerAvatar
            ? `<span class="card-seller-badge has-image" style="background-image: url('${sellerAvatar.replace(/'/g, "\\'")}');"></span>`
            : `<span class="card-seller-badge">${(item.userName || "م").charAt(0)}</span>`;

        if (!hasRealImage) {
            card.classList.add("card-no-image");
        }
        
        card.innerHTML = `
            ${hasRealImage ? `<img src="${previewImage}" alt="${item.title}" class="card-img" onerror="this.remove()">` : ""}
            <div class="card-content">
                <div class="card-badge-row">
                    <span class="card-category-chip">${getCategoryLabel(item.category)}</span>
                    <span class="card-time">${timeAgo(item.createdAt)}</span>
                </div>
                <span class="card-price">${formatPrice(item.price, item.priceType, item.currency)}</span>
                ${(item.priceType === "negotiable" || item.priceType === "free" || item.priceType === "exchange") ? `<span class="card-price-type">${PRICE_TYPES.find((entry) => entry.id === item.priceType)?.name || ""}</span>` : ""}
                <h3 class="card-title">${item.title}</h3>
                <p class="card-description">${item.description || ""}</p>
                <div class="card-footer">
                    <div class="card-footer-right">
                        <div class="card-meta card-governorate">
                            <i class="fa-solid fa-location-dot"></i>
                            <span>${getGovernorateLabel(item.governorate)}</span>
                        </div>
                        <div class="card-meta">
                            <i class="fa-regular fa-clock"></i>
                            <span>${timeAgo(item.createdAt)}</span>
                        </div>
                    </div>
                    <div class="card-footer-left">
                        <div class="card-meta">
                            ${sellerBadge}
                            <span>${item.userName}</span>
                        </div>
                        ${isOwnPost ? `
                            <button class="listing-delete-btn" type="button" data-delete-id="${item.id}">
                                <i class="fa-regular fa-trash-can"></i>
                                <span>حذف</span>
                            </button>
                        ` : ""}
                    </div>
                </div>
            </div>
        `;

        card.addEventListener("click", () => {
            if (!getStoredUser()) {
                openAuthModal("login");
                return;
            }
            window.location.href = getListingUrl(item);
        });

        const deleteBtn = card.querySelector("[data-delete-id]");
        deleteBtn?.addEventListener("click", (event) => {
            event.stopPropagation();
            if (!confirm("هل تريد حذف هذا الإعلان؟")) {
                return;
            }
            deleteStoredPostById(item.id);
            renderCurrentListings();
        });

        listingsContainer.appendChild(card);
    });
}

function renderListingPage(item) {
    const nextViews = incrementListingViews(item.id);
    const listingWithViews = { ...item, views: nextViews };
    const sellerPhone = getCurrentUserPhoneForListing(listingWithViews).replace(/\D/g, "");
    const sellerPhoneIntl = sellerPhone.startsWith("967") ? sellerPhone : `967${sellerPhone}`;
    const sellerAvatar = getCurrentUserAvatarForListing(listingWithViews);
    const images = getRealListingImages(item);
    const hasRealImages = images.length > 0;
    const galleryHtml = images
        .slice(1)
        .map((src, index) => `<img src="${src}" alt="${listingWithViews.title} ${index + 2}" class="listing-thumb" data-lightbox-src="${src}">`)
        .join("");
    const shareUrl = `${window.location.origin}${getListingUrl(listingWithViews)}`;
    const shareText = `${listingWithViews.title} - ${formatPrice(listingWithViews.price, listingWithViews.priceType, listingWithViews.currency)}`;
    listingPageBody.innerHTML = `
        <div class="listing-page-shell">
        <div class="listing-page-grid${hasRealImages ? "" : " listing-page-grid--single"}">
            ${hasRealImages ? `
            <div class="listing-gallery">
                <img src="${images[0]}" class="listing-main-image" data-lightbox-src="${images[0]}">
                ${images.length > 1 ? `<div class="listing-thumbs">${galleryHtml}</div>` : ""}
            </div>
            ` : ""}
            <div class="modal-info">
                <div class="listing-meta-bar">
                    <span class="listing-category-chip">${getCategoryLabel(listingWithViews.category)}</span>
                    <span class="listing-time"><i class="fa-regular fa-clock ml-2"></i>${timeAgo(listingWithViews.createdAt)}</span>
                </div>
                <h2 class="listing-title">${listingWithViews.title}</h2>
                <h3 class="listing-price">${formatPrice(listingWithViews.price, listingWithViews.priceType, listingWithViews.currency)}</h3>

                <div class="listing-quick-meta">
                    <span class="listing-meta-pill"><i class="fa-solid fa-location-dot"></i>${getGovernorateLabel(listingWithViews.governorate)}</span>
                    <span class="listing-meta-pill"><i class="fa-regular fa-eye"></i>${listingWithViews.views || 0}</span>
                    <span class="listing-meta-pill"><i class="fa-solid fa-tag"></i>${PRICE_TYPES.find((entry) => entry.id === listingWithViews.priceType)?.name || "سعر ثابت"}</span>
                    <span class="listing-meta-pill"><i class="fa-solid fa-box-open"></i>${CONDITION_TYPES.find((entry) => entry.id === listingWithViews.condition)?.name || "غير محدد"}</span>
                </div>
                
                <div class="listing-info-card">
                    <h4>وصف الإعلان</h4>
                    <p>${listingWithViews.description}</p>
                </div>

                <div class="listing-seller-card">
                    <div class="listing-seller-head">
                        <span class="listing-seller-avatar ${sellerAvatar ? "has-image" : ""}" ${sellerAvatar ? `style="background-image: url('${sellerAvatar.replace(/'/g, "\\'")}');"` : ""}>${sellerAvatar ? "" : (listingWithViews.userName || "م").charAt(0)}</span>
                        <h4>المعلن: ${listingWithViews.userName}</h4>
                    </div>
                    <p>التواصل مع المعلن متاح عبر المنصة والاتصال المباشر.</p>
                    <div class="details-actions-bar">
                        <button id="messageSellerBtn" class="details-action-btn">
                            <i class="fa-regular fa-envelope"></i> مراسلة
                        </button>
                        <a id="callSellerBtn" class="details-action-btn" href="${sellerPhone ? `tel:+${sellerPhoneIntl}` : "#"}">
                            <i class="fa-solid fa-phone"></i> اتصال
                        </a>
                        <a id="whatsappSellerBtn" class="details-action-btn" target="_blank" rel="noopener noreferrer" href="${sellerPhone ? `https://wa.me/${sellerPhoneIntl}?text=${encodeURIComponent(`مرحبًا، بخصوص إعلان: ${listingWithViews.title}`)}` : "#"}">
                            <i class="fa-brands fa-whatsapp"></i> واتساب
                        </a>
                        <button id="favoriteSellerBtn" class="details-action-btn">
                            <i class="fa-solid fa-heart"></i> تفضيل
                        </button>
                        <button id="shareSellerBtn" class="details-action-btn">
                            <i class="fa-solid fa-share-nodes"></i> مشاركة
                        </button>
                        <button id="reportSellerBtn" class="details-action-btn">
                            <i class="fa-solid fa-flag"></i> بلّغ
                        </button>
                    </div>
                </div>
            </div>
        </div>
        </div>
    `;
    const messageSellerBtn = document.getElementById("messageSellerBtn");
    const callSellerBtn = document.getElementById("callSellerBtn");
    const whatsappSellerBtn = document.getElementById("whatsappSellerBtn");
    const favoriteSellerBtn = document.getElementById("favoriteSellerBtn");
    const shareSellerBtn = document.getElementById("shareSellerBtn");
    const reportSellerBtn = document.getElementById("reportSellerBtn");

    messageSellerBtn?.addEventListener("click", () => {
        openListingConversation(listingWithViews);
    });

    callSellerBtn?.addEventListener("click", (event) => {
        if (!sellerPhone) {
            event.preventDefault();
            alert("رقم المعلن غير متوفر لهذا الإعلان.");
        }
    });

    whatsappSellerBtn?.addEventListener("click", (event) => {
        if (!sellerPhone) {
            event.preventDefault();
            alert("رقم واتساب غير متوفر لهذا الإعلان.");
        }
    });

    favoriteSellerBtn?.addEventListener("click", () => {
        const isFav = toggleFavoriteListing(listingWithViews.id);
        favoriteSellerBtn.classList.toggle("active", isFav);
        saveSearchBtn?.classList.toggle("active", getStoredFavorites().length > 0);
    });

    shareSellerBtn?.addEventListener("click", async () => {
        if (navigator.share) {
            try {
                await navigator.share({
                    title: listingWithViews.title,
                    text: shareText,
                    url: shareUrl,
                });
            } catch {}
            return;
        }

        if (navigator.clipboard?.writeText) {
            await navigator.clipboard.writeText(shareUrl);
            shareSellerBtn.classList.add("active");
        }
    });

    reportSellerBtn?.addEventListener("click", () => {
        reportSellerBtn.classList.add("active");
        alert("تم استلام البلاغ وسيتم مراجعته من إدارة المنصة.");
    });

    listingPageBody.querySelectorAll("[data-lightbox-src]").forEach((imageElement) => {
        imageElement.addEventListener("click", () => {
            openImageLightbox(imageElement.getAttribute("data-lightbox-src"));
        });
    });

    marketToolbar.classList.add("hidden");
    listingsContainer.classList.add("hidden");
    listingPage.classList.remove("hidden");
    window.scrollTo({ top: 0, behavior: "smooth" });
}

window.addEventListener("click", (e) => {
    if (e.target === authModal) {
        closeAuth();
    }

    if (e.target === messagesModal) {
        closeMessages();
    }

    if (e.target === favoritesModal) {
        closeFavoritesPanel();
    }

    if (e.target === profileModal) {
        closeProfilePanel();
    }

    if (e.target === postModal) {
        closePostModalHandler();
    }

    if (e.target === publishAgreementModal) {
        closeAgreementModalHandler();
    }

    if (e.target === imageLightboxModal) {
        closeImageLightbox();
    }
});

listingBackBtn.addEventListener("click", () => {
    window.location.href = window.location.pathname;
});

categoriesList.addEventListener("click", (e) => {
    const item = e.target.closest(".category-item");
    if (!item) return;
    e.preventDefault();
    navigateToListingsView();
    categoriesList.querySelectorAll(".category-item").forEach((entry) => entry.classList.remove("active"));
    item.classList.add("active");
    renderSubcategoryBar();
    renderCurrentListings();
});

subcategoriesList?.addEventListener("click", (e) => {
    const item = e.target.closest(".subcategory-chip");
    if (!item) return;
    e.preventDefault();
    navigateToListingsView();
    subcategoriesList.querySelectorAll(".subcategory-chip").forEach((entry) => entry.classList.remove("active"));
    item.classList.add("active");
    renderCurrentListings();
});

// Search functionality
const searchInput = document.querySelector(".search-bar input");
searchInput.addEventListener("input", (e) => {
    renderCurrentListings();
});

regionFilter?.addEventListener("change", () => {
    renderCurrentListings();
});

nearbyToggleBtn?.addEventListener("click", async () => {
    if (nearbyOnly) {
        nearbyOnly = false;
        nearbyToggleBtn.classList.remove("active");
        renderCurrentListings();
        return;
    }

    try {
        nearbyToggleBtn.disabled = true;
        nearbyToggleBtn.textContent = "جاري التحديد...";
        await requestNearbyLocation();
        nearbyOnly = true;
        nearbyToggleBtn.classList.add("active");
        nearbyToggleBtn.textContent = "القريب";
        renderCurrentListings();
    } catch (error) {
        nearbyOnly = false;
        nearbyToggleBtn.classList.remove("active");
        nearbyToggleBtn.textContent = "القريب";
        alert(error.message || "تعذر تحديد موقعك الجغرافي.");
    } finally {
        nearbyToggleBtn.disabled = false;
    }
});

saveSearchBtn?.addEventListener("click", () => {
    saveSearchBtn.classList.toggle("active");
});

favoritesTrigger?.addEventListener("click", (e) => {
    e.preventDefault();
    openFavoritesModal();
});

authTrigger.addEventListener("click", (e) => {
    e.preventDefault();
    openProfileModal();
});

authRequiredTriggers.forEach((trigger) => {
    trigger.addEventListener("click", (e) => {
        e.preventDefault();
        const mode = trigger.getAttribute("data-auth-trigger") || "login";
        const user = getStoredUser();

        if (mode === "post") {
            if (!user) {
                openAuthModal("post");
                return;
            }
            openPostModal();
            return;
        }

        openAuthModal(mode);
    });
});

closeAuthModal.addEventListener("click", closeAuth);
closeAuthSuccessBtn.addEventListener("click", closeAuth);
closeMessagesModal.addEventListener("click", closeMessages);
closeFavoritesModalBtn.addEventListener("click", closeFavoritesPanel);
closeProfileModalBtn.addEventListener("click", closeProfilePanel);
closePostModal.addEventListener("click", closePostModalHandler);
cancelPostBtn.addEventListener("click", closePostModalHandler);
closeAgreementModal.addEventListener("click", closeAgreementModalHandler);
cancelAgreementBtn.addEventListener("click", closeAgreementModalHandler);
closeImageLightboxBtn.addEventListener("click", closeImageLightbox);

postImage.addEventListener("change", () => {
    const files = Array.from(postImage.files || []);

    if (!files.length) {
        resetPostImagePreview();
        return;
    }

    if (files.length > 10) {
        setPostError("الحد الأقصى لصور الإعلان هو 10 صور.");
        postImage.value = "";
        resetPostImagePreview();
        return;
    }

    if (files.some((file) => !file.type.startsWith("image/"))) {
        setPostError("يوجد ملف غير صالح. الرجاء اختيار صور فقط.");
        postImage.value = "";
        resetPostImagePreview();
        return;
    }

    Promise.all(
        files.map((file) => new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(typeof reader.result === "string" ? reader.result : "");
            reader.onerror = reject;
            reader.readAsDataURL(file);
        }))
    )
        .then((results) => Promise.all(results.filter(Boolean).map((src) => addWatermarkToImage(src).catch(() => src))))
        .then((results) => {
            postImageDataUrls = results.filter(Boolean);
            if (!postImageDataUrls.length) {
                setPostError("تعذر قراءة الصور المختارة.");
                resetPostImagePreview();
                return;
            }

            setPostError("");
            postImagePreview.innerHTML = postImageDataUrls
                .map((src, index) => `
                    <div class="post-image-thumb">
                        <img src="${src}" alt="معاينة ${index + 1}">
                    </div>
                `)
                .join("");
            postImagePreview.classList.remove("hidden");
        })
        .catch(() => {
            setPostError("تعذر قراءة الصور المختارة.");
            resetPostImagePreview();
        });
});

postTitle.addEventListener("input", validatePostDraft);
postDescription.addEventListener("input", validatePostDraft);
postCategory.addEventListener("change", validatePostDraft);
postSubcategory.addEventListener("change", validatePostDraft);
postCategory.addEventListener("change", syncSubcategoryOptions);


profileAvatarInput?.addEventListener("change", async () => {
    const current = getStoredUser();
    const file = profileAvatarInput.files?.[0];
    if (!current || !file) return;

    if (!file.type.startsWith("image/")) {
        setProfileError("الملف المختار ليس صورة.");
        profileAvatarInput.value = "";
        return;
    }

    try {
        const ref = fbStorage.ref(`avatars/${current.id}`);
        await ref.put(file);
        const avatarUrl = await ref.getDownloadURL();
        await fbDb.collection("users").doc(current.id).set({ avatar: avatarUrl }, { merge: true });
        const updatedUser = { ...current, avatar: avatarUrl };
        setStoredUser(updatedUser);
        renderProfileAvatarElement(updatedUser);
        setProfileError("");
        profileAvatarInput.value = "";
    } catch {
        setProfileError("تعذر حفظ الصورة الشخصية.");
    }
});

authForm?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const email = emailInput.value.trim().toLowerCase();
    const password = passwordInput.value;
    const isRegister = authMode === "register";

    if (!email || !password) {
        setAuthError("يرجى إدخال البريد الإلكتروني وكلمة المرور.");
        return;
    }

    if (isRegister) {
        const name = nameInput.value.trim();
        if (!hasRequiredFullName(name)) {
            setAuthError("يجب إدخال الاسم الأول والاسم الأخير بشكل إجباري.");
            return;
        }
        if (password !== confirmPasswordInput.value) {
            setAuthError("كلمتا المرور غير متطابقتين.");
            return;
        }
    }

    authSubmitBtn.disabled = true;
    authSubmitBtn.textContent = "جاري...";
    setAuthError("");

    try {
        if (isRegister) {
            const name = nameInput.value.trim();
            const cred = await fbAuth.createUserWithEmailAndPassword(email, password);
            fbDb.collection("users").doc(cred.user.uid).set({
                name, email, phone: "",
                created_at: firebase.firestore.FieldValue.serverTimestamp(),
            }).catch(() => {});
            cred.user.updateProfile({ displayName: name }).catch(() => {});
            authSubmitBtn.disabled = false;
            authSubmitBtn.textContent = "إنشاء حساب";
            await showOtpStep(email, cred.user);
        } else {
            const cred = await fbAuth.signInWithEmailAndPassword(email, password);
            authSubmitBtn.disabled = false;
            authSubmitBtn.textContent = "تسجيل الدخول";
            await showOtpStep(email, cred.user);
        }
    } catch (err) {
        setAuthError(getFirebaseErrorMessage(err.code) + (err.code ? "" : ` (${err.message || JSON.stringify(err)})`));
        authSubmitBtn.disabled = false;
        authSubmitBtn.textContent = isRegister ? "إنشاء حساب" : "تسجيل الدخول";
    }
});

loginTabBtn?.addEventListener("click", () => {
    setAuthError("");
    setAuthMode("login");
});

registerTabBtn?.addEventListener("click", () => {
    setAuthError("");
    setAuthMode("register");
});

forgotPasswordBtn?.addEventListener("click", async () => {
    const email = emailInput.value.trim();
    if (!email) {
        setAuthError("أدخل بريدك الإلكتروني أولاً.");
        return;
    }
    forgotPasswordMode = true;
    await showOtpStep(email, null, "reset");
});


// ===== OTP handlers =====
document.getElementById("otpBoxes")?.addEventListener("input", (e) => {
    const box = e.target;
    if (!/^\d$/.test(box.value)) { box.value = ""; return; }
    box.classList.add("filled");
    const boxes = [...document.querySelectorAll(".otp-box")];
    const idx = boxes.indexOf(box);
    if (idx < boxes.length - 1) boxes[idx + 1].focus();
});

document.getElementById("otpBoxes")?.addEventListener("keydown", (e) => {
    const boxes = [...document.querySelectorAll(".otp-box")];
    const idx = boxes.indexOf(e.target);
    if (e.key === "Backspace") {
        e.target.value = "";
        e.target.classList.remove("filled");
        if (idx > 0) boxes[idx - 1].focus();
    } else if (e.key === "ArrowRight" && idx > 0) {
        boxes[idx - 1].focus();
    } else if (e.key === "ArrowLeft" && idx < boxes.length - 1) {
        boxes[idx + 1].focus();
    }
});

document.getElementById("otpSubmitBtn")?.addEventListener("click", async () => {
    const boxes = [...document.querySelectorAll(".otp-box")];
    const code = boxes.map(b => b.value).join("");
    if (code.length !== 4) { setAuthError("أدخل الرمز المكون من 4 أرقام."); return; }

    const btn = document.getElementById("otpSubmitBtn");
    btn.disabled = true;
    btn.textContent = "جاري التحقق...";
    setAuthError("");

    try {
        const purpose = forgotPasswordMode ? "reset" : "login";
        const resp = await fetch(`${API_BASE}/auth/verify-otp`, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ email: pendingOtpEmail, otp: code, purpose }),
        });
        const data = await resp.json();
        if (!resp.ok) { setAuthError(data.error || "رمز غير صحيح."); return; }

        if (forgotPasswordMode) {
            // OTP verified for password reset — show new password form
            document.getElementById("authOtpStep")?.classList.add("hidden");
            document.getElementById("authResetStep")?.classList.remove("hidden");
            authTitle.textContent = "كلمة مرور جديدة";
            authDescription.textContent = "أدخل كلمة المرور الجديدة لحسابك";
            document.getElementById("resetNewPassword").value = "";
            document.getElementById("resetConfirmPassword").value = "";
            document.getElementById("resetNewPassword").focus();
            setAuthError("");
            return;
        }

        // OTP verified for login — store Firebase user info and show success
        const fbUser = pendingOtpFirebaseUser || fbAuth.currentUser;
        if (fbUser) {
            const userDoc = await fbDb.collection("users").doc(fbUser.uid).get().catch(() => null);
            const ud = userDoc?.data() || {};
            setStoredUser({
                id: fbUser.uid,
                email: fbUser.email,
                name: ud.name || fbUser.displayName || fbUser.email?.split("@")[0] || "مستخدم",
                phone: ud.phone || "",
                avatar: ud.avatar || "",
            });
        }
        hideOtpStep();
        showAuthSuccess();
        updateAuthNav();
    } catch (_) {
        setAuthError("حدث خطأ، حاول مرة أخرى.");
    } finally {
        btn.disabled = false;
        btn.textContent = "تحقق";
    }
});

document.getElementById("otpResendBtn")?.addEventListener("click", async () => {
    const btn = document.getElementById("otpResendBtn");
    btn.disabled = true;
    btn.textContent = "جاري الإرسال...";
    try {
        await fetch(`${API_BASE}/auth/send-otp`, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ email: pendingOtpEmail, purpose: forgotPasswordMode ? "reset" : "login" }),
        });
        setAuthError("");
        btn.textContent = "تم الإرسال ✓";
        setTimeout(() => { btn.textContent = "لم يصل الرمز؟ أعد الإرسال"; btn.disabled = false; }, 3000);
        const boxes = document.querySelectorAll(".otp-box");
        boxes.forEach(b => { b.value = ""; b.classList.remove("filled"); });
        boxes[0]?.focus();
    } catch (_) {
        btn.textContent = "لم يصل الرمز؟ أعد الإرسال";
        btn.disabled = false;
    }
});

document.getElementById("resetSubmitBtn")?.addEventListener("click", async () => {
    const newPwd = document.getElementById("resetNewPassword").value;
    const confPwd = document.getElementById("resetConfirmPassword").value;
    setAuthError("");
    if (newPwd.length < 6) { setAuthError("كلمة المرور يجب أن تكون 6 أحرف على الأقل."); return; }
    if (newPwd !== confPwd) { setAuthError("كلمتا المرور غير متطابقتين."); return; }

    const btn = document.getElementById("resetSubmitBtn");
    btn.disabled = true;
    btn.textContent = "جاري...";

    try {
        const resp = await fetch(`${API_BASE}/auth/reset-password`, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ email: pendingOtpEmail, newPassword: newPwd }),
        });
        const data = await resp.json();
        if (!resp.ok) { setAuthError(data.error || "فشل تغيير كلمة المرور."); return; }

        // Auto sign in with new password
        const email = pendingOtpEmail;
        hideOtpStep();
        const cred = await fbAuth.signInWithEmailAndPassword(email, newPwd);
        const fbUser = cred.user;
        const userDoc = await fbDb.collection("users").doc(fbUser.uid).get().catch(() => null);
        const ud = userDoc?.data() || {};
        setStoredUser({
            id: fbUser.uid,
            email: fbUser.email,
            name: ud.name || fbUser.displayName || fbUser.email?.split("@")[0] || "مستخدم",
            phone: ud.phone || "",
            avatar: ud.avatar || "",
        });
        showAuthSuccess();
        updateAuthNav();
    } catch (err) {
        setAuthError(err.message || "حدث خطأ، حاول مرة أخرى.");
    } finally {
        btn.disabled = false;
        btn.textContent = "تغيير كلمة المرور";
    }
});

logoutBtn.addEventListener("click", async () => {
    await handleClientLogout();
});

saveProfileBtn?.addEventListener("click", async () => {
    const current = getStoredUser();
    const fullName = profileNameInput.value.trim();
    const phone = profilePhoneInput.value.replace(/\D/g, "").slice(0, 9);

    if (!current) { closeProfilePanel(); return; }

    if (!hasRequiredFullName(fullName)) {
        setProfileError("يجب إدخال الاسم الأول والاسم الأخير بشكل إجباري.");
        return;
    }

    try {
        await fbDb.collection("users").doc(current.id).set(
            { name: fullName, phone },
            { merge: true }
        );
        const updatedUser = { ...current, name: fullName, phone };
        setStoredUser(updatedUser);
        updateAuthNav();
        openProfileModal();
        alert("تم حفظ التغييرات بنجاح.");
    } catch {
        setProfileError("تعذر حفظ التغييرات. حاول مرة أخرى.");
    }
});

logoutProfileBtn?.addEventListener("click", async () => {
    await handleClientLogout();
    closeProfilePanel();
});

messagesTrigger.addEventListener("click", (e) => {
    e.preventDefault();
    openMessagesModal();
});

messagesAuthBtn.addEventListener("click", () => {
    closeMessages();
    openAuthModal("login");
});

backToMessagesBtn.addEventListener("click", () => {
    if (mediaRecorder && mediaRecorder.state === "recording") {
        mediaRecorder.stop();
    }
    stopRecordingStream();
    resetRecorderUi();
    if (unsubscribeMessages) { unsubscribeMessages(); unsubscribeMessages = null; }
    chatView.classList.add("hidden");
    messagesList.classList.remove("hidden");
    setChatStatus("");
    const user = getStoredUser();
    if (user) {
        messagesSubtitle.textContent = `مرحبًا ${user.name}، هذه آخر محادثاتك.`;
        listenToInbox(renderMessagesInbox);
    }
});

chatForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const text = chatInput.value.trim();
    const currentUser = getStoredUser();
    if (!text || !activeConversationId || !currentUser) return;
    chatInput.value = "";
    try {
        await sendFirebaseMessage(activeConversationId, text, "text");
    } catch {
        setChatStatus("تعذر إرسال الرسالة.");
    }
});

chatImageInput.addEventListener("change", async () => {
    const file = chatImageInput.files?.[0];
    const currentUser = getStoredUser();
    if (!file || !activeConversationId || !currentUser) return;

    if (!file.type.startsWith("image/")) {
        setChatStatus("الملف المختار ليس صورة.");
        chatImageInput.value = "";
        return;
    }

    try {
        setChatStatus("جاري رفع الصورة...");
        const ref = fbStorage.ref(`chat/${activeConversationId}/${Date.now()}_${Math.random().toString(36).slice(2)}`);
        await ref.put(file);
        const url = await ref.getDownloadURL();
        await sendFirebaseMessage(activeConversationId, url, "image");
        setChatStatus("تم إرفاق الصورة.");
    } catch {
        setChatStatus("تعذر رفع الصورة.");
    }
    chatImageInput.value = "";
});

chatRecordBtn.addEventListener("click", async () => {
    if (!activeConversationId || !activeConversationMeta || !getStoredUser()) {
        return;
    }

    if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === "undefined") {
        setChatStatus("التسجيل الصوتي غير مدعوم في هذا المتصفح.");
        return;
    }

    if (mediaRecorder && mediaRecorder.state === "recording") {
        mediaRecorder.stop();
        setChatStatus("جاري تجهيز الرسالة الصوتية...");
        return;
    }

    try {
        audioChunks = [];
        recordingStream = await navigator.mediaDevices.getUserMedia({ audio: true });
        mediaRecorder = new MediaRecorder(recordingStream);
        mediaRecorder.ondataavailable = (event) => {
            if (event.data.size > 0) {
                audioChunks.push(event.data);
            }
        };
        mediaRecorder.onstop = async () => {
            const currentUser = getStoredUser();
            const audioBlob = new Blob(audioChunks, { type: mediaRecorder.mimeType || "audio/webm" });
            resetRecorderUi();
            stopRecordingStream();
            if (currentUser && activeConversationId) {
                try {
                    setChatStatus("جاري رفع الرسالة الصوتية...");
                    const ref = fbStorage.ref(`chat/${activeConversationId}/${Date.now()}_audio`);
                    await ref.put(audioBlob);
                    const url = await ref.getDownloadURL();
                    await sendFirebaseMessage(activeConversationId, url, "audio");
                    setChatStatus("تم إرسال الرسالة الصوتية.");
                } catch {
                    setChatStatus("تعذر إرسال الرسالة الصوتية.");
                }
            }
        };
        mediaRecorder.start();
        chatRecordBtn.classList.add("recording");
        chatRecordBtnText.textContent = "إيقاف";
        setChatStatus("جاري التسجيل الصوتي...");
    } catch {
        resetRecorderUi();
        stopRecordingStream();
        setChatStatus("تعذر الوصول إلى الميكروفون.");
    }
});

postForm.addEventListener("submit", (e) => {
    e.preventDefault();

    const user = getStoredUser();
    if (!user) {
        closePostModalHandler();
        openAuthModal("post");
        return;
    }

    const title = postTitle.value.trim();
    const price = postPrice.value.trim();
    const currency = postCurrency.value.trim();
    const governorate = postLocation.value.trim();
    const category = postCategory.value.trim();
    const subcategory = postSubcategory.value.trim();
    const priceType = postPriceType.value.trim();
    const condition = postCondition.value.trim();
    const description = postDescription.value.trim();
    const images = postImageDataUrls.length ? postImageDataUrls : [];
    const blockedTerm = getBlockedAdTerm(`${title} ${description} ${category} ${subcategory}`);

    if (!title || !governorate || !category || !description) {
        setPostError("يرجى تعبئة جميع الحقول الأساسية واختيار المحافظة قبل نشر الإعلان.");
        return;
    }

    if ((priceType === "fixed" || priceType === "negotiable") && !price) {
        setPostError("يرجى إدخال السعر.");
        return;
    }

    if (!validatePostDraft() || blockedTerm) {
        return;
    }

    openAgreementModal({
        user,
        title,
        price,
        currency,
        governorate,
        category,
        subcategory,
        priceType,
        condition,
        description,
        images,
    });
});

confirmAgreementBtn.addEventListener("click", async () => {
    if (!pendingPostDraft) {
        closeAgreementModalHandler();
        return;
    }

    if (!agreementCheckbox.checked) {
        setAgreementError("يجب الموافقة على المعاهدة قبل نشر الإعلان.");
        return;
    }

    await publishPostDraft(pendingPostDraft);
});

// Firebase auth state listener — runs on every login/logout
fbAuth.onAuthStateChanged(async (firebaseUser) => {
    if (firebaseUser) {
        const userDoc = await fbDb.collection("users").doc(firebaseUser.uid).get().catch(() => null);
        const userData = userDoc?.data() || {};
        setStoredUser({
            id: firebaseUser.uid,
            email: firebaseUser.email,
            name: userData.name || firebaseUser.displayName || firebaseUser.email?.split("@")[0] || "مستخدم",
            phone: userData.phone || "",
            avatar: userData.avatar || "",
        });
    } else {
        clearStoredUser();
    }
    updateAuthNav();
});

// Initialize
window.addEventListener("DOMContentLoaded", async () => {
    loader.style.display = "block";


    updateAuthNav();
    renderCategoryBar();
    renderSubcategoryBar();
    renderGovernorateOptions();
    renderCategoryOptions();
    renderPriceTypeOptions();
    renderCurrencyOptions();
    renderConditionOptions();
    syncSubcategoryOptions();
    validatePostDraft();

    await refreshRemoteState().catch(() => {});
    purgeBlockedStoredPosts();

    const params = new URLSearchParams(window.location.search);
    const listingId = params.get("listing");

    if (listingId) {
        const listing = getListingById(listingId);
        if (listing) {
            if (!getStoredUser()) {
                history.replaceState(null, "", window.location.pathname);
                loader.style.display = "none";
                showListingsPage();
                renderCurrentListings();
                openAuthModal("login");
                return;
            }
            renderListingPage(listing);
            loader.style.display = "none";
            return;
        }
    }

    loader.style.display = "none";
    showListingsPage();
    renderCurrentListings();
});
