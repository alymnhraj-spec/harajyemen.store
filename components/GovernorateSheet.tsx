import { Feather } from "@expo/vector-icons";
import React from "react";
import {
  FlatList,
  Modal,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { YEMEN_GOVERNORATES } from "@/constants/data";
import { useColors } from "@/hooks/useColors";

interface GovernorateSheetProps {
  visible: boolean;
  selected: string;
  onSelect: (id: string) => void;
  onClose: () => void;
}

export default function GovernorateSheet({ visible, selected, onSelect, onClose }: GovernorateSheetProps) {
  const colors = useColors();
  const insets = useSafeAreaInsets();

  const styles = StyleSheet.create({
    overlay: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.5)",
      justifyContent: "flex-end",
    },
    sheet: {
      backgroundColor: colors.card,
      borderTopLeftRadius: 20,
      borderTopRightRadius: 20,
      paddingBottom: insets.bottom + 16,
      maxHeight: "80%",
    },
    handle: {
      width: 40,
      height: 4,
      borderRadius: 2,
      backgroundColor: colors.border,
      alignSelf: "center",
      marginTop: 12,
      marginBottom: 8,
    },
    header: {
      flexDirection: "row-reverse",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: 16,
      paddingVertical: 12,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    title: {
      fontSize: 16,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
    },
    item: {
      flexDirection: "row-reverse",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: 16,
      paddingVertical: 14,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    itemText: {
      fontSize: 15,
      fontFamily: "Cairo_400Regular",
      color: colors.foreground,
      textAlign: "right",
      writingDirection: "rtl",
    },
    selectedText: {
      color: colors.primary,
      fontFamily: "Cairo_600SemiBold",
    },
  });

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <TouchableOpacity style={styles.overlay} activeOpacity={1} onPress={onClose}>
        <View style={styles.sheet}>
          <View style={styles.handle} />
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose}>
              <Feather name="x" size={22} color={colors.foreground} />
            </TouchableOpacity>
            <Text style={styles.title}>اختر المحافظة</Text>
            <View style={{ width: 22 }} />
          </View>
          <FlatList
            data={YEMEN_GOVERNORATES}
            keyExtractor={(item) => item.id}
            renderItem={({ item }) => (
              <TouchableOpacity
                style={styles.item}
                onPress={() => {
                  onSelect(item.id);
                  onClose();
                }}
              >
                {selected === item.id && (
                  <Feather name="check" size={18} color={colors.primary} />
                )}
                <Text
                  style={[styles.itemText, selected === item.id && styles.selectedText]}
                >
                  {item.name}
                </Text>
              </TouchableOpacity>
            )}
          />
        </View>
      </TouchableOpacity>
    </Modal>
  );
}
