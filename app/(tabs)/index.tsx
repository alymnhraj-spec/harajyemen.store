import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { useRouter } from "expo-router";
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

import CategoryCard from "@/components/CategoryCard";
import GovernorateSheet from "@/components/GovernorateSheet";
import ListingCard from "@/components/ListingCard";
import SearchBar from "@/components/SearchBar";
import YemenHeader from "@/components/YemenHeader";
import { CATEGORIES } from "@/constants/data";
import { useListings } from "@/context/ListingsContext";
import { useColors } from "@/hooks/useColors";
import { getGovernorateLabel } from "@/utils/helpers";

export default function HomeScreen() {
  const colors = useColors();
  const router = useRouter();
  const { listings } = useListings();
  const [search, setSearch] = useState("");
  const [selectedGov, setSelectedGov] = useState("all");
  const [showGovSheet, setShowGovSheet] = useState(false);

  const recent = useMemo(() => {
    return listings
      .filter(
        (l) =>
          (selectedGov === "all" || l.governorate === selectedGov) &&
          (!search || l.title.includes(search) || l.description.includes(search))
      )
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(0, 20);
  }, [listings, selectedGov, search]);

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
      direction: "rtl",
    },
    searchSection: {
      backgroundColor: colors.primary,
      paddingHorizontal: 16,
      paddingBottom: 16,
    },
    sectionHeader: {
      flexDirection: "row",
      direction: "rtl",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: 16,
      marginTop: 20,
      marginBottom: 12,
    },
    sectionTitle: {
      fontSize: 18,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
      textAlign: "right",
      writingDirection: "rtl",
    },
    seeAll: {
      fontSize: 13,
      fontFamily: "Cairo_500Medium",
      color: colors.primary,
      textAlign: "left",
      writingDirection: "rtl",
    },
    categoriesScroll: {
      paddingHorizontal: 16,
      gap: 10,
      flexDirection: "row-reverse",
      minWidth: "100%",
      justifyContent: "flex-start",
    },
    listContent: {
      paddingHorizontal: 16,
      paddingBottom: Platform.OS === "web" ? 100 : 90,
    },
    banner: {
      marginHorizontal: 16,
      backgroundColor: colors.accent + "20",
      borderRadius: colors.radius,
      borderWidth: 1,
      borderColor: colors.accent + "40",
      padding: 14,
      flexDirection: "row-reverse",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 8,
    },
    bannerText: {
      flex: 1,
      fontSize: 13,
      fontFamily: "Cairo_600SemiBold",
      color: colors.foreground,
      textAlign: "right",
    },
    bannerIcon: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: colors.accent + "30",
      alignItems: "center",
      justifyContent: "center",
    },
    emptyText: {
      textAlign: "center",
      color: colors.mutedForeground,
      fontFamily: "Cairo_400Regular",
      fontSize: 14,
      marginTop: 40,
    },
  });

  return (
    <View style={styles.container}>
      <YemenHeader
        showGovernorate
        governorate={getGovernorateLabel(selectedGov)}
        onGovernoratePress={() => setShowGovSheet(true)}
        showNotif
      />

      <View style={styles.searchSection}>
        <SearchBar value={search} onChangeText={setSearch} />
      </View>

      <FlatList
        data={recent}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => <ListingCard listing={item} />}
        contentContainerStyle={styles.listContent}
        ListHeaderComponent={
          <>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>الأقسام</Text>
              <TouchableOpacity
                onPress={() => router.push("/(tabs)/categories" as any)}
              >
                <Text style={styles.seeAll}>عرض الكل</Text>
              </TouchableOpacity>
            </View>

            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.categoriesScroll}
              style={{ marginBottom: 16 }}
              inverted
            >
              {CATEGORIES.map((cat) => (
                <CategoryCard
                  key={cat.id}
                  {...cat}
                  compact
                  onPress={() => router.push(`/(tabs)/categories?cat=${cat.id}` as any)}
                />
              ))}
            </ScrollView>

            <TouchableOpacity
              style={styles.banner}
              onPress={() => {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                router.push("/(tabs)/post" as any);
              }}
            >
              <View style={styles.bannerIcon}>
                <Feather name="plus-circle" size={22} color={colors.accent} />
              </View>
              <Text style={styles.bannerText}>
                أضف إعلانك مجاناً وابدأ البيع الآن
              </Text>
            </TouchableOpacity>

            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>أحدث الإعلانات</Text>
              <View />
            </View>
          </>
        }
        ListEmptyComponent={
          <Text style={styles.emptyText}>لا توجد إعلانات حالياً</Text>
        }
        showsVerticalScrollIndicator={false}
      />

      <GovernorateSheet
        visible={showGovSheet}
        selected={selectedGov}
        onSelect={setSelectedGov}
        onClose={() => setShowGovSheet(false)}
      />
    </View>
  );
}
