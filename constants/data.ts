export const YEMEN_GOVERNORATES = [
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

export const CATEGORIES = [
  {
    id: "cars",
    name: "سيارات",
    icon: "navigation",
    color: "#1B6B3A",
    subcategories: ["سيارات جديدة", "سيارات مستعملة", "دراجات نارية", "قطع غيار"],
  },
  {
    id: "real_estate",
    name: "عقارات",
    icon: "home",
    color: "#CE1126",
    subcategories: ["شقق للبيع", "شقق للإيجار", "أراضي", "فلل ومنازل", "محلات تجارية"],
  },
  {
    id: "electronics",
    name: "إلكترونيات",
    icon: "smartphone",
    color: "#D4AF37",
    subcategories: ["هواتف", "أجهزة لوحية", "كمبيوترات", "شاشات", "كاميرات"],
  },
  {
    id: "furniture",
    name: "أثاث ومنزل",
    icon: "package",
    color: "#6B3A1B",
    subcategories: ["غرف نوم", "صالات", "مطابخ", "ديكور", "أجهزة منزلية"],
  },
  {
    id: "fashion",
    name: "ملابس وأزياء",
    icon: "shopping-bag",
    color: "#8B1B6B",
    subcategories: ["رجالي", "نسائي", "أطفال", "أحذية", "حقائب"],
  },
  {
    id: "jobs",
    name: "وظائف",
    icon: "briefcase",
    color: "#1B4B6B",
    subcategories: ["وظائف حكومية", "قطاع خاص", "عمل حر", "تدريب"],
  },
  {
    id: "animals",
    name: "حيوانات",
    icon: "globe",
    color: "#3A6B1B",
    subcategories: ["مواشي", "طيور", "حيوانات أليفة"],
  },
  {
    id: "agriculture",
    name: "زراعة ومزارع",
    icon: "sun",
    color: "#6B6B1B",
    subcategories: ["أراضي زراعية", "معدات زراعية", "محاصيل"],
  },
  {
    id: "services",
    name: "خدمات",
    icon: "tool",
    color: "#6B1B1B",
    subcategories: ["صيانة", "نقل", "تعليم", "تصميم", "مطاعم"],
  },
  {
    id: "sports",
    name: "رياضة وترفيه",
    icon: "activity",
    color: "#1B6B6B",
    subcategories: ["أجهزة رياضية", "ألعاب", "كتب"],
  },
];

export const SORT_OPTIONS = [
  { id: "newest", name: "الأحدث" },
  { id: "oldest", name: "الأقدم" },
  { id: "price_low", name: "السعر: الأقل" },
  { id: "price_high", name: "السعر: الأعلى" },
];

export const PRICE_TYPES = [
  { id: "fixed", name: "سعر ثابت" },
  { id: "negotiable", name: "قابل للتفاوض" },
  { id: "free", name: "مجاناً" },
  { id: "exchange", name: "للمبادلة" },
];

export const CURRENCY_TYPES = [
  { id: "yer", name: "ريال يمني", symbol: "ر.ي" },
  { id: "sar", name: "ريال سعودي", symbol: "ر.س" },
  { id: "usd", name: "دولار", symbol: "$" },
];

export const CONDITION_TYPES = [
  { id: "new", name: "جديد" },
  { id: "like_new", name: "شبه جديد" },
  { id: "good", name: "حالة جيدة" },
  { id: "acceptable", name: "حالة مقبولة" },
];
