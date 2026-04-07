import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import * as ImagePicker from "expo-image-picker";
import { useRouter } from "expo-router";
import React, { useState } from "react";
import {
  Image,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import GovernorateSheet from "@/components/GovernorateSheet";
import YemenHeader from "@/components/YemenHeader";
import { CATEGORIES, CONDITION_TYPES, CURRENCY_TYPES, PRICE_TYPES } from "@/constants/data";
import { useListings } from "@/context/ListingsContext";
import { useColors } from "@/hooks/useColors";
import { getGovernorateLabel } from "@/utils/helpers";

export default function PostScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { addListing, currentUser } = useListings();

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState("");
  const [currency, setCurrency] = useState<"yer" | "sar" | "usd">("yer");
  const [priceType, setPriceType] = useState<"fixed" | "negotiable" | "free" | "exchange">("fixed");
  const [category, setCategory] = useState("");
  const [subcategory, setSubcategory] = useState("");
  const [governorate, setGovernorate] = useState("sanaa");
  const [condition, setCondition] = useState("good");
  const [images, setImages] = useState<{ uri: string }[]>([]);
  const [showGovSheet, setShowGovSheet] = useState(false);
  const [loading, setLoading] = useState(false);
  const [showCommitmentModal, setShowCommitmentModal] = useState(false);
  const [commitmentAccepted, setCommitmentAccepted] = useState(false);
  const [submitError, setSubmitError] = useState("");
  const [submitSuccess, setSubmitSuccess] = useState("");

  const currentCat = CATEGORIES.find((c) => c.id === category);

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsMultipleSelection: true,
      quality: 0.8,
      selectionLimit: 10,
    });
    if (!result.canceled) {
      const newImgs = result.assets.map((a) => ({ uri: a.uri }));
      setImages((prev) => [...prev, ...newImgs].slice(0, 10));
    }
  };

  const validateForm = () => {
    if (!currentUser) {
      setSubmitError("يجب تسجيل الدخول قبل نشر الإعلان");
      return false;
    }
    if (!title.trim()) {
      setSubmitError("يرجى إدخال عنوان الإعلان");
      return false;
    }
    if (!category) {
      setSubmitError("يرجى اختيار القسم");
      return false;
    }
    if (!description.trim()) {
      setSubmitError("يرجى كتابة وصف الإعلان");
      return false;
    }
    if ((priceType === "fixed" || priceType === "negotiable") && !(Number(price) > 0)) {
      setSubmitError("يرجى إدخال سعر صحيح");
      return false;
    }
    setSubmitError("");
    return true;
  };

  const handleSubmit = () => {
    setSubmitSuccess("");
    if (!currentUser) {
      setSubmitError("يجب تسجيل الدخول قبل نشر الإعلان");
      router.push("/login" as any);
      return;
    }
    setSubmitError("");
    setCommitmentAccepted(false);
    setShowCommitmentModal(true);
  };

  const confirmSubmit = async () => {
    if (!validateForm()) return;
    if (!currentUser) {
      setSubmitError("يجب تسجيل الدخول قبل نشر الإعلان");
      setShowCommitmentModal(false);
      return;
    }
    if (!commitmentAccepted) {
      setSubmitError("يجب الموافقة على التعهد قبل نشر الإعلان");
      return;
    }

    setSubmitError("");
    setLoading(true);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    try {
      await addListing({
        title: title.trim(),
        description: description.trim(),
        price: priceType === "free" || priceType === "exchange" ? 0 : Number(price) || 0,
        currency,
        priceType,
        category,
        subcategory: subcategory || undefined,
        governorate,
        condition,
        images,
        userId: currentUser.id,
        userName: currentUser.name,
        userPhone: currentUser.phone,
      });

      setShowCommitmentModal(false);
      setCommitmentAccepted(false);
      setSubmitSuccess("تم نشر إعلانك بنجاح");
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      setTitle("");
      setDescription("");
      setPrice("");
      setCurrency("yer");
      setCategory("");
      setSubcategory("");
      setImages([]);
      router.push("/(tabs)/" as any);
    } catch (error: any) {
      setSubmitError(error?.message || "حدث خطأ أثناء نشر الإعلان");
    } finally {
      setLoading(false);
    }
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
      direction: "rtl",
    },
    scroll: {
      paddingHorizontal: 16,
      paddingTop: 16,
      paddingBottom: insets.bottom + 120,
    },
    section: {
      marginBottom: 20,
    },
    label: {
      fontSize: 14,
      fontFamily: "Cairo_600SemiBold",
      color: colors.foreground,
      marginBottom: 8,
      textAlign: "right",
    },
    required: {
      color: colors.secondary,
    },
    input: {
      backgroundColor: colors.card,
      borderWidth: 1,
      borderColor: colors.border,
      borderRadius: colors.radius,
      paddingHorizontal: 14,
      paddingVertical: 12,
      fontSize: 15,
      fontFamily: "Cairo_400Regular",
      color: colors.foreground,
      textAlign: "right",
    },
    textarea: {
      height: 100,
      textAlignVertical: "top",
    },
    chipsRow: {
      flexDirection: "row-reverse",
      flexWrap: "wrap",
      gap: 8,
      justifyContent: "flex-start",
    },
    chip: {
      paddingHorizontal: 12,
      paddingVertical: 7,
      borderRadius: 20,
      borderWidth: 1,
      borderColor: colors.border,
      backgroundColor: colors.card,
    },
    chipActive: {
      backgroundColor: colors.primary,
      borderColor: colors.primary,
    },
    chipText: {
      fontSize: 13,
      fontFamily: "Cairo_500Medium",
      color: colors.foreground,
    },
    chipTextActive: {
      color: "#fff",
    },
    govBtn: {
      backgroundColor: colors.card,
      borderWidth: 1,
      borderColor: colors.border,
      borderRadius: colors.radius,
      paddingHorizontal: 14,
      paddingVertical: 12,
      flexDirection: "row-reverse",
      alignItems: "center",
      justifyContent: "space-between",
    },
    govBtnText: {
      fontSize: 15,
      fontFamily: "Cairo_400Regular",
      color: colors.foreground,
    },
    imagesGrid: {
      flexDirection: "row-reverse",
      flexWrap: "wrap",
      gap: 8,
    },
    addImageBtn: {
      width: 90,
      height: 90,
      borderRadius: colors.radius,
      borderWidth: 1.5,
      borderColor: colors.border,
      borderStyle: "dashed",
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: colors.muted,
      gap: 4,
    },
    addImageText: {
      fontSize: 11,
      fontFamily: "Cairo_400Regular",
      color: colors.mutedForeground,
    },
    imageThumb: {
      width: 90,
      height: 90,
      borderRadius: colors.radius,
      overflow: "hidden",
    },
    imageThumbImg: {
      width: "100%",
      height: "100%",
    },
    removeImg: {
      position: "absolute",
      top: 4,
      right: 4,
      backgroundColor: "rgba(0,0,0,0.6)",
      borderRadius: 10,
      width: 20,
      height: 20,
      alignItems: "center",
      justifyContent: "center",
    },
    priceRow: {
      flexDirection: "row-reverse",
      gap: 8,
      alignItems: "center",
    },
    priceInput: {
      flex: 1,
    },
    currency: {
      fontSize: 14,
      fontFamily: "Cairo_500Medium",
      color: colors.mutedForeground,
      textAlign: "right",
    },
    submitBtn: {
      backgroundColor: colors.primary,
      borderRadius: colors.radius,
      paddingVertical: 16,
      alignItems: "center",
      marginBottom: 16,
    },
    submitBtnText: {
      fontSize: 16,
      fontFamily: "Cairo_700Bold",
      color: "#fff",
    },
    feedbackText: {
      fontSize: 14,
      fontFamily: "Cairo_600SemiBold",
      textAlign: "right",
      marginBottom: 12,
    },
    errorText: {
      color: colors.secondary,
    },
    successText: {
      color: colors.primary,
    },
    modalOverlay: {
      position: "absolute",
      top: 0,
      right: 0,
      bottom: 0,
      left: 0,
      backgroundColor: "rgba(0,0,0,0.35)",
      alignItems: "center",
      justifyContent: "center",
      padding: 16,
      zIndex: 1000,
    },
    modalCard: {
      width: "100%",
      maxWidth: 520,
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      padding: 18,
      borderWidth: 1,
      borderColor: colors.border,
      direction: "rtl",
    },
    modalTitle: {
      fontSize: 22,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
      textAlign: "right",
      marginBottom: 12,
    },
    verseText: {
      fontSize: 16,
      lineHeight: 32,
      fontFamily: "Cairo_500Medium",
      color: colors.mutedForeground,
      textAlign: "center",
      marginBottom: 10,
    },
    verseConfirm: {
      fontSize: 16,
      lineHeight: 30,
      fontFamily: "Cairo_700Bold",
      color: colors.mutedForeground,
      textAlign: "center",
      marginBottom: 16,
    },
    divider: {
      height: 1,
      backgroundColor: colors.border,
      marginBottom: 18,
    },
    pledgeBox: {
      borderWidth: 1,
      borderColor: colors.border,
      borderRadius: colors.radius,
      backgroundColor: colors.background,
      padding: 16,
      marginBottom: 18,
    },
    modalText: {
      fontSize: 15,
      lineHeight: 28,
      fontFamily: "Cairo_500Medium",
      color: colors.foreground,
      textAlign: "right",
    },
    modalNote: {
      marginTop: 8,
      fontSize: 14,
      lineHeight: 24,
      fontFamily: "Cairo_500Medium",
      color: colors.primary,
      textAlign: "right",
    },
    agreementRow: {
      flexDirection: "row-reverse",
      alignItems: "center",
      justifyContent: "space-between",
      gap: 12,
      marginTop: 18,
      marginBottom: 10,
    },
    agreementText: {
      flex: 1,
      fontSize: 15,
      lineHeight: 32,
      fontFamily: "Cairo_600SemiBold",
      color: colors.foreground,
      textAlign: "right",
    },
    agreementWarning: {
      fontSize: 14,
      lineHeight: 26,
      fontFamily: "Cairo_700Bold",
      color: "#c65b22",
      textAlign: "right",
      marginTop: 10,
    },
    modalActions: {
      flexDirection: "row-reverse",
      gap: 10,
      marginTop: 16,
    },
    modalBtn: {
      flex: 1,
      borderRadius: colors.radius,
      paddingVertical: 14,
      alignItems: "center",
      justifyContent: "center",
      borderWidth: 1,
      borderColor: colors.border,
      backgroundColor: colors.background,
    },
    modalBtnPrimary: {
      backgroundColor: colors.primary,
      borderColor: colors.primary,
    },
    modalBtnText: {
      fontSize: 15,
      fontFamily: "Cairo_700Bold",
      color: colors.foreground,
    },
    modalBtnTextPrimary: {
      color: "#fff",
    },
  });

  return (
    <View style={styles.container}>
      <YemenHeader title="نشر إعلان" />
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        style={{ flex: 1 }}
      >
        <ScrollView
          contentContainerStyle={styles.scroll}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {!!submitError && (
            <Text style={[styles.feedbackText, styles.errorText]}>{submitError}</Text>
          )}
          {!!submitSuccess && (
            <Text style={[styles.feedbackText, styles.successText]}>{submitSuccess}</Text>
          )}
          <View style={styles.section}>
            <Text style={styles.label}>
              صور الإعلان <Text style={styles.required}>(اختياري)</Text>
            </Text>
            <View style={styles.imagesGrid}>
              {images.map((img, i) => (
                <View key={i} style={styles.imageThumb}>
                  <Image source={{ uri: img.uri }} style={styles.imageThumbImg} resizeMode="cover" />
                  <TouchableOpacity
                    style={styles.removeImg}
                    onPress={() => setImages((p) => p.filter((_, idx) => idx !== i))}
                  >
                    <Feather name="x" size={12} color="#fff" />
                  </TouchableOpacity>
                </View>
              ))}
              {images.length < 10 && (
                <TouchableOpacity style={styles.addImageBtn} onPress={pickImage}>
                  <Feather name="camera" size={24} color={colors.mutedForeground} />
                  <Text style={styles.addImageText}>أضف صورة</Text>
                </TouchableOpacity>
              )}
            </View>
          </View>

          <View style={styles.section}>
            <Text style={styles.label}>
              عنوان الإعلان <Text style={styles.required}>*</Text>
            </Text>
            <TextInput
              style={styles.input}
              value={title}
              onChangeText={setTitle}
              placeholder="مثال: تويوتا كامري 2022 للبيع"
              placeholderTextColor={colors.mutedForeground}
              textAlign="right"
            />
          </View>

          <View style={styles.section}>
            <Text style={styles.label}>
              القسم <Text style={styles.required}>*</Text>
            </Text>
            <View style={styles.chipsRow}>
              {CATEGORIES.map((cat) => (
                <TouchableOpacity
                  key={cat.id}
                  style={[styles.chip, category === cat.id && styles.chipActive]}
                  onPress={() => { setCategory(cat.id); setSubcategory(""); }}
                >
                  <Text style={[styles.chipText, category === cat.id && styles.chipTextActive]}>
                    {cat.name}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          {currentCat && currentCat.subcategories.length > 0 && (
            <View style={styles.section}>
              <Text style={styles.label}>القسم الفرعي</Text>
              <View style={styles.chipsRow}>
                {currentCat.subcategories.map((sub) => (
                  <TouchableOpacity
                    key={sub}
                    style={[styles.chip, subcategory === sub && styles.chipActive]}
                    onPress={() => setSubcategory(sub)}
                  >
                    <Text style={[styles.chipText, subcategory === sub && styles.chipTextActive]}>
                      {sub}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          )}

          <View style={styles.section}>
            <Text style={styles.label}>
              وصف الإعلان <Text style={styles.required}>*</Text>
            </Text>
            <TextInput
              style={[styles.input, styles.textarea]}
              value={description}
              onChangeText={setDescription}
              placeholder="اكتب تفاصيل الإعلان هنا..."
              placeholderTextColor={colors.mutedForeground}
              multiline
              textAlign="right"
            />
          </View>

          <View style={styles.section}>
            <Text style={styles.label}>نوع السعر</Text>
            <View style={styles.chipsRow}>
              {PRICE_TYPES.map((pt) => (
                <TouchableOpacity
                  key={pt.id}
                  style={[styles.chip, priceType === pt.id && styles.chipActive]}
                  onPress={() => setPriceType(pt.id as any)}
                >
                  <Text style={[styles.chipText, priceType === pt.id && styles.chipTextActive]}>
                    {pt.name}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          {(priceType === "fixed" || priceType === "negotiable") && (
            <View style={styles.section}>
              <Text style={styles.label}>العملة</Text>
              <View style={styles.chipsRow}>
                {CURRENCY_TYPES.map((entry) => (
                  <TouchableOpacity
                    key={entry.id}
                    style={[styles.chip, currency === entry.id && styles.chipActive]}
                    onPress={() => setCurrency(entry.id as any)}
                  >
                    <Text style={[styles.chipText, currency === entry.id && styles.chipTextActive]}>
                      {entry.name}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          )}

          {priceType === "fixed" || priceType === "negotiable" ? (
            <View style={styles.section}>
              <Text style={styles.label}>السعر</Text>
              <View style={styles.priceRow}>
                <Text style={styles.currency}>
                  {CURRENCY_TYPES.find((entry) => entry.id === currency)?.symbol || "ر.ي"}
                </Text>
                <TextInput
                  style={[styles.input, styles.priceInput]}
                  value={price}
                  onChangeText={setPrice}
                  placeholder="أدخل السعر"
                  placeholderTextColor={colors.mutedForeground}
                  keyboardType="numeric"
                  textAlign="right"
                />
              </View>
            </View>
          ) : null}

          <View style={styles.section}>
            <Text style={styles.label}>حالة السلعة</Text>
            <View style={styles.chipsRow}>
              {CONDITION_TYPES.map((ct) => (
                <TouchableOpacity
                  key={ct.id}
                  style={[styles.chip, condition === ct.id && styles.chipActive]}
                  onPress={() => setCondition(ct.id)}
                >
                  <Text style={[styles.chipText, condition === ct.id && styles.chipTextActive]}>
                    {ct.name}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          <View style={styles.section}>
            <Text style={styles.label}>المحافظة</Text>
            <TouchableOpacity style={styles.govBtn} onPress={() => setShowGovSheet(true)}>
              <Feather name="chevron-left" size={18} color={colors.mutedForeground} />
              <Text style={styles.govBtnText}>{getGovernorateLabel(governorate)}</Text>
              <Feather name="map-pin" size={16} color={colors.mutedForeground} />
            </TouchableOpacity>
          </View>

          <TouchableOpacity
            style={[styles.submitBtn, loading && { opacity: 0.7 }]}
            onPress={handleSubmit}
            disabled={loading}
          >
            <Text style={styles.submitBtnText}>
              {loading ? "جاري النشر..." : "نشر الإعلان"}
            </Text>
          </TouchableOpacity>
        </ScrollView>
      </KeyboardAvoidingView>

      <GovernorateSheet
        visible={showGovSheet}
        selected={governorate}
        onSelect={setGovernorate}
        onClose={() => setShowGovSheet(false)}
      />

      {showCommitmentModal && (
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>بسم الله الرحمن الرحيم</Text>
            <Text style={styles.verseText}>
              قال الله تعالى: "وأوفوا بعهد الله إذا عاهدتم ولا تنقضوا الأيمان بعد توكيدها وقد جعلتم الله عليكم كفيلاً"
            </Text>
            <Text style={styles.verseConfirm}>صدق الله العظيم</Text>
            <View style={styles.divider} />

            <View style={styles.pledgeBox}>
              <View style={styles.agreementRow}>
                <Switch
                  value={commitmentAccepted}
                  onValueChange={setCommitmentAccepted}
                  trackColor={{ false: colors.muted, true: colors.primary + "88" }}
                  thumbColor={commitmentAccepted ? colors.primary : "#f4f3f4"}
                />
                <Text style={styles.agreementText}>
                  أتعهد وأقسم بالله أن أدفع رسوم الموقع وهي 1% من قيمة البيع سواء تم البيع عن طريق الموقع أو بسببه.
                </Text>
              </View>

              <Text style={styles.modalText}>
                كما أتعهد بدفع الرسوم خلال 10 أيام من استلام كامل مبلغ المبايعة.
              </Text>
              <Text style={styles.agreementWarning}>تجب الموافقة على المعاهدة</Text>
            </View>

            <Text style={styles.modalTitle}>ملاحظة بشأن الرسوم</Text>
            <Text style={styles.modalNote}>
              رسوم الموقع هي على المعلن ولا تبرأ ذمة المعلن من الرسوم إلا في حال دفعها.
            </Text>

            {!!submitError && (
              <Text style={[styles.feedbackText, styles.errorText]}>{submitError}</Text>
            )}

            <View style={styles.modalActions}>
              <TouchableOpacity
                style={[styles.modalBtn, styles.modalBtnPrimary, loading && { opacity: 0.7 }]}
                onPress={confirmSubmit}
                disabled={loading}
              >
                <Text style={[styles.modalBtnText, styles.modalBtnTextPrimary]}>
                  {loading ? "جاري النشر..." : "موافقة ونشر الإعلان"}
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.modalBtn}
                onPress={() => {
                  setShowCommitmentModal(false);
                  setCommitmentAccepted(false);
                }}
                disabled={loading}
              >
                <Text style={styles.modalBtnText}>إلغاء</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )}
    </View>
  );
}
