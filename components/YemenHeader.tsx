import { Feather } from "@expo/vector-icons";
import React from "react";
import {
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useColors } from "@/hooks/useColors";

interface YemenHeaderProps {
  title?: string;
  subtitle?: string;
  showGovernorate?: boolean;
  governorate?: string;
  onGovernoratePress?: () => void;
  showNotif?: boolean;
  rightAction?: React.ReactNode;
}

export default function YemenHeader({
  title,
  subtitle,
  showGovernorate,
  governorate,
  onGovernoratePress,
  showNotif,
  rightAction,
}: YemenHeaderProps) {
  const colors = useColors();
  const insets = useSafeAreaInsets();

  const topPad = Platform.OS === "web" ? 67 : insets.top;

  const styles = StyleSheet.create({
    container: {
      backgroundColor: colors.primary,
      paddingTop: topPad + 8,
      paddingBottom: 20,
      paddingHorizontal: 16,
    },
    row: {
      flexDirection: "row-reverse",
      alignItems: "center",
      justifyContent: "space-between",
      direction: "rtl",
    },
    leftActions: {
      flexDirection: "row-reverse",
      alignItems: "center",
      gap: 12,
    },
    titleBlock: {
      flex: 1,
      alignItems: "center",
      justifyContent: "center",
    },
    title: {
      fontSize: 20,
      fontFamily: "Cairo_700Bold",
      color: "#FFFFFF",
    },
    subtitle: {
      fontSize: 12,
      fontFamily: "Cairo_400Regular",
      color: "rgba(255,255,255,0.8)",
      marginTop: 2,
    },
    govBtn: {
      flexDirection: "row-reverse",
      alignItems: "center",
      gap: 4,
      backgroundColor: "rgba(255,255,255,0.15)",
      paddingHorizontal: 10,
      paddingVertical: 5,
      borderRadius: 20,
      marginTop: 8,
      alignSelf: "flex-start",
    },
    govText: {
      fontSize: 12,
      fontFamily: "Cairo_500Medium",
      color: "#FFFFFF",
    },
    notifBtn: {
      width: 36,
      height: 36,
      borderRadius: 18,
      backgroundColor: "rgba(255,255,255,0.15)",
      alignItems: "center",
      justifyContent: "center",
    },
    logoText: {
      fontSize: 30,
      fontFamily: "Cairo_700Bold",
      color: "#D4AF37",
      letterSpacing: 0.5,
      lineHeight: 40,
    },
  });

  return (
    <View style={styles.container}>
      <View style={styles.row}>
        <View style={styles.leftActions}>
          {showNotif && (
            <TouchableOpacity style={styles.notifBtn}>
              <Feather name="bell" size={20} color="#fff" />
            </TouchableOpacity>
          )}
          {rightAction}
        </View>

        <View style={styles.titleBlock}>
          {title ? (
            <Text style={styles.title}>{title}</Text>
          ) : (
            <Text style={styles.logoText}>حراج اليمن</Text>
          )}
          {subtitle && <Text style={styles.subtitle}>{subtitle}</Text>}
        </View>

        <View style={{ width: 36 + 12 + (showNotif ? 36 : 0) }} />
      </View>

      {showGovernorate && (
        <TouchableOpacity style={styles.govBtn} onPress={onGovernoratePress}>
          <Feather name="chevron-down" size={12} color="#fff" />
          <Text style={styles.govText}>{governorate ?? "كل المحافظات"}</Text>
          <Feather name="map-pin" size={12} color="#fff" />
        </TouchableOpacity>
      )}
    </View>
  );
}
