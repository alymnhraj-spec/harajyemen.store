import { Feather } from "@expo/vector-icons";
import React from "react";
import {
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";

import { useColors } from "@/hooks/useColors";

interface SearchBarProps {
  value: string;
  onChangeText: (text: string) => void;
  placeholder?: string;
  onFilterPress?: () => void;
}

export default function SearchBar({ value, onChangeText, placeholder, onFilterPress }: SearchBarProps) {
  const colors = useColors();

  const styles = StyleSheet.create({
    container: {
      flexDirection: "row-reverse",
      alignItems: "center",
      gap: 8,
      direction: "rtl",
    },
    inputWrapper: {
      flex: 1,
      flexDirection: "row-reverse",
      alignItems: "center",
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      borderWidth: 1,
      borderColor: colors.border,
      paddingHorizontal: 12,
      height: 44,
      gap: 8,
    },
    input: {
      flex: 1,
      fontSize: 14,
      fontFamily: "Cairo_400Regular",
      color: colors.foreground,
      textAlign: "right",
      writingDirection: "rtl",
    },
    filterBtn: {
      width: 44,
      height: 44,
      borderRadius: colors.radius,
      backgroundColor: colors.primary,
      alignItems: "center",
      justifyContent: "center",
    },
  });

  return (
    <View style={styles.container}>
      {onFilterPress && (
        <TouchableOpacity style={styles.filterBtn} onPress={onFilterPress}>
          <Feather name="sliders" size={20} color="#fff" />
        </TouchableOpacity>
      )}
      <View style={styles.inputWrapper}>
        <TextInput
          style={styles.input}
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder ?? "ابحث في الإعلانات..."}
          placeholderTextColor={colors.mutedForeground}
          returnKeyType="search"
        />
        <Feather name="search" size={18} color={colors.mutedForeground} />
      </View>
    </View>
  );
}
