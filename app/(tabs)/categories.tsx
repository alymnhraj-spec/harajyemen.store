import { Feather } from "@expo/vector-icons";
import { useLocalSearchParams, useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  FlatList,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import ListingCard from "@/components/ListingCard";
import SearchBar from "@/components/SearchBar";
import YemenHeader from "@/components/YemenHeader";
import { CATEGORIES } from "@/constants/data";
import { useListings } from "@/context/ListingsContext";
import { useColors } from "@/hooks/useColors";

export default function CategoriesScreen() {
  const colors = useColors();
  const router = useRouter();
  const params = useLocalSearchParams<{ cat?: string }>();
  const { listings } = useListings();
  const [selectedCat, setSelectedCat] = useState<string>(params.cat ?? "");
  const [selectedSub, setSelectedSub] = useState<string>("");
  const [search, setSearch] = useState("");
  const [sortBy, setSortBy] = useState<"newest" | "price_low" | "price_high">("newest");

  const currentCategory = CATEGORIES.find((c) => c.id === selectedCat);

  const filtered = useMemo(() => {
    let list = listings.filter(
      (l) =>
        (!selectedCat || l.category === selectedCat) &&
        (!selectedSub || l.subcategory === selectedSub) &&
        (!search || l.title.includes(search) || l.description.includes(search))
    );
    if (sortBy === "newest")
      list = list.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    else if (sortBy === "price_low") list = list.sort((a, b) => a.price - b.price);
    else list = list.sort((a, b) => b.price - a.price);
    return list;
  }, [listings, selectedCat, selectedSub, search, sortBy]);

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
      direction: "rtl",
    },
    searchRow: {
      paddingHorizontal: 16,
      paddingVertical: 12,
      backgroundColor: colors.card,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    catScrollWrap: {
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
      backgroundColor: colors.card,
    },
    catScroll: {
      paddingHorizontal: 12,
      paddingVertical: 10,
      gap: 8,
      flexDirection: "row-reverse",
      minWidth: "100%",
      justifyContent: "flex-start",
    },
    catChip: {
      paddingHorizontal: 14,
      paddingVertical: 7,
      borderRadius: 20,
      borderWidth: 1,
      borderColor: colors.border,
      backgroundColor: colors.background,
    },
    catChipActive: {
      backgroundColor: colors.primary,
      borderColor: colors.primary,
    },
    catChipText: {
      fontSize: 13,
      fontFamily: "Cairo_500Medium",
      color: colors.foreground,
    },
    catChipTextActive: {
      color: "#fff",
    },
    subCatRow: {
      paddingHorizontal: 12,
      paddingVertical: 8,
      gap: 8,
      flexDirection: "row-reverse",
      minWidth: "100%",
      justifyContent: "flex-start",
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    sortRow: {
      flexDirection: "row-reverse",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: 16,
      paddingVertical: 10,
      gap: 8,
    },
    sortChip: {
      paddingHorizontal: 12,
      paddingVertical: 6,
      borderRadius: 16,
      backgroundColor: colors.muted,
    },
    sortChipActive: {
      backgroundColor: colors.primary,
    },
    sortText: {
      fontSize: 12,
      fontFamily: "Cairo_500Medium",
      color: colors.mutedForeground,
    },
    sortTextActive: {
      color: "#fff",
    },
    countText: {
      fontSize: 13,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
    },
    listContent: {
      padding: 16,
      paddingBottom: Platform.OS === "web" ? 100 : 90,
    },
    emptyWrap: {
      alignItems: "center",
      paddingTop: 60,
      gap: 12,
    },
    emptyText: {
      fontSize: 15,
      fontFamily: "Cairo_500Medium",
      color: colors.mutedForeground,
    },
  });

  return (
    <View style={styles.container}>
      <YemenHeader title="الأقسام" />

      <View style={styles.searchRow}>
        <SearchBar value={search} onChangeText={setSearch} placeholder="ابحث في القسم..." />
      </View>

      <View style={styles.catScrollWrap}>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.catScroll}
          inverted
        >
          <TouchableOpacity
            style={[styles.catChip, !selectedCat && styles.catChipActive]}
            onPress={() => { setSelectedCat(""); setSelectedSub(""); }}
          >
            <Text style={[styles.catChipText, !selectedCat && styles.catChipTextActive]}>
              الكل
            </Text>
          </TouchableOpacity>
          {CATEGORIES.map((cat) => (
            <TouchableOpacity
              key={cat.id}
              style={[styles.catChip, selectedCat === cat.id && styles.catChipActive]}
              onPress={() => { setSelectedCat(cat.id); setSelectedSub(""); }}
            >
              <Text
                style={[
                  styles.catChipText,
                  selectedCat === cat.id && styles.catChipTextActive,
                ]}
              >
                {cat.name}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {currentCategory && currentCategory.subcategories.length > 0 && (
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.subCatRow}
            inverted
          >
            <TouchableOpacity
              style={[styles.catChip, !selectedSub && styles.catChipActive]}
              onPress={() => setSelectedSub("")}
            >
              <Text style={[styles.catChipText, !selectedSub && styles.catChipTextActive]}>
                الكل
              </Text>
            </TouchableOpacity>
            {currentCategory.subcategories.map((sub) => (
              <TouchableOpacity
                key={sub}
                style={[styles.catChip, selectedSub === sub && styles.catChipActive]}
                onPress={() => setSelectedSub(sub)}
              >
                <Text
                  style={[
                    styles.catChipText,
                    selectedSub === sub && styles.catChipTextActive,
                  ]}
                >
                  {sub}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        )}
      </View>

      <View style={styles.sortRow}>
        {(["newest", "price_low", "price_high"] as const).map((s) => (
          <TouchableOpacity
            key={s}
            style={[styles.sortChip, sortBy === s && styles.sortChipActive]}
            onPress={() => setSortBy(s)}
          >
            <Text style={[styles.sortText, sortBy === s && styles.sortTextActive]}>
              {s === "newest" ? "الأحدث" : s === "price_low" ? "أقل سعر" : "أعلى سعر"}
            </Text>
          </TouchableOpacity>
        ))}
        <Text style={styles.countText}>{filtered.length} إعلان</Text>
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(i) => i.id}
        renderItem={({ item }) => <ListingCard listing={item} />}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
        ListEmptyComponent={
          <View style={styles.emptyWrap}>
            <Feather name="inbox" size={48} color={colors.mutedForeground} />
            <Text style={styles.emptyText}>لا توجد إعلانات في هذا القسم</Text>
          </View>
        }
      />
    </View>
  );
}
