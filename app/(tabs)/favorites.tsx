import { Feather } from "@expo/vector-icons";
import React, { useMemo } from "react";
import {
  FlatList,
  Platform,
  StyleSheet,
  Text,
  View,
} from "react-native";

import ListingCard from "@/components/ListingCard";
import YemenHeader from "@/components/YemenHeader";
import { useListings } from "@/context/ListingsContext";
import { useColors } from "@/hooks/useColors";

export default function FavoritesScreen() {
  const colors = useColors();
  const { listings, favorites } = useListings();

  const favListings = useMemo(
    () => listings.filter((l) => favorites.includes(l.id)),
    [listings, favorites]
  );

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
    },
    listContent: {
      padding: 16,
      paddingBottom: Platform.OS === "web" ? 100 : 90,
    },
    emptyWrap: {
      flex: 1,
      alignItems: "center",
      justifyContent: "center",
      gap: 12,
      paddingBottom: 80,
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
  });

  if (favListings.length === 0) {
    return (
      <View style={styles.container}>
        <YemenHeader title="المفضلة" />
        <View style={styles.emptyWrap}>
          <Feather name="heart" size={56} color={colors.mutedForeground} />
          <Text style={styles.emptyTitle}>المفضلة فارغة</Text>
          <Text style={styles.emptyText}>
            أضف الإعلانات التي تعجبك إلى المفضلة للرجوع إليها لاحقاً
          </Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <YemenHeader title="المفضلة" />
      <FlatList
        data={favListings}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => <ListingCard listing={item} />}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
}
