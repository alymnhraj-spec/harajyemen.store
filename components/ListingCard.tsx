import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { useRouter } from "expo-router";
import React from "react";
import {
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import { Listing, useListings } from "@/context/ListingsContext";
import { useColors } from "@/hooks/useColors";
import { formatPrice, getGovernorateLabel, timeAgo } from "@/utils/helpers";
import WatermarkedImage from "@/components/WatermarkedImage";

interface ListingCardProps {
  listing: Listing;
  variant?: "default" | "compact" | "featured";
}

export default function ListingCard({ listing, variant = "default" }: ListingCardProps) {
  const colors = useColors();
  const router = useRouter();
  const { favorites, toggleFavorite } = useListings();
  const isFav = favorites.includes(listing.id);

  const handlePress = () => {
    router.push(`/listing/${listing.id}` as any);
  };

  const handleFav = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    toggleFavorite(listing.id);
  };

  const styles = StyleSheet.create({
    container: {
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      overflow: "hidden",
      borderWidth: 1,
      borderColor: colors.border,
      marginBottom: 12,
      ...(Platform.OS === "ios"
        ? { shadowColor: "#000", shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.06, shadowRadius: 6 }
        : { elevation: 2 }),
    },
    row: {
      flexDirection: "row-reverse",
      minHeight: 132,
    },
    mediaWrap: {
      width: 132,
      minHeight: 132,
      backgroundColor: colors.muted,
      flexShrink: 0,
    },
    image: {
      width: "100%",
      height: "100%",
      backgroundColor: colors.muted,
    },
    imagePlaceholder: {
      width: "100%",
      height: "100%",
      backgroundColor: colors.muted,
      alignItems: "center",
      justifyContent: "center",
    },
    body: {
      padding: 12,
      direction: "rtl",
      flex: 1,
      justifyContent: "space-between",
    },
    title: {
      fontSize: 15,
      fontFamily: "Cairo_600SemiBold",
      color: colors.foreground,
      marginBottom: 4,
      textAlign: "right",
    },
    priceRow: {
      flexDirection: "row-reverse",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 8,
    },
    price: {
      fontSize: 16,
      fontFamily: "Cairo_700Bold",
      color: colors.primary,
    },
    priceType: {
      fontSize: 11,
      color: colors.mutedForeground,
      fontFamily: "Cairo_400Regular",
    },
    description: {
      fontSize: 13,
      lineHeight: 24,
      color: colors.mutedForeground,
      fontFamily: "Cairo_400Regular",
      textAlign: "right",
      marginBottom: 10,
    },
    metaRow: {
      flexDirection: "row-reverse",
      alignItems: "center",
      justifyContent: "space-between",
    },
    metaLeft: {
      flexDirection: "row-reverse",
      alignItems: "center",
      gap: 8,
    },
    metaItem: {
      flexDirection: "row-reverse",
      alignItems: "center",
      gap: 3,
    },
    metaText: {
      fontSize: 11,
      color: colors.mutedForeground,
      fontFamily: "Cairo_400Regular",
    },
    favBtn: {
      width: 32,
      height: 32,
      borderRadius: 16,
      backgroundColor: colors.muted,
      alignItems: "center",
      justifyContent: "center",
    },
    governorate: {
      flexDirection: "row-reverse",
      alignItems: "center",
      gap: 3,
      backgroundColor: colors.muted,
      paddingHorizontal: 6,
      paddingVertical: 2,
      borderRadius: 6,
    },
    governorateText: {
      fontSize: 11,
      color: colors.mutedForeground,
      fontFamily: "Cairo_500Medium",
    },
  });

  return (
    <TouchableOpacity style={styles.container} onPress={handlePress} activeOpacity={0.85}>
      <View style={styles.row}>
        <View style={styles.mediaWrap}>
          {listing.images.length > 0 ? (
            <WatermarkedImage
              uri={listing.images[0].uri}
              containerStyle={styles.image}
              resizeMode="cover"
              compact
            />
          ) : (
            <View style={styles.imagePlaceholder}>
              <Feather name="image" size={32} color={colors.mutedForeground} />
            </View>
          )}
        </View>

        <View style={styles.body}>
          <View>
            <Text style={styles.title} numberOfLines={2}>
              {listing.title}
            </Text>

            <View style={styles.priceRow}>
              <Text style={styles.priceType}>
                {listing.priceType === "negotiable"
                  ? "قابل للتفاوض"
                  : listing.priceType === "free"
                  ? "مجاناً"
                  : listing.priceType === "exchange"
                  ? "للمبادلة"
                  : ""}
              </Text>
              <Text style={styles.price}>
                {listing.priceType === "free"
                  ? "مجاني"
                  : listing.priceType === "exchange"
                  ? "مبادلة"
                  : formatPrice(listing.price, listing.currency)}
              </Text>
            </View>

            <Text style={styles.description} numberOfLines={2}>
              {listing.description || "لا يوجد وصف للإعلان"}
            </Text>
          </View>

          <View style={styles.metaRow}>
            <TouchableOpacity style={styles.favBtn} onPress={handleFav}>
              <Feather
                name="heart"
                size={16}
                color={isFav ? colors.secondary : colors.mutedForeground}
              />
            </TouchableOpacity>

            <View style={styles.metaLeft}>
              <View style={styles.metaItem}>
                <Feather name="eye" size={12} color={colors.mutedForeground} />
                <Text style={styles.metaText}>{listing.views}</Text>
              </View>
              <View style={styles.governorate}>
                <Feather name="map-pin" size={10} color={colors.mutedForeground} />
                <Text style={styles.governorateText}>{getGovernorateLabel(listing.governorate)}</Text>
              </View>
              <Text style={styles.metaText}>{timeAgo(listing.createdAt)}</Text>
            </View>
          </View>
        </View>
      </View>
    </TouchableOpacity>
  );
}
