import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/post_model.dart';
import '../../models/governorate_model.dart';
import '../../services/post_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _postService = PostService();
  final _locationService = LocationService();

  List<XFile> _images = [];
  List<GovernorateModel> _governorates = [];
  GovernorateModel? _selectedGov;
  String? _selectedCategory;
  PriceType _priceType = PriceType.yemeni;
  bool _isLoading = false;
  String _loadingStatus = '';

  @override
  void initState() {
    super.initState();
    _locationService.loadGovernorates().then((govs) {
      if (mounted) setState(() => _governorates = govs);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى 6 صور')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    final remaining = 6 - _images.length;
    setState(() => _images.addAll(picked.take(remaining)));
  }

  Future<void> _takePhoto() async {
    if (_images.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى 6 صور')),
      );
      return;
    }
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo == null) return;
    setState(() => _images.add(photo));
  }

  Future<void> _validateThenShowCovenant() async {
    // 1. تحقق من النموذج
    if (!_formKey.currentState!.validate()) return;
    // 2. تحقق من الصورة
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة صورة واحدة على الأقل'), backgroundColor: Colors.red),
      );
      return;
    }
    // 3. تحقق من المحافظة
    if (_selectedGov == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المحافظة')),
      );
      return;
    }
    // 4. تحقق من السعر
    final needsPrice = _priceType != PriceType.free && _priceType != PriceType.negotiable;
    if (needsPrice && _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إدخال السعر أو اختيار "مجاناً" / "قابل للتفاوض"'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // كل التحقق اكتمل — أظهر المعاهدة
    await _showCovenantDialog();
  }

  Future<void> _showCovenantDialog() async {
    bool agreed = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // رأس النافذة
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Text(
                        'بسم الله الرحمن الرحيم',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // المحتوى
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        children: [
                          // الآية
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  '"وَأَوْفُوا بِعَهْدِ اللَّهِ إِذَا عَاهَدتُّمْ وَلَا تَنقُضُوا الْأَيْمَانَ بَعْدَ تَوْكِيدِهَا وَقَدْ جَعَلْتُمُ اللَّهَ عَلَيْكُمْ كَفِيلًا"',
                                  style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'صدق الله العظيم',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // بطاقة التعهد
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'أتعهد وأقسم بالله أن أدفع رسوم الموقع وهي 1% من قيمة البيع سواء تم البيع عن طريق الموقع أو بسببه، وبدفعها خلال 10 أيام من استلام كامل المبلغ.',
                                  style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => setStateDialog(() => agreed = !agreed),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: agreed ? const Color(0xFF388E3C) : Colors.white,
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(
                                            color: agreed ? const Color(0xFF388E3C) : Colors.grey.shade400,
                                            width: 2,
                                          ),
                                        ),
                                        child: agreed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('أوافق على المعاهدة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                if (!agreed) ...[
                                  const SizedBox(height: 4),
                                  const Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 12, color: Colors.red),
                                      SizedBox(width: 4),
                                      Text('يجب الموافقة على المعاهدة للمتابعة', style: TextStyle(color: Colors.red, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ملاحظة الرسوم
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFCC02)),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'رسوم الموقع هي على المعلن ولا تبرأ ذمته منها إلا في حال دفعها.',
                                    style: TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF795548)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // الأزرار
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    minimumSize: const Size(0, 44),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('إلغاء'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: agreed ? () => Navigator.of(ctx).pop(true) : null,
                                  icon: const Icon(Icons.send_rounded, size: 16),
                                  label: const Text('نشر الإعلان'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF388E3C),
                                    disabledBackgroundColor: Colors.grey.shade200,
                                    minimumSize: const Size(0, 44),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() { _isLoading = true; _loadingStatus = 'جاري رفع الصور...'; });
    try {
      await _postService.addPost(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        images: _images,
        governorateId: _selectedGov!.id,
        governorateName: _selectedGov!.name,
        priceType: _priceType,
        contactPhone: _phoneController.text.trim(),
        price: _priceType != PriceType.free && _priceType != PriceType.negotiable
            ? double.tryParse(_priceController.text)
            : null,
        category: _selectedCategory,
        onProgress: (status) { if (mounted) setState(() => _loadingStatus = status); },
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF388E3C), size: 44),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تم نشر الإعلان!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'إعلانك الآن مرئي للجميع',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E3C),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('حسناً'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة إعلان')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'عنوان الإعلان'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل العنوان' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'الوصف'),
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الوصف' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'رقم الجوال للتواصل *',
                hintText: '9671XXXXXXXX+',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'رقم الجوال مطلوب';
                if (v.trim().length < 9) return 'رقم الجوال غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GovernorateModel>(
              value: _selectedGov,
              hint: const Text('اختر المحافظة'),
              items: _governorates.map((g) => DropdownMenuItem(
                value: g,
                child: Text(g.name),
              )).toList(),
              onChanged: (g) => setState(() => _selectedGov = g),
              decoration: const InputDecoration(labelText: 'المحافظة'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('اختر الفئة (اختياري)'),
              items: PostCategories.categories.map((c) => DropdownMenuItem(
                value: c['id'],
                child: Text('${c['icon']} ${c['name']}'),
              )).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              decoration: const InputDecoration(labelText: 'الفئة'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PriceType>(
              value: _priceType,
              items: PriceType.values.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.label),
              )).toList(),
              onChanged: (t) => setState(() => _priceType = t!),
              decoration: const InputDecoration(labelText: 'نوع السعر'),
            ),
            if (_priceType != PriceType.free && _priceType != PriceType.negotiable) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'السعر',
                  suffixText: _priceType.symbol,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _validateThenShowCovenant,
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        ),
                        const SizedBox(width: 10),
                        Text(_loadingStatus, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    )
                  : const Text('نشر الإعلان'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الصور (${_images.length}/6)',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._images.asMap().entries.map((e) => _imageThumb(e.value, e.key)),
              if (_images.length < 6) ...[
                _addImageBtn(),
                if (!kIsWeb) _cameraBtn(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageThumb(XFile xfile, int index) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(left: 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.divider,
          ),
          child: FutureBuilder<dynamic>(
            future: xfile.readAsBytes(),
            builder: (_, snap) {
              if (snap.hasData) {
                return Image.memory(snap.data!, fit: BoxFit.cover, width: 90, height: 90);
              }
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            },
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => setState(() => _images.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addImageBtn() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 90,
        height: 90,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 28, color: AppColors.textSecondary),
            SizedBox(height: 4),
            Text('معرض', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _cameraBtn() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        width: 90,
        height: 90,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 28, color: AppColors.primary),
            const SizedBox(height: 4),
            Text('كاميرا', style: TextStyle(fontSize: 11, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
