import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { useRouter } from "expo-router";
import React, { useState } from "react";
import {
  Alert,
  FlatList,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import ListingCard from "@/components/ListingCard";
import YemenHeader from "@/components/YemenHeader";
import { useAuth } from "@/context/AuthContext";
import { useListings } from "@/context/ListingsContext";
import { useColors } from "@/hooks/useColors";

export default function ProfileScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { currentUser, myListings, deleteListing, setCurrentUser } = useListings();
  const { user, signOut } = useAuth();
  const [editMode, setEditMode] = useState(false);
  const [name, setName] = useState(currentUser?.name ?? "");
  const [phone, setPhone] = useState(currentUser?.phone ?? "");

  const handleSignOut = () => {
    Alert.alert("تسجيل الخروج", "هل أنت متأكد من تسجيل الخروج؟", [
      { text: "إلغاء", style: "cancel" },
      {
        text: "خروج",
        style: "destructive",
        onPress: async () => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
          await signOut();
          router.replace("/login");
        },
      },
    ]);
  };

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert("خطأ", "يرجى إدخال الاسم");
      return;
    }
    await setCurrentUser({ id: currentUser?.id ?? "me", name: name.trim(), phone: phone.trim() });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setEditMode(false);
  };

  const handleDelete = (id: string) => {
    Alert.alert("حذف الإعلان", "هل أنت متأكد من حذف هذا الإعلان؟", [
      { text: "إلغاء", style: "cancel" },
      {
        text: "حذف",
        style: "destructive",
        onPress: () => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
          deleteListing(id);
        },
      },
    ]);
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
    },
    profileCard: {
      backgroundColor: colors.card,
      marginHorizontal: 16,
      marginTop: 16,
      borderRadius: colors.radius,
      padding: 20,
      borderWidth: 1,
      borderColor: colors.border,
      alignItems: "center",
      gap: 12,
      marginBottom: 20,
    },
    avatar: {
      width: 80,
      height: 80,
      borderRadius: 40,
      backgroundColor: colors.primary,
      alignItems: "center",
      justifyContent: "center",
    },
    avatarText: {
      fontSize: 32,
      fontFamily: "Cairo_700Bold",
      color: "#fff",
    },
    name: {
      fontSize: 20,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
    },
    phone: {
      fontSize: 14,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
    },
    statsRow: {
      flexDirection: "row",
      gap: 24,
    },
    statItem: {
      alignItems: "center",
      gap: 2,
    },
    statNum: {
      fontSize: 22,
      fontFamily: "Cairo_700Bold",
      color: colors.primary,
    },
    statLabel: {
      fontSize: 12,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
    },
    editBtn: {
      flexDirection: "row",
      alignItems: "center",
      gap: 6,
      paddingHorizontal: 16,
      paddingVertical: 8,
      borderRadius: 20,
      borderWidth: 1,
      borderColor: colors.primary,
    },
    editBtnText: {
      fontSize: 13,
      fontFamily: "Cairo_500Medium",
      color: colors.primary,
    },
    editCard: {
      backgroundColor: colors.card,
      marginHorizontal: 16,
      marginBottom: 20,
      borderRadius: colors.radius,
      padding: 16,
      borderWidth: 1,
      borderColor: colors.border,
      gap: 12,
    },
    editTitle: {
      fontSize: 16,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
      textAlign: "right",
    },
    inputRow: {
      gap: 6,
    },
    inputLabel: {
      fontSize: 13,
      fontFamily: "Cairo_500Medium",
      color: colors.foreground,
      textAlign: "right",
    },
    input: {
      backgroundColor: colors.background,
      borderWidth: 1,
      borderColor: colors.border,
      borderRadius: colors.radius,
      paddingHorizontal: 12,
      paddingVertical: 10,
      fontSize: 15,
      fontFamily: "Cairo_400Regular",
      color: colors.foreground,
      textAlign: "right",
    },
    saveBtn: {
      backgroundColor: colors.primary,
      borderRadius: colors.radius,
      paddingVertical: 12,
      alignItems: "center",
    },
    saveBtnText: {
      fontSize: 15,
      fontFamily: "Cairo_700Bold",
      color: "#fff",
    },
    sectionTitle: {
      fontSize: 17,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
      textAlign: "right",
      paddingHorizontal: 16,
      marginBottom: 12,
    },
    listContent: {
      paddingHorizontal: 16,
      paddingBottom: Platform.OS === "web" ? 100 : 90,
    },
    emptyWrap: {
      alignItems: "center",
      paddingTop: 32,
      gap: 10,
    },
    emptyText: {
      fontSize: 14,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
    },
    deleteBtn: {
      backgroundColor: colors.destructive + "15",
      borderRadius: 8,
      paddingHorizontal: 10,
      paddingVertical: 6,
      flexDirection: "row",
      alignItems: "center",
      gap: 4,
    },
    deleteBtnText: {
      fontSize: 12,
      color: colors.destructive,
      fontFamily: "Cairo_500Medium",
    },
    listingWithDelete: {
      position: "relative",
    },
    deleteOverlay: {
      position: "absolute",
      top: 10,
      left: 10,
      zIndex: 10,
    },
    signOutBtn: {
      flexDirection: "row",
      alignItems: "center",
      gap: 6,
      paddingHorizontal: 16,
      paddingVertical: 8,
      borderRadius: 20,
      borderWidth: 1,
      borderColor: colors.destructive + "60",
    },
    signOutText: {
      fontSize: 13,
      fontFamily: "Cairo_500Medium",
      color: colors.destructive,
    },
    btnRow: {
      flexDirection: "row",
      gap: 10,
      marginTop: 4,
    },
    guestCard: {
      backgroundColor: colors.card,
      marginHorizontal: 16,
      marginTop: 16,
      borderRadius: colors.radius,
      padding: 24,
      borderWidth: 1,
      borderColor: colors.border,
      alignItems: "center",
      gap: 14,
      marginBottom: 20,
    },
    guestIcon: {
      width: 72,
      height: 72,
      borderRadius: 36,
      backgroundColor: colors.muted,
      alignItems: "center",
      justifyContent: "center",
    },
    guestTitle: {
      fontSize: 20,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
      textAlign: "center",
    },
    guestText: {
      fontSize: 14,
      lineHeight: 26,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
      textAlign: "center",
    },
    loginBtn: {
      backgroundColor: colors.primary,
      borderRadius: colors.radius,
      paddingHorizontal: 24,
      paddingVertical: 12,
      alignItems: "center",
      justifyContent: "center",
      minWidth: 180,
    },
    loginBtnText: {
      fontSize: 15,
      fontFamily: "Cairo_700Bold",
      color: "#fff",
    },
  });

  if (!user || !currentUser) {
    return (
      <View style={styles.container}>
        <YemenHeader title="حسابي" />
        <View style={styles.guestCard}>
          <View style={styles.guestIcon}>
            <Feather name="user" size={30} color={colors.mutedForeground} />
          </View>
          <Text style={styles.guestTitle}>أنت غير مسجل الدخول</Text>
          <Text style={styles.guestText}>
            سجل الدخول للوصول إلى حسابك وإعلاناتك والمفضلة والرسائل.
          </Text>
          <TouchableOpacity
            style={styles.loginBtn}
            onPress={() => router.push("/login" as any)}
          >
            <Text style={styles.loginBtnText}>تسجيل الدخول</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <YemenHeader title="حسابي" />
      <FlatList
        data={myListings}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
        renderItem={({ item }) => (
          <View style={styles.listingWithDelete}>
            <ListingCard listing={item} />
            <TouchableOpacity
              style={styles.deleteOverlay}
              onPress={() => handleDelete(item.id)}
            >
              <View style={styles.deleteBtn}>
                <Feather name="trash-2" size={12} color={colors.destructive} />
                <Text style={styles.deleteBtnText}>حذف</Text>
              </View>
            </TouchableOpacity>
          </View>
        )}
        ListHeaderComponent={
          <>
            <View style={styles.profileCard}>
              <View style={styles.avatar}>
                <Text style={styles.avatarText}>
                  {(currentUser?.name ?? "م").charAt(0)}
                </Text>
              </View>
              <Text style={styles.name}>{currentUser?.name ?? "المستخدم"}</Text>
              {currentUser?.phone ? (
                <Text style={styles.phone}>{currentUser.phone}</Text>
              ) : null}

              <View style={styles.statsRow}>
                <View style={styles.statItem}>
                  <Text style={styles.statNum}>{myListings.length}</Text>
                  <Text style={styles.statLabel}>إعلاناتي</Text>
                </View>
              </View>

              <View style={styles.btnRow}>
                <TouchableOpacity
                  style={styles.signOutBtn}
                  onPress={handleSignOut}
                >
                  <Text style={styles.signOutText}>خروج</Text>
                  <Feather name="log-out" size={14} color={colors.destructive} />
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.editBtn}
                  onPress={() => setEditMode((p) => !p)}
                >
                  <Text style={styles.editBtnText}>
                    {editMode ? "إلغاء" : "تعديل"}
                  </Text>
                  <Feather name={editMode ? "x" : "edit-2"} size={14} color={colors.primary} />
                </TouchableOpacity>
              </View>
            </View>

            {editMode && (
              <View style={styles.editCard}>
                <Text style={styles.editTitle}>تعديل البيانات</Text>
                <View style={styles.inputRow}>
                  <Text style={styles.inputLabel}>الاسم</Text>
                  <TextInput
                    style={styles.input}
                    value={name}
                    onChangeText={setName}
                    placeholder="أدخل اسمك"
                    placeholderTextColor={colors.mutedForeground}
                    textAlign="right"
                  />
                </View>
                <View style={styles.inputRow}>
                  <Text style={styles.inputLabel}>رقم الهاتف</Text>
                  <TextInput
                    style={styles.input}
                    value={phone}
                    onChangeText={setPhone}
                    placeholder="7XXXXXXXX"
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType="phone-pad"
                    textAlign="right"
                  />
                </View>
                <TouchableOpacity style={styles.saveBtn} onPress={handleSave}>
                  <Text style={styles.saveBtnText}>حفظ التغييرات</Text>
                </TouchableOpacity>
              </View>
            )}

            <Text style={styles.sectionTitle}>إعلاناتي ({myListings.length})</Text>
          </>
        }
        ListEmptyComponent={
          <View style={styles.emptyWrap}>
            <Feather name="package" size={48} color={colors.mutedForeground} />
            <Text style={styles.emptyText}>لا توجد إعلانات بعد</Text>
          </View>
        }
      />
    </View>
  );
}
