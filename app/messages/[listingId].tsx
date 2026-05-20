import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { useLocalSearchParams, useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useListings } from "@/context/ListingsContext";
import { useColors } from "@/hooks/useColors";
import { timeAgo } from "@/utils/helpers";

export default function ListingChatScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const params = useLocalSearchParams<{
    listingId: string;
    receiverId?: string;
    listingTitle?: string;
    sellerName?: string;
  }>();
  const { listings, messages, currentUser, sendMessage } = useListings();
  const [draft, setDraft] = useState("");

  const listing = listings.find((item) => item.id === params.listingId);
  const receiverId = params.receiverId || listing?.userId || "";
  const sellerName = params.sellerName || listing?.userName || "البائع";
  const listingTitle = params.listingTitle || listing?.title || "الإعلان";

  const threadMessages = useMemo(() => {
    if (!currentUser || !params.listingId || !receiverId) return [];
    return messages
      .filter(
        (msg) =>
          msg.listingId === params.listingId &&
          ((msg.senderId === currentUser.id && msg.receiverId === receiverId) ||
            (msg.senderId === receiverId && msg.receiverId === currentUser.id))
      )
      .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
  }, [messages, currentUser, params.listingId, receiverId]);

  const handleSend = async () => {
    if (!currentUser) {
      router.push("/login" as any);
      return;
    }
    if (!draft.trim() || !params.listingId || !receiverId) return;

    await sendMessage({
      listingId: params.listingId,
      listingTitle,
      senderId: currentUser.id,
      receiverId,
      senderName: currentUser.name,
      content: draft.trim(),
    });

    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setDraft("");
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
    },
    header: {
      paddingTop: Platform.OS === "web" ? 24 : insets.top + 12,
      paddingHorizontal: 16,
      paddingBottom: 12,
      backgroundColor: colors.card,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
      gap: 10,
    },
    topRow: {
      flexDirection: "row-reverse",
      alignItems: "center",
      justifyContent: "space-between",
    },
    backBtn: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: colors.muted,
      alignItems: "center",
      justifyContent: "center",
    },
    headerContent: {
      flex: 1,
      alignItems: "flex-end",
      marginRight: 12,
    },
    title: {
      fontSize: 20,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
      textAlign: "right",
    },
    subtitle: {
      fontSize: 13,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
      textAlign: "right",
    },
    warningBox: {
      backgroundColor: colors.accent + "18",
      borderWidth: 1,
      borderColor: colors.accent + "45",
      borderRadius: colors.radius,
      paddingHorizontal: 14,
      paddingVertical: 10,
    },
    warningText: {
      fontSize: 13,
      lineHeight: 22,
      fontFamily: "Cairo_600SemiBold",
      color: colors.foreground,
      textAlign: "right",
    },
    messagesContent: {
      paddingHorizontal: 16,
      paddingTop: 18,
      paddingBottom: 120,
      gap: 10,
    },
    bubbleWrapMine: {
      alignItems: "flex-start",
    },
    bubbleWrapOther: {
      alignItems: "flex-end",
    },
    bubble: {
      maxWidth: "82%",
      borderRadius: 18,
      paddingHorizontal: 14,
      paddingVertical: 10,
    },
    bubbleMine: {
      backgroundColor: colors.primary,
      borderBottomLeftRadius: 6,
    },
    bubbleOther: {
      backgroundColor: colors.card,
      borderWidth: 1,
      borderColor: colors.border,
      borderBottomRightRadius: 6,
    },
    bubbleTextMine: {
      color: "#fff",
    },
    bubbleTextOther: {
      color: colors.foreground,
    },
    bubbleText: {
      fontSize: 14,
      lineHeight: 24,
      fontFamily: "Cairo_500Medium",
      textAlign: "right",
    },
    bubbleTime: {
      fontSize: 11,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
      marginTop: 4,
      textAlign: "right",
    },
    emptyWrap: {
      alignItems: "center",
      justifyContent: "center",
      paddingTop: 80,
      gap: 10,
    },
    emptyText: {
      fontSize: 15,
      fontFamily: "Cairo_500Medium",
      color: colors.mutedForeground,
      textAlign: "center",
    },
    composerWrap: {
      position: "absolute",
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: colors.card,
      borderTopWidth: 1,
      borderTopColor: colors.border,
      paddingHorizontal: 16,
      paddingTop: 10,
      paddingBottom: (Platform.OS === "web" ? 18 : insets.bottom + 10),
      gap: 10,
    },
    input: {
      minHeight: 54,
      maxHeight: 120,
      backgroundColor: colors.background,
      borderWidth: 1,
      borderColor: colors.border,
      borderRadius: colors.radius,
      paddingHorizontal: 14,
      paddingVertical: 12,
      fontSize: 15,
      fontFamily: "Cairo_400Regular",
      color: colors.foreground,
      textAlign: "right",
      textAlignVertical: "top",
    },
    sendBtn: {
      backgroundColor: colors.primary,
      borderRadius: colors.radius,
      paddingVertical: 14,
      alignItems: "center",
      justifyContent: "center",
    },
    sendBtnText: {
      fontSize: 15,
      fontFamily: "Cairo_700Bold",
      color: "#fff",
    },
  });

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.topRow}>
          <TouchableOpacity style={styles.backBtn} onPress={() => router.back()}>
            <Feather name="arrow-right" size={20} color={colors.foreground} />
          </TouchableOpacity>
          <View style={styles.headerContent}>
            <Text style={styles.title}>{sellerName}</Text>
            <Text style={styles.subtitle} numberOfLines={1}>
              {listingTitle}
            </Text>
          </View>
        </View>
        <View style={styles.warningBox}>
          <Text style={styles.warningText}>
            تأكد من السلعة قبل دفع المبلغ وفحصها واستلمها في الوقت المحدد.
          </Text>
        </View>
      </View>

      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === "ios" ? "padding" : undefined}
      >
        <ScrollView
          contentContainerStyle={styles.messagesContent}
          showsVerticalScrollIndicator={false}
          keyboardShouldPersistTaps="handled"
        >
          {threadMessages.length === 0 ? (
            <View style={styles.emptyWrap}>
              <Feather name="message-circle" size={52} color={colors.mutedForeground} />
              <Text style={styles.emptyText}>ابدأ المحادثة مع البائع من هنا</Text>
            </View>
          ) : (
            threadMessages.map((message) => {
              const isMine = message.senderId === currentUser?.id;
              return (
                <View
                  key={message.id}
                  style={isMine ? styles.bubbleWrapMine : styles.bubbleWrapOther}
                >
                  <View style={[styles.bubble, isMine ? styles.bubbleMine : styles.bubbleOther]}>
                    <Text
                      style={[
                        styles.bubbleText,
                        isMine ? styles.bubbleTextMine : styles.bubbleTextOther,
                      ]}
                    >
                      {message.content}
                    </Text>
                    <Text style={styles.bubbleTime}>{timeAgo(message.timestamp)}</Text>
                  </View>
                </View>
              );
            })
          )}
        </ScrollView>

        <View style={styles.composerWrap}>
          <TextInput
            style={styles.input}
            value={draft}
            onChangeText={setDraft}
            placeholder="اكتب رسالتك هنا"
            placeholderTextColor={colors.mutedForeground}
            multiline
            textAlign="right"
          />
          <TouchableOpacity style={styles.sendBtn} onPress={handleSend}>
            <Text style={styles.sendBtnText}>إرسال</Text>
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}
