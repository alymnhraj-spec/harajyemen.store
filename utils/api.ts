import Constants from "expo-constants";
import { Platform } from "react-native";

const FALLBACK_WEB_BASE = "http://127.0.0.1:3000";
const FALLBACK_ANDROID_EMULATOR_BASE = "http://10.0.2.2:3000";
const REQUEST_TIMEOUT_MS = 12000;

function getBaseUrl() {
  const envBaseUrl =
    process.env.EXPO_PUBLIC_API_BASE_URL ||
    (globalThis as any)?.process?.env?.EXPO_PUBLIC_API_BASE_URL ||
    "";

  if (envBaseUrl) {
    return envBaseUrl.replace(/\/+$/, "");
  }

  if (Platform.OS === "web" && typeof window !== "undefined") {
    const { hostname, port, origin } = window.location;
    if (hostname === "127.0.0.1" || hostname === "localhost") {
      if (port === "3000") {
        return origin;
      }
      return FALLBACK_WEB_BASE;
    }
    return origin;
  }

  if (Platform.OS === "android") {
    return FALLBACK_ANDROID_EMULATOR_BASE;
  }

  const debuggerHost =
    (Constants as any)?.expoConfig?.hostUri ||
    (Constants as any)?.manifest2?.extra?.expoClient?.hostUri ||
    "";

  if (debuggerHost) {
    const host = String(debuggerHost).split(":")[0];
    return `http://${host}:3000`;
  }

  return FALLBACK_WEB_BASE;
}

export const API_BASE_URL = `${getBaseUrl()}/api`;
let sessionToken = "";

export function setApiSessionToken(token?: string | null) {
  sessionToken = token || "";
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    const response = await fetch(`${API_BASE_URL}${path}`, {
      headers: {
        "content-type": "application/json",
        ...(sessionToken ? { "x-session-token": sessionToken } : {}),
        ...(init?.headers || {}),
      },
      ...init,
      signal: controller.signal,
    });

    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      throw new Error(payload?.error || "Request failed");
    }

    return payload as T;
  } catch (error) {
    if (error instanceof Error && error.name === "AbortError") {
      throw new Error("انتهت مهلة الاتصال بالخادم. تأكد من تشغيل الخادم على المنفذ 3000.");
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}

export interface ApiUser {
  id: string;
  name: string;
  phone: string;
  avatar?: string;
  sessionToken?: string;
}

export interface ApiListingImage {
  uri: string;
  width?: number;
  height?: number;
}

export interface ApiListing {
  id: string;
  title: string;
  description: string;
  price: number;
  currency?: string;
  priceType: "fixed" | "negotiable" | "free" | "exchange";
  category: string;
  subcategory?: string;
  governorate: string;
  condition: string;
  images: ApiListingImage[];
  userId: string;
  userName: string;
  userPhone?: string;
  userAvatar?: string;
  createdAt: string;
  views: number;
  favorites: number;
  isFeatured?: boolean;
}

export interface ApiMessage {
  id: string;
  listingId: string;
  listingTitle: string;
  senderId: string;
  receiverId: string;
  senderName: string;
  content: string;
  timestamp: string;
  isRead: boolean;
  mediaType?: string;
}

export interface BootstrapResponse {
  currentUser: ApiUser | null;
  users: ApiUser[];
  listings: ApiListing[];
  favorites: string[];
  messages: ApiMessage[];
}

export const api = {
  bootstrap: () =>
    request<BootstrapResponse>("/bootstrap"),
  lookupUserByPhone: (phone: string) =>
    request<{ user: ApiUser | null }>(`/auth/lookup?phone=${encodeURIComponent(phone)}`),
  signIn: (phone: string, name: string) =>
    request<{ user: ApiUser; sessionToken: string }>("/auth/signin", {
      method: "POST",
      body: JSON.stringify({ phone, name }),
    }),
  signOut: () =>
    request<{ success: boolean }>("/auth/signout", {
      method: "POST",
    }),
  updateUser: (_userId: string, payload: Partial<ApiUser>) =>
    request<{ user: ApiUser }>(`/users/me`, {
      method: "PATCH",
      body: JSON.stringify(payload),
    }),
  addListing: (payload: Omit<ApiListing, "id" | "createdAt" | "views" | "favorites">) =>
    request<{ listing: ApiListing }>("/listings", {
      method: "POST",
      body: JSON.stringify(payload),
    }),
  deleteListing: (listingId: string) =>
    request<{ success: boolean }>(`/listings/${encodeURIComponent(listingId)}`, {
      method: "DELETE",
    }),
  incrementViews: (listingId: string) =>
    request<{ listing: ApiListing }>(`/listings/${encodeURIComponent(listingId)}/views`, {
      method: "POST",
    }),
  toggleFavorite: (_userId: string, listingId: string) =>
    request<{ favorites: string[] }>("/favorites/toggle", {
      method: "POST",
      body: JSON.stringify({ listingId }),
    }),
  sendMessage: (payload: Omit<ApiMessage, "id" | "timestamp" | "isRead">) =>
    request<{ message: ApiMessage }>("/messages", {
      method: "POST",
      body: JSON.stringify(payload),
    }),
  seedMessage: (payload: Omit<ApiMessage, "id" | "timestamp" | "isRead">) =>
    request<{ message: ApiMessage | null }>("/messages/seed", {
      method: "POST",
      body: JSON.stringify(payload),
    }),
};
