import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useMemo } from "react";
import {
  FlatList,
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import YemenHeader from "@/components/YemenHeader";
import { useListings } from "@/context/ListingsContext";
import { useColors } from "@/hooks/useColors";
import { timeAgo } from "@/utils/helpers";

export default function MessagesScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { messages, currentUser } = useListings();

  const myMessages = useMemo(() => {
    const grouped = messages.reduce<Record<string, typeof messages[0]>>((acc, msg) => {
      const key = msg.listingId + (msg.senderId === currentUser?.id ? msg.receiverId : msg.senderId);
      if (!acc[key] || new Date(msg.timestamp) > new Date(acc[key].timestamp)) {
        acc[key] = msg;
      }
      return acc;
    }, {});
    return Object.values(grouped).sort(
      (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    );
  }, [messages, currentUser]);

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
    },
    item: {
      backgroundColor: colors.card,
      paddingHorizontal: 16,
      paddingVertical: 14,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
      flexDirection: "row-reverse",
      alignItems: "center",
      gap: 12,
    },
    avatar: {
      width: 48,
      height: 48,
      borderRadius: 24,
      backgroundColor: colors.primary + "20",
      alignItems: "center",
      justifyContent: "center",
    },
    avatarText: {
      fontSize: 18,
      fontFamily: "Cairo_700Bold",
      color: colors.primary,
    },
    content: {
      flex: 1,
    },
    topRow: {
      flexDirection: "row-reverse",
      justifyContent: "space-between",
      alignItems: "center",
      marginBottom: 4,
    },
    name: {
      fontSize: 15,
      fontFamily: "Cairo_600SemiBold",
      color: colors.foreground,
    },
    time: {
      fontSize: 11,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
    },
    listing: {
      fontSize: 12,
      fontFamily: "Cairo_400Regular",
      color: colors.primary,
      marginBottom: 2,
      textAlign: "right",
    },
    lastMsg: {
      fontSize: 13,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
      textAlign: "right",
    },
    unreadDot: {
      width: 8,
      height: 8,
      borderRadius: 4,
      backgroundColor: colors.secondary,
    },
    emptyWrap: {
      flex: 1,
      alignItems: "center",
      justifyContent: "center",
      gap: 12,
    },
    emptyTitle: {
      fontSize: 17,
      fontFamily: "Cairo_600SemiBold",
      color: colors.foreground,
    },
    emptyText: {
      fontSize: 14,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
      textAlign: "center",
      paddingHorizontal: 32,
    },
    content2: {
      paddingBottom: Platform.OS === "web" ? 100 : 90,
    },
  });

  if (myMessages.length === 0) {
    return (
      <View style={styles.container}>
        <YemenHeader title="الرسائل" />
        <View style={styles.emptyWrap}>
          <Feather name="message-circle" size={56} color={colors.mutedForeground} />
          <Text style={styles.emptyTitle}>لا توجد رسائل</Text>
          <Text style={styles.emptyText}>
            ابدأ محادثة مع البائع من صفحة الإعلان
          </Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <YemenHeader title="الرسائل" />
      <FlatList
        data={myMessages}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.content2}
        renderItem={({ item }) => {
          const otherName =
            item.senderId === currentUser?.id ? "البائع" : item.senderName;
          const receiverId =
            item.senderId === currentUser?.id ? item.receiverId : item.senderId;
          return (
            <TouchableOpacity
              style={styles.item}
              onPress={() =>
                router.push({
                  pathname: "/messages/[listingId]",
                  params: {
                    listingId: item.listingId,
                    receiverId,
                    listingTitle: item.listingTitle,
                    sellerName: otherName,
                  },
                } as any)
              }
            >
              <View style={styles.avatar}>
                <Text style={styles.avatarText}>{otherName.charAt(0)}</Text>
              </View>
              <View style={styles.content}>
                <View style={styles.topRow}>
                  <View style={styles.unreadDot} />
                  <Text style={styles.time}>{timeAgo(item.timestamp)}</Text>
                  <Text style={styles.name}>{otherName}</Text>
                </View>
                <Text style={styles.listing} numberOfLines={1}>
                  {item.listingTitle}
                </Text>
                <Text style={styles.lastMsg} numberOfLines={1}>
                  {item.content}
                </Text>
              </View>
            </TouchableOpacity>
          );
        }}
      />
    </View>
  );
}
