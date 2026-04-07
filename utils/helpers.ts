import { CATEGORIES, YEMEN_GOVERNORATES } from "@/constants/data";

export function formatPrice(price: number, currency = "yer"): string {
  const symbol = currency === "usd" ? "$" : currency === "sar" ? "ر.س" : "ر.ي";
  const locale = "en-US";

  if (currency === "usd" || currency === "sar") {
    return `${price.toLocaleString(locale)} ${symbol}`;
  }

  if (price >= 1000000) {
    const millions = price / 1000000;
    if (millions === Math.floor(millions)) {
      return `${millions.toLocaleString(locale)} مليون ${symbol}`;
    }
    return `${millions.toFixed(1)} مليون ${symbol}`;
  }
  if (price >= 1000) {
    const thousands = price / 1000;
    if (thousands === Math.floor(thousands)) {
      return `${thousands.toLocaleString(locale)} ألف ${symbol}`;
    }
    return `${thousands.toFixed(1)} ألف ${symbol}`;
  }
  return `${price.toLocaleString(locale)} ${symbol}`;
}

export function getGovernorateLabel(id: string): string {
  const gov = YEMEN_GOVERNORATES.find((g) => g.id === id);
  if (!gov) return id;
  const name = gov.name;
  if (name === "أمانة العاصمة صنعاء") return "صنعاء";
  return name;
}

export function getCategoryLabel(id: string): string {
  const cat = CATEGORIES.find((c) => c.id === id);
  return cat?.name ?? id;
}

export function timeAgo(dateStr: string): string {
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

export function generateId(): string {
  return Date.now().toString() + Math.random().toString(36).substr(2, 9);
}
