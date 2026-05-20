import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { useLocalSearchParams, useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import {
  Linking,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useListings } from "@/context/ListingsContext";
import { useColors } from "@/hooks/useColors";
import { formatPrice, getCategoryLabel, getGovernorateLabel, timeAgo } from "@/utils/helpers";
import WatermarkedImage from "@/components/WatermarkedImage";

export default function ListingDetailScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { listings, favorites, toggleFavorite, incrementViews, currentUser } = useListings();
  const [showImageViewer, setShowImageViewer] = useState(false);
  const [activeImg, setActiveImg] = useState(0);

  const listing = listings.find((l) => l.id === id);

  useEffect(() => {
    if (listing) {
      incrementViews(listing.id);
    }
  }, [listing?.id]);

  if (!listing) {
    return (
      <View style={{ flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.background }}>
        <Text style={{ color: colors.mutedForeground, fontFamily: "Cairo_400Regular" }}>
          الإعلان غير موجود
        </Text>
      </View>
    );
  }

  const isFav = favorites.includes(listing.id);

  const handleFav = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    toggleFavorite(listing.id);
  };

  const handleCall = () => {
    if (listing.userPhone) {
      Linking.openURL(`tel:+967${listing.userPhone}`);
    }
  };

  const handleWhatsApp = () => {
    if (listing.userPhone) {
      const cleanedPhone = String(listing.userPhone).replace(/\D/g, "");
      const phone = cleanedPhone.startsWith("967") ? cleanedPhone : `967${cleanedPhone}`;
      const text = encodeURIComponent(`مرحباً، بخصوص إعلان: ${listing.title}`);
      Linking.openURL(`https://wa.me/${phone}?text=${text}`);
    }
  };

  const openChat = () => {
    if (!currentUser) {
      router.push("/login" as any);
      return;
    }
    router.push({
      pathname: "/messages/[listingId]",
      params: {
        listingId: listing.id,
        receiverId: listing.userId,
        listingTitle: listing.title,
        sellerName: listing.userName,
      },
    } as any);
  };

  const bottomPad = Platform.OS === "web" ? 34 : insets.bottom;

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
    },
    header: {
      position: "absolute",
      top: Platform.OS === "web" ? 67 : insets.top + 8,
      left: 16,
      right: 16,
      flexDirection: "row",
      justifyContent: "space-between",
      zIndex: 10,
    },
    headerBtn: {
      width: 38,
      height: 38,
      borderRadius: 19,
      backgroundColor: "rgba(255,255,255,0.9)",
      alignItems: "center",
      justifyContent: "center",
    },
    headerRight: {
      flexDirection: "row",
      gap: 10,
    },
    galleryWrap: {
      marginTop: Platform.OS === "web" ? 96 : 0,
      paddingHorizontal: 16,
      paddingTop: 16,
    },
    imageStage: {
      width: "100%",
      height: 380,
      backgroundColor: colors.muted,
      borderRadius: colors.radius,
      overflow: "hidden",
      alignItems: "center",
      justifyContent: "center",
    },
    imageStageButton: {
      width: "100%",
      height: "100%",
    },
    imageContainer: {
      width: "100%",
      height: "100%",
      backgroundColor: colors.muted,
    },
    imagePlaceholder: {
      width: "100%",
      height: 380,
      backgroundColor: colors.muted,
      alignItems: "center",
      justifyContent: "center",
      borderRadius: colors.radius,
      overflow: "hidden",
    },
    thumbsRow: {
      flexDirection: "row-reverse",
      gap: 10,
      marginTop: 12,
    },
    thumbBtn: {
      width: 92,
      height: 92,
      borderRadius: colors.radius,
      overflow: "hidden",
      borderWidth: 1,
      borderColor: colors.border,
      backgroundColor: colors.muted,
    },
    thumbBtnActive: {
      borderWidth: 2,
      borderColor: colors.primary,
    },
    thumbImage: {
      width: "100%",
      height: "100%",
    },
    viewerOverlay: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.94)",
    },
    viewerHeader: {
      position: "absolute",
      top: Platform.OS === "web" ? 20 : insets.top + 8,
      right: 16,
      left: 16,
      zIndex: 20,
      flexDirection: "row-reverse",
      alignItems: "center",
      justifyContent: "space-between",
    },
    viewerHeaderBtn: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: "rgba(255,255,255,0.12)",
      alignItems: "center",
      justifyContent: "center",
    },
    viewerCounter: {
      fontSize: 14,
      fontFamily: "Cairo_700Bold",
      color: "#fff",
      backgroundColor: "rgba(255,255,255,0.12)",
      borderRadius: 20,
      paddingHorizontal: 14,
      paddingVertical: 7,
    },
    viewerScroll: {
      flex: 1,
    },
    viewerContent: {
      flexGrow: 1,
      alignItems: "center",
      justifyContent: "center",
      paddingHorizontal: 16,
      paddingTop: 70,
      paddingBottom: 120,
    },
    viewerImageWrap: {
      width: "100%",
      height: "100%",
      minHeight: 420,
      alignItems: "center",
      justifyContent: "center",
    },
    viewerImage: {
      width: "100%",
      height: "100%",
    },
    viewerHint: {
      position: "absolute",
      bottom: Platform.OS === "web" ? 18 : insets.bottom + 12,
      alignSelf: "center",
      fontSize: 13,
      lineHeight: 22,
      fontFamily: "Cairo_500Medium",
      color: "rgba(255,255,255,0.84)",
      backgroundColor: "rgba(255,255,255,0.10)",
      borderRadius: 16,
      paddingHorizontal: 14,
      paddingVertical: 8,
      textAlign: "center",
    },
    body: {
      padding: 16,
    },
    titleRow: {
      flexDirection: "row",
      alignItems: "flex-start",
      justifyContent: "space-between",
      gap: 8,
      marginBottom: 8,
    },
    title: {
      flex: 1,
      fontSize: 20,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
      textAlign: "right",
    },
    price: {
      fontSize: 22,
      fontFamily: "Cairo_700Bold",
      color: colors.primary,
      textAlign: "right",
      marginBottom: 4,
    },
    priceType: {
      fontSize: 13,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
      textAlign: "right",
      marginBottom: 16,
    },
    tagsRow: {
      flexDirection: "row",
      flexWrap: "wrap",
      gap: 8,
      marginBottom: 16,
      justifyContent: "flex-end",
    },
    tag: {
      flexDirection: "row",
      alignItems: "center",
      gap: 4,
      backgroundColor: colors.muted,
      paddingHorizontal: 10,
      paddingVertical: 5,
      borderRadius: 20,
    },
    tagText: {
      fontSize: 12,
      fontFamily: "Cairo_500Medium",
      color: colors.mutedForeground,
    },
    divider: {
      height: 1,
      backgroundColor: colors.border,
      marginVertical: 16,
    },
    sectionTitle: {
      fontSize: 16,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
      textAlign: "right",
      marginBottom: 8,
    },
    description: {
      fontSize: 15,
      fontFamily: "Cairo_400Regular",
      color: colors.foreground,
      lineHeight: 24,
      textAlign: "right",
    },
    sellerCard: {
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      padding: 16,
      borderWidth: 1,
      borderColor: colors.border,
      flexDirection: "row-reverse",
      alignItems: "center",
      gap: 12,
      marginBottom: 80,
    },
    sellerInfo: {
      flex: 1,
      alignItems: "flex-end",
    },
    sellerName: {
      fontSize: 16,
      fontFamily: "Cairo_600SemiBold",
      color: colors.foreground,
    },
    sellerSince: {
      fontSize: 12,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
    },
    sellerAvatar: {
      width: 52,
      height: 52,
      borderRadius: 26,
      backgroundColor: colors.primary,
      alignItems: "center",
      justifyContent: "center",
    },
    sellerAvatarText: {
      fontSize: 20,
      fontFamily: "Cairo_700Bold",
      color: "#fff",
    },
    footer: {
      position: "absolute",
      bottom: 0,
      left: 0,
      right: 0,
      backgroundColor: colors.card,
      borderTopWidth: 1,
      borderTopColor: colors.border,
      paddingHorizontal: 16,
      paddingTop: 12,
      paddingBottom: bottomPad + 12,
      flexDirection: "row-reverse",
      gap: 10,
    },
    msgBtn: {
      flex: 1,
      backgroundColor: colors.muted,
      borderRadius: colors.radius,
      paddingVertical: 14,
      alignItems: "center",
      flexDirection: "row-reverse",
      justifyContent: "center",
      gap: 8,
    },
    msgBtnText: {
      fontSize: 15,
      fontFamily: "Cairo_600SemiBold",
      color: colors.foreground,
    },
    callBtn: {
      flex: 1,
      backgroundColor: colors.primary,
      borderRadius: colors.radius,
      paddingVertical: 14,
      alignItems: "center",
      flexDirection: "row-reverse",
      justifyContent: "center",
      gap: 8,
    },
    whatsappBtn: {
      flex: 1,
      backgroundColor: "#25D366",
      borderRadius: colors.radius,
      paddingVertical: 14,
      alignItems: "center",
      flexDirection: "row-reverse",
      justifyContent: "center",
      gap: 8,
    },
    whatsappBtnText: {
      fontSize: 15,
      fontFamily: "Cairo_700Bold",
      color: "#fff",
    },
    callBtnText: {
      fontSize: 15,
      fontFamily: "Cairo_700Bold",
      color: "#fff",
    },
  });

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerRight}>
          <TouchableOpacity style={styles.headerBtn} onPress={handleFav}>
            <Feather
              name="heart"
              size={20}
              color={isFav ? colors.secondary : colors.foreground}
            />
          </TouchableOpacity>
          <TouchableOpacity style={styles.headerBtn}>
            <Feather name="share-2" size={20} color={colors.foreground} />
          </TouchableOpacity>
        </View>
        <TouchableOpacity style={styles.headerBtn} onPress={() => router.back()}>
          <Feather name="arrow-right" size={20} color={colors.foreground} />
        </TouchableOpacity>
      </View>

      <ScrollView showsVerticalScrollIndicator={false}>
        {listing.images.length > 0 ? (
          <View style={styles.galleryWrap}>
            <View style={styles.imageStage}>
              <TouchableOpacity
                style={styles.imageStageButton}
                activeOpacity={0.95}
                onPress={() => setShowImageViewer(true)}
              >
                <WatermarkedImage
                  uri={listing.images[activeImg]?.uri || listing.images[0]?.uri}
                  containerStyle={styles.imageContainer}
                  resizeMode="contain"
                />
              </TouchableOpacity>
            </View>
            {listing.images.length > 1 && (
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.thumbsRow}
                inverted
              >
                {listing.images.map((img, i) => (
                  <TouchableOpacity
                    key={i}
                    style={[styles.thumbBtn, i === activeImg && styles.thumbBtnActive]}
                    onPress={() => setActiveImg(i)}
                    activeOpacity={0.85}
                  >
                    <WatermarkedImage
                      uri={img.uri}
                      containerStyle={styles.thumbImage}
                      resizeMode="cover"
                      compact
                    />
                  </TouchableOpacity>
                ))}
              </ScrollView>
            )}
          </View>
        ) : (
          <View style={styles.galleryWrap}>
            <View style={styles.imagePlaceholder}>
              <Feather name="image" size={60} color={colors.mutedForeground} />
            </View>
          </View>
        )}

        <View style={styles.body}>
          <Text style={styles.title}>{listing.title}</Text>
          <Text style={styles.price}>
            {listing.priceType === "free"
              ? "مجاني"
              : listing.priceType === "exchange"
              ? "للمبادلة"
              : formatPrice(listing.price, listing.currency)}
          </Text>
          <Text style={styles.priceType}>
            {listing.priceType === "negotiable"
              ? "قابل للتفاوض"
              : listing.priceType === "fixed"
              ? "سعر ثابت"
              : ""}
          </Text>

          <View style={styles.tagsRow}>
            <View style={styles.tag}>
              <Feather name="clock" size={12} color={colors.mutedForeground} />
              <Text style={styles.tagText}>{timeAgo(listing.createdAt)}</Text>
            </View>
            <View style={styles.tag}>
              <Feather name="eye" size={12} color={colors.mutedForeground} />
              <Text style={styles.tagText}>{listing.views} مشاهدة</Text>
            </View>
            <View style={styles.tag}>
              <Feather name="map-pin" size={12} color={colors.mutedForeground} />
              <Text style={styles.tagText}>{getGovernorateLabel(listing.governorate)}</Text>
            </View>
            <View style={styles.tag}>
              <Feather name="tag" size={12} color={colors.mutedForeground} />
              <Text style={styles.tagText}>{getCategoryLabel(listing.category)}</Text>
            </View>
          </View>

          <View style={styles.divider} />

          <Text style={styles.sectionTitle}>وصف الإعلان</Text>
          <Text style={styles.description}>{listing.description}</Text>

          <View style={styles.divider} />

          <Text style={styles.sectionTitle}>معلومات البائع</Text>
          <View style={styles.sellerCard}>
            <View style={styles.sellerAvatar}>
              <Text style={styles.sellerAvatarText}>
                {listing.userName.charAt(0)}
              </Text>
            </View>
            <View style={styles.sellerInfo}>
              <Text style={styles.sellerName}>{listing.userName}</Text>
              {listing.userPhone && (
                <Text style={styles.sellerSince}>{listing.userPhone}</Text>
              )}
            </View>
          </View>
        </View>
      </ScrollView>

      <View style={styles.footer}>
        <TouchableOpacity style={styles.msgBtn} onPress={openChat}>
          <Feather name="message-circle" size={18} color={colors.foreground} />
          <Text style={styles.msgBtnText}>مراسلة</Text>
        </TouchableOpacity>
        {listing.userPhone && (
          <TouchableOpacity style={styles.whatsappBtn} onPress={handleWhatsApp}>
            <Feather name="message-square" size={18} color="#fff" />
            <Text style={styles.whatsappBtnText}>واتساب</Text>
          </TouchableOpacity>
        )}
        {listing.userPhone && (
          <TouchableOpacity style={styles.callBtn} onPress={handleCall}>
            <Feather name="phone" size={18} color="#fff" />
            <Text style={styles.callBtnText}>اتصال</Text>
          </TouchableOpacity>
        )}
      </View>

      <Modal
        visible={showImageViewer}
        transparent={false}
        animationType="fade"
        onRequestClose={() => setShowImageViewer(false)}
      >
        <View style={styles.viewerOverlay}>
          <View style={styles.viewerHeader}>
            <TouchableOpacity
              style={styles.viewerHeaderBtn}
              onPress={() => setShowImageViewer(false)}
            >
              <Feather name="x" size={20} color="#fff" />
            </TouchableOpacity>
            <Text style={styles.viewerCounter}>
              {activeImg + 1} / {listing.images.length}
            </Text>
          </View>

          <ScrollView
            style={styles.viewerScroll}
            contentContainerStyle={styles.viewerContent}
            maximumZoomScale={4}
            minimumZoomScale={1}
            centerContent
            showsHorizontalScrollIndicator={false}
            showsVerticalScrollIndicator={false}
          >
            <View style={styles.viewerImageWrap}>
              <WatermarkedImage
                uri={listing.images[activeImg]?.uri || listing.images[0]?.uri}
                containerStyle={styles.viewerImage}
                resizeMode="contain"
              />
            </View>
          </ScrollView>

          <Text style={styles.viewerHint}>
            انقر بإصبعين للتكبير على الجوال، أو استخدم اللمس للفحص
          </Text>
        </View>
      </Modal>
    </View>
  );
}
