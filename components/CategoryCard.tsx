import { Feather } from "@expo/vector-icons";
import React from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";

import { useColors } from "@/hooks/useColors";

interface CategoryCardProps {
  id: string;
  name: string;
  icon: string;
  color: string;
  onPress: () => void;
  compact?: boolean;
}

export default function CategoryCard({ name, icon, color, onPress, compact }: CategoryCardProps) {
  const colors = useColors();

  const styles = StyleSheet.create({
    container: {
      alignItems: "center",
      gap: 6,
      padding: compact ? 8 : 12,
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      borderWidth: 1,
      borderColor: colors.border,
      minWidth: compact ? 70 : 80,
    },
    iconWrap: {
      width: compact ? 40 : 48,
      height: compact ? 40 : 48,
      borderRadius: compact ? 20 : 24,
      backgroundColor: color + "20",
      alignItems: "center",
      justifyContent: "center",
    },
    name: {
      fontSize: compact ? 11 : 12,
      fontFamily: "Cairo_600SemiBold",
      color: colors.foreground,
      textAlign: "center",
    },
  });

  return (
    <TouchableOpacity style={styles.container} onPress={onPress} activeOpacity={0.8}>
      <View style={styles.iconWrap}>
        <Feather name={icon as any} size={compact ? 20 : 22} color={color} />
      </View>
      <Text style={styles.name}>{name}</Text>
    </TouchableOpacity>
  );
}
