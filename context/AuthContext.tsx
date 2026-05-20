import AsyncStorage from "@react-native-async-storage/async-storage";
import React, { createContext, useCallback, useContext, useEffect, useState } from "react";
import { api, setApiSessionToken } from "@/utils/api";

export interface AuthUser {
  id: string;
  name: string;
  phone: string;
  avatar?: string;
  sessionToken?: string;
}

interface AuthContextType {
  user: AuthUser | null;
  isLoading: boolean;
  signIn: (phone: string, name: string) => Promise<void>;
  signOut: () => Promise<void>;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const AUTH_KEY = "haraj_auth_user";

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadUser();
  }, []);

  const loadUser = async () => {
    try {
      const stored = await AsyncStorage.getItem(AUTH_KEY);
      if (stored) {
        const parsed = JSON.parse(stored) as AuthUser;
        setApiSessionToken(parsed.sessionToken);
        try {
          const bootstrap = await api.bootstrap();
          const nextUser = (bootstrap.currentUser as AuthUser) || parsed;
          setUser({ ...parsed, ...nextUser, sessionToken: parsed.sessionToken });
          await AsyncStorage.setItem(AUTH_KEY, JSON.stringify({ ...parsed, ...nextUser, sessionToken: parsed.sessionToken }));
        } catch {
          setUser(parsed);
        }
      }
    } catch {}
    setIsLoading(false);
  };

  const signIn = useCallback(async (phone: string, name: string) => {
    const response = await api.signIn(phone, name);
    const newUser: AuthUser = {
      id: response.user.id,
      name: response.user.name,
      phone: response.user.phone,
      avatar: response.user.avatar || "",
      sessionToken: response.sessionToken,
    };
    setApiSessionToken(response.sessionToken);
    setUser(newUser);
    await AsyncStorage.setItem(AUTH_KEY, JSON.stringify(newUser));
  }, []);

  const signOut = useCallback(async () => {
    try {
      await api.signOut();
    } catch {}
    setApiSessionToken("");
    setUser(null);
    await AsyncStorage.removeItem(AUTH_KEY);
  }, []);

  return (
    <AuthContext.Provider
      value={{ user, isLoading, signIn, signOut, isAuthenticated: !!user }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
