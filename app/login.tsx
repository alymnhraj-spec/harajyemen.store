import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { useRouter } from "expo-router";
import React, { useState } from "react";
import {
  Alert,
  Image,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useAuth } from "@/context/AuthContext";
import { useColors } from "@/hooks/useColors";
import { api } from "@/utils/api";

type Step = "phone" | "otp" | "name";

export default function LoginScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { signIn } = useAuth();

  const [step, setStep] = useState<Step>("phone");
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(false);
  const [fakeOtp] = useState(() => Math.floor(1000 + Math.random() * 9000).toString());

  const normalizePhone = (value: string) => {
    const arabicDigits = "٠١٢٣٤٥٦٧٨٩";
    const englishDigits = "0123456789";
    let normalized = String(value || "")
      .split("")
      .map((char) => {
        const index = arabicDigits.indexOf(char);
        return index >= 0 ? englishDigits[index] : char;
      })
      .join("")
      .replace(/\D/g, "");

    if (normalized.startsWith("00967")) {
      normalized = normalized.slice(5);
    } else if (normalized.startsWith("967")) {
      normalized = normalized.slice(3);
    }

    if (normalized.length === 10 && normalized.startsWith("0")) {
      normalized = normalized.slice(1);
    }

    return normalized;
  };

  const topPad = Platform.OS === "web" ? 67 : insets.top;
  const botPad = Platform.OS === "web" ? 34 : insets.bottom;

  const handlePhoneNext = () => {
    const cleaned = phone.replace(/\D/g, "");
    if (cleaned.length < 9) {
      Alert.alert("خطأ", "يرجى إدخال رقم جوال صحيح (9 أرقام)");
      return;
    }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    Alert.alert(
      "رمز التحقق",
      `تم إرسال رمز التحقق إلى رقمك:\n\nرمز التحقق التجريبي: ${fakeOtp}`,
      [{ text: "حسناً" }]
    );
    setStep("otp");
  };

  const handleOtpNext = async () => {
    if (otp.length < 4) {
      Alert.alert("خطأ", "يرجى إدخال رمز التحقق المكون من 4 أرقام");
      return;
    }
    if (otp !== fakeOtp) {
      Alert.alert("خطأ", "رمز التحقق غير صحيح، حاول مرة أخرى");
      setOtp("");
      return;
    }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setLoading(true);
    try {
      const normalizedPhone = normalizePhone(phone);
      const { user } = await api.lookupUserByPhone(normalizedPhone);

      if (user?.name && normalizePhone(user.phone) === normalizedPhone) {
        await signIn(phone, user.name);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        router.replace("/(tabs)/");
        return;
      }

      setStep("name");
    } catch {
      setStep("name");
    } finally {
      setLoading(false);
    }
  };

  const handleSignIn = async () => {
    if (!name.trim() || name.trim().length < 2) {
      Alert.alert("خطأ", "يرجى إدخال اسمك الكامل (حرفان على الأقل)");
      return;
    }
    setLoading(true);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    try {
      await signIn(phone, name.trim());
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      router.replace("/(tabs)/");
    } catch (error) {
      const message =
        error instanceof Error && error.message
          ? error.message
          : "تعذر تسجيل الدخول. تأكد من تشغيل الخادم ثم حاول مرة أخرى.";
      Alert.alert("تعذر الدخول", message);
    } finally {
      setLoading(false);
    }
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
    },
    top: {
      paddingTop: topPad + 20,
      paddingHorizontal: 24,
      paddingBottom: 18,
      alignItems: "center",
      gap: 10,
      backgroundColor: colors.background,
    },
    logoImage: {
      width: 92,
      height: 92,
      borderRadius: 22,
    },
    logoText: {
      fontSize: 28,
      fontFamily: "Cairo_800ExtraBold",
      color: colors.primary,
      textAlign: "center",
    },
    logoSub: {
      fontSize: 14,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
      textAlign: "center",
    },
    card: {
      flex: 1,
      backgroundColor: colors.background,
      paddingHorizontal: 24,
      paddingTop: 10,
      paddingBottom: botPad + 24,
    },
    stepIndicator: {
      flexDirection: "row",
      justifyContent: "center",
      gap: 8,
      marginBottom: 28,
    },
    stepDot: {
      width: 32,
      height: 4,
      borderRadius: 2,
      backgroundColor: colors.border,
    },
    stepDotActive: {
      backgroundColor: colors.primary,
    },
    stepDotDone: {
      backgroundColor: colors.accent,
    },
    stepTitle: {
      fontSize: 24,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
      textAlign: "right",
      marginBottom: 6,
      width: "100%",
    },
    stepDesc: {
      fontSize: 14,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
      textAlign: "right",
      marginBottom: 28,
      lineHeight: 22,
      width: "100%",
    },
    inputLabel: {
      fontSize: 14,
      fontFamily: "Cairo_600SemiBold",
      color: colors.foreground,
      textAlign: "right",
      marginBottom: 8,
      width: "100%",
    },
    inputWrapper: {
      flexDirection: "row-reverse",
      alignItems: "center",
      backgroundColor: colors.card,
      borderWidth: 1.5,
      borderColor: colors.border,
      borderRadius: colors.radius,
      paddingHorizontal: 14,
      height: 54,
      gap: 10,
    },
    inputWrapperFocused: {
      borderColor: colors.primary,
    },
    prefix: {
      fontSize: 16,
      fontFamily: "Cairo_600SemiBold",
      color: colors.mutedForeground,
      paddingLeft: 8,
      borderLeftWidth: 1,
      borderLeftColor: colors.border,
    },
    input: {
      flex: 1,
      fontSize: 18,
      fontFamily: "Cairo_400Regular",
      color: colors.foreground,
      textAlign: "right",
      letterSpacing: 2,
    },
    otpRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      gap: 10,
    },
    otpBox: {
      flex: 1,
      height: 62,
      borderRadius: colors.radius,
      borderWidth: 1.5,
      borderColor: colors.border,
      backgroundColor: colors.card,
      alignItems: "center",
      justifyContent: "center",
    },
    otpBoxActive: {
      borderColor: colors.primary,
      backgroundColor: colors.primary + "10",
    },
    otpText: {
      fontSize: 26,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
    },
    otpInput: {
      position: "absolute",
      opacity: 0,
      width: "100%",
      height: "100%",
    },
    nameInput: {
      backgroundColor: colors.card,
      borderWidth: 1.5,
      borderColor: colors.border,
      borderRadius: colors.radius,
      paddingHorizontal: 14,
      height: 54,
      fontSize: 18,
      fontFamily: "Cairo_400Regular",
      color: colors.foreground,
      textAlign: "right",
    },
    nextBtn: {
      backgroundColor: colors.primary,
      borderRadius: colors.radius,
      height: 54,
      alignItems: "center",
      justifyContent: "center",
      marginTop: 28,
      flexDirection: "row-reverse",
      gap: 10,
    },
    nextBtnDisabled: {
      opacity: 0.6,
    },
    nextBtnText: {
      fontSize: 18,
      fontFamily: "Cairo_700Bold",
      color: "#fff",
    },
    testCodeBox: {
      backgroundColor: colors.accent + "20",
      borderWidth: 1.5,
      borderColor: colors.accent + "60",
      borderRadius: colors.radius,
      paddingVertical: 14,
      paddingHorizontal: 16,
      alignItems: "center",
      marginBottom: 16,
      gap: 4,
    },
    testCodeLabel: {
      fontSize: 12,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
    },
    testCode: {
      fontSize: 32,
      fontFamily: "Cairo_800ExtraBold",
      color: colors.accent,
      letterSpacing: 10,
    },
    resendRow: {
      flexDirection: "row-reverse",
      justifyContent: "center",
      alignItems: "center",
      marginTop: 20,
      gap: 6,
    },
    resendText: {
      fontSize: 14,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
    },
    resendLink: {
      fontSize: 14,
      fontFamily: "Cairo_600SemiBold",
      color: colors.primary,
    },
    backBtn: {
      flexDirection: "row-reverse",
      alignItems: "center",
      gap: 6,
      marginBottom: 16,
      alignSelf: "flex-end",
    },
    backText: {
      fontSize: 14,
      fontFamily: "Cairo_500Medium",
      color: colors.primary,
    },
    terms: {
      fontSize: 12,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
      textAlign: "right",
      marginTop: 16,
      lineHeight: 18,
      width: "100%",
    },
    termsLink: {
      color: colors.primary,
      fontFamily: "Cairo_600SemiBold",
    },
    phoneDisplay: {
      fontSize: 16,
      fontFamily: "Cairo_600SemiBold",
      color: colors.primary,
      textAlign: "right",
      marginBottom: 20,
    },
  });

  return (
    <View style={styles.container}>
      <View style={styles.top}>
        <Image source={require("../assets/images/icon.png")} style={styles.logoImage} resizeMode="contain" />
        <Text style={styles.logoText}>حراج اليمن</Text>
        <Text style={styles.logoSub}>سوقك اليمني الأول</Text>
      </View>

      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        style={{ flex: 1 }}
      >
        <ScrollView
          contentContainerStyle={{ flexGrow: 1 }}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.card}>
            <View style={styles.stepIndicator}>
              {(["phone", "otp", "name"] as Step[]).map((s, i) => (
                <View
                  key={s}
                  style={[
                    styles.stepDot,
                    step === s && styles.stepDotActive,
                    (step === "otp" && i === 0) ||
                    (step === "name" && i <= 1)
                      ? styles.stepDotDone
                      : null,
                  ]}
                />
              ))}
            </View>

            {step === "phone" && (
              <>
                <Text style={styles.stepTitle}>أدخل رقم جوالك</Text>
                <Text style={styles.stepDesc}>
                  سنرسل لك رمز تحقق للتأكد من هويتك
                </Text>
                <Text style={styles.inputLabel}>رقم الجوال</Text>
                <View style={styles.inputWrapper}>
                  <TextInput
                    style={styles.input}
                    value={phone}
                    onChangeText={(t) => setPhone(t.replace(/\D/g, "").slice(0, 9))}
                    placeholder="7XXXXXXXX"
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType="phone-pad"
                    maxLength={9}
                    textAlign="right"
                    autoFocus
                  />
                  <Text style={styles.prefix}>967+</Text>
                </View>
                <TouchableOpacity
                  style={[styles.nextBtn, phone.length < 9 && styles.nextBtnDisabled]}
                  onPress={handlePhoneNext}
                  disabled={phone.length < 9}
                >
                  <Feather name="arrow-left" size={20} color="#fff" />
                  <Text style={styles.nextBtnText}>إرسال رمز التحقق</Text>
                </TouchableOpacity>
                <Text style={styles.terms}>
                  بالمتابعة أنت توافق على{" "}
                  <Text style={styles.termsLink}>شروط الاستخدام</Text>
                  {" "}و{" "}
                  <Text style={styles.termsLink}>سياسة الخصوصية</Text>
                </Text>
              </>
            )}

            {step === "otp" && (
              <>
                <TouchableOpacity style={styles.backBtn} onPress={() => setStep("phone")}>
                  <Feather name="arrow-right" size={18} color={colors.primary} />
                  <Text style={styles.backText}>تغيير الرقم</Text>
                </TouchableOpacity>
                <Text style={styles.stepTitle}>رمز التحقق</Text>
                <Text style={styles.stepDesc}>
                  أدخل الرمز المرسل إلى{"\n"}
                  <Text style={{ color: colors.primary, fontFamily: "Cairo_700Bold" }}>
                    +967 {phone}
                  </Text>
                </Text>
                <View style={styles.testCodeBox}>
                  <Text style={styles.testCodeLabel}>رمز التحقق التجريبي</Text>
                  <Text style={styles.testCode}>{fakeOtp}</Text>
                </View>
                <TextInput
                  style={[styles.nameInput, { letterSpacing: 8, textAlign: "center", fontSize: 22 }]}
                  value={otp}
                  onChangeText={(t) => setOtp(t.replace(/\D/g, "").slice(0, 4))}
                  placeholder="----"
                  placeholderTextColor={colors.mutedForeground}
                  keyboardType="number-pad"
                  maxLength={4}
                  autoFocus
                />
                <TouchableOpacity
                  style={[styles.nextBtn, otp.length < 4 && styles.nextBtnDisabled]}
                  onPress={handleOtpNext}
                  disabled={otp.length < 4 || loading}
                >
                  {loading ? (
                    <Text style={styles.nextBtnText}>جاري التحقق...</Text>
                  ) : (
                    <>
                      <Feather name="check" size={20} color="#fff" />
                      <Text style={styles.nextBtnText}>تأكيد الرمز</Text>
                    </>
                  )}
                </TouchableOpacity>
                <View style={styles.resendRow}>
                  <TouchableOpacity onPress={() => {
                    setOtp("");
                    Alert.alert("تم الإرسال", `رمز التحقق التجريبي: ${fakeOtp}`);
                  }}>
                    <Text style={styles.resendLink}>إعادة الإرسال</Text>
                  </TouchableOpacity>
                  <Text style={styles.resendText}>لم تستلم الرمز؟</Text>
                </View>
              </>
            )}

            {step === "name" && (
              <>
                <Text style={styles.stepTitle}>ما اسمك؟</Text>
                <Text style={styles.stepDesc}>
                  أدخل اسمك الكامل ليتعرف عليك المشترون والبائعون
                </Text>
                <Text style={styles.inputLabel}>الاسم الكامل</Text>
                <TextInput
                  style={styles.nameInput}
                  value={name}
                  onChangeText={setName}
                  placeholder="مثال: محمد أحمد علي"
                  placeholderTextColor={colors.mutedForeground}
                  textAlign="right"
                  autoFocus
                  autoCapitalize="words"
                />
                <TouchableOpacity
                  style={[styles.nextBtn, (loading || name.trim().length < 2) && styles.nextBtnDisabled]}
                  onPress={handleSignIn}
                  disabled={loading || name.trim().length < 2}
                >
                  {loading ? (
                    <Text style={styles.nextBtnText}>جاري الدخول...</Text>
                  ) : (
                    <>
                      <Feather name="arrow-left" size={20} color="#fff" />
                      <Text style={styles.nextBtnText}>دخول</Text>
                    </>
                  )}
                </TouchableOpacity>
              </>
            )}
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}
