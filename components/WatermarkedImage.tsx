import React from "react";
import {
  Image,
  ImageResizeMode,
  ImageStyle,
  StyleProp,
  StyleSheet,
  Text,
  View,
  ViewStyle,
} from "react-native";

import { useColors } from "@/hooks/useColors";

interface WatermarkedImageProps {
  uri: string;
  resizeMode?: ImageResizeMode;
  containerStyle?: StyleProp<ViewStyle>;
  imageStyle?: StyleProp<ImageStyle>;
  compact?: boolean;
}

export default function WatermarkedImage({
  uri,
  resizeMode = "cover",
  containerStyle,
  imageStyle,
  compact = false,
}: WatermarkedImageProps) {
  const colors = useColors();

  const styles = StyleSheet.create({
    container: {
      overflow: "hidden",
      position: "relative",
      backgroundColor: colors.muted,
    },
    image: {
      width: "100%",
      height: "100%",
    },
    watermark: {
      position: "absolute",
      right: compact ? 6 : 10,
      bottom: compact ? 6 : 10,
      backgroundColor: "rgba(0,0,0,0.58)",
      borderRadius: compact ? 8 : 10,
      paddingHorizontal: compact ? 6 : 8,
      paddingVertical: compact ? 2 : 4,
    },
    watermarkText: {
      color: "#fff",
      fontFamily: "Cairo_700Bold",
      fontSize: compact ? 9 : 11,
      lineHeight: compact ? 14 : 18,
    },
  });

  return (
    <View style={[styles.container, containerStyle]}>
      <Image source={{ uri }} style={[styles.image, imageStyle]} resizeMode={resizeMode} />
      <View style={styles.watermark}>
        <Text style={styles.watermarkText}>حراج اليمن</Text>
      </View>
    </View>
  );
}
