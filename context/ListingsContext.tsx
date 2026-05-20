import React, { createContext, useCallback, useContext, useEffect, useState } from "react";
import { useAuth } from "@/context/AuthContext";
import { api } from "@/utils/api";

export interface ListingImage {
  uri: string;
  width?: number;
  height?: number;
}

export interface Listing {
  id: string;
  title: string;
  description: string;
  price: number;
  priceType: "fixed" | "negotiable" | "free" | "exchange";
  category: string;
  subcategory?: string;
  governorate: string;
  condition: string;
  images: ListingImage[];
  userId: string;
  userName: string;
  userPhone?: string;
  createdAt: string;
  views: number;
  favorites: number;
  isFeatured?: boolean;
  currency?: string;
  userAvatar?: string;
}

export interface Message {
  id: string;
  listingId: string;
  listingTitle: string;
  senderId: string;
  receiverId: string;
  senderName: string;
  content: string;
  timestamp: string;
  isRead: boolean;
}

interface ListingsContextType {
  listings: Listing[];
  myListings: Listing[];
  favorites: string[];
  messages: Message[];
  currentUser: { id: string; name: string; phone: string } | null;
  addListing: (listing: Omit<Listing, "id" | "createdAt" | "views" | "favorites">) => void;
  toggleFavorite: (listingId: string) => void;
  sendMessage: (msg: Omit<Message, "id" | "timestamp" | "isRead">) => void;
  incrementViews: (listingId: string) => void;
  deleteListing: (listingId: string) => void;
  setCurrentUser: (user: { id: string; name: string; phone: string }) => void;
}


const ListingsContext = createContext<ListingsContextType | undefined>(undefined);

export function ListingsProvider({ children }: { children: React.ReactNode }) {
  const { user: authUser } = useAuth();
  const [listings, setListings] = useState<Listing[]>([]);
  const [favorites, setFavorites] = useState<string[]>([]);
  const [messages, setMessages] = useState<Message[]>([]);
  const [currentUser, setCurrentUserState] = useState<{ id: string; name: string; phone: string } | null>(null);

  useEffect(() => {
    if (authUser) {
      setCurrentUserState(authUser);
    } else {
      setCurrentUserState(null);
    }
  }, [authUser]);

  useEffect(() => {
    loadData();
  }, [authUser?.id]);

  const loadData = async () => {
    try {
      const bootstrap = await api.bootstrap();
      setListings(Array.isArray(bootstrap.listings) ? (bootstrap.listings as Listing[]) : []);
      setFavorites(Array.isArray(bootstrap.favorites) ? bootstrap.favorites : []);
      setMessages(Array.isArray(bootstrap.messages) ? (bootstrap.messages as Message[]) : []);
      if (bootstrap.currentUser) {
        setCurrentUserState({
          id: bootstrap.currentUser.id,
          name: bootstrap.currentUser.name,
          phone: bootstrap.currentUser.phone,
        });
      } else {
        setCurrentUserState(null);
      }
    } catch {
      setListings([]);
      setFavorites([]);
      setMessages([]);
    }
  };

  const addListing = useCallback(async (listing: Omit<Listing, "id" | "createdAt" | "views" | "favorites">) => {
    const response = await api.addListing(listing as any);
    setListings((prev) => [response.listing as Listing, ...prev]);
  }, []);

  const toggleFavorite = useCallback(async (listingId: string) => {
    if (!currentUser) return;
    const response = await api.toggleFavorite(currentUser.id, listingId);
    setFavorites(response.favorites);
  }, [currentUser]);

  const sendMessage = useCallback(async (msg: Omit<Message, "id" | "timestamp" | "isRead">) => {
    const response = await api.sendMessage(msg as any);
    setMessages((prev) => [...prev, response.message as Message]);
  }, []);

  const incrementViews = useCallback(async (listingId: string) => {
    const response = await api.incrementViews(listingId);
    if (!response.listing) return;
    setListings((prev) =>
      prev.map((l) => (l.id === listingId ? (response.listing as Listing) : l))
    );
  }, []);

  const deleteListing = useCallback(async (listingId: string) => {
    if (!currentUser) return;
    const response = await api.deleteListing(listingId);
    if (!response.success) return;
    setListings((prev) => prev.filter((l) => l.id !== listingId));
  }, [currentUser]);

  const setCurrentUser = useCallback(async (user: { id: string; name: string; phone: string }) => {
    const response = await api.updateUser(user.id, user);
    const nextUser = {
      id: response.user.id,
      name: response.user.name,
      phone: response.user.phone,
    };
    setCurrentUserState(nextUser);
    await loadData();
  }, []);

  const myListings = listings.filter((l) => l.userId === currentUser?.id);

  return (
    <ListingsContext.Provider
      value={{
        listings,
        myListings,
        favorites,
        messages,
        currentUser,
        addListing,
        toggleFavorite,
        sendMessage,
        incrementViews,
        deleteListing,
        setCurrentUser,
      }}
    >
      {children}
    </ListingsContext.Provider>
  );
}

export function useListings() {
  const ctx = useContext(ListingsContext);
  if (!ctx) throw new Error("useListings must be used within ListingsProvider");
  return ctx;
}
