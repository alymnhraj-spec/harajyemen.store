import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/post_model.dart';
import '../../models/governorate_model.dart';
import '../../services/post_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _phoneController;
  final _postService = PostService();
  final _locationService = LocationService();

  List<String> _existingImageUrls = [];
  List<XFile> _newImages = [];
  List<GovernorateModel> _governorates = [];
  GovernorateModel? _selectedGov;
  String? _selectedCategory;
  late PriceType _priceType;
  bool _isLoading = false;
  String _loadingStatus = '';

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _titleController = TextEditingController(text: p.title);
    _descController = TextEditingController(text: p.description);
    _priceController = TextEditingController(text: p.price?.toStringAsFixed(0) ?? '');
    _phoneController = TextEditingController(text: p.userPhone);
    _existingImageUrls = List.from(p.images);
    _priceType = p.priceType;
    _selectedCategory = p.category;

    _locationService.loadGovernorates().then((govs) {
      if (!mounted) return;
      setState(() {
        _governorates = govs;
        _selectedGov = govs.cast<GovernorateModel?>().firstWhere(
          (g) => g?.id == p.governorateId,
          orElse: () => null,
        );
      });
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

  int get _totalImages => _existingImageUrls.length + _newImages.length;

  Future<void> _pickImages() async {
    if (_totalImages >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الحد الأقصى 6 صور')));
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() => _newImages.addAll(picked.take(6 - _totalImages)));
  }

  Future<void> _takePhoto() async {
    if (_totalImages >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الحد الأقصى 6 صور')));
      return;
    }
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo == null) return;
    setState(() => _newImages.add(photo));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_totalImages == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة صورة واحدة على الأقل'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedGov == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار المحافظة')));
      return;
    }

    setState(() { _isLoading = true; _loadingStatus = 'جاري حفظ التعديلات...'; });
    try {
      await _postService.updatePost(
        postId: widget.post.id!,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        governorateId: _selectedGov!.id,
        governorateName: _selectedGov!.name,
        priceType: _priceType,
        contactPhone: _phoneController.text.trim(),
        price: _priceType != PriceType.free && _priceType != PriceType.negotiable
            ? double.tryParse(_priceController.text)
            : null,
        category: _selectedCategory,
        newImages: _newImages,
        existingImageUrls: _existingImageUrls,
        onProgress: (s) { if (mounted) setState(() => _loadingStatus = s); },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعديل الإعلان بنجاح ✓'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الإعلان')),
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
              items: _governorates.map((g) => DropdownMenuItem(value: g, child: Text(g.name))).toList(),
              onChanged: (g) => setState(() => _selectedGov = g),
              decoration: const InputDecoration(labelText: 'المحافظة'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('اختر الفئة (اختياري)'),
              items: PostCategories.categories
                  .map((c) => DropdownMenuItem(value: c['id'], child: Text('${c['icon']} ${c['name']}')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              decoration: const InputDecoration(labelText: 'الفئة'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PriceType>(
              value: _priceType,
              items: PriceType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (t) => setState(() => _priceType = t!),
              decoration: const InputDecoration(labelText: 'نوع السعر'),
            ),
            if (_priceType != PriceType.free && _priceType != PriceType.negotiable) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'السعر', suffixText: _priceType.symbol),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                        const SizedBox(width: 10),
                        Text(_loadingStatus, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    )
                  : const Text('حفظ التعديلات'),
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
        Text('الصور ($_totalImages/6)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._existingImageUrls.asMap().entries.map((e) => _existingImageThumb(e.value, e.key)),
              ..._newImages.asMap().entries.map((e) => _newImageThumb(e.value, e.key)),
              if (_totalImages < 6) ...[
                _addImageBtn(),
                if (!kIsWeb) _cameraBtn(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _existingImageThumb(String url, int index) {
    return Stack(
      children: [
        Container(
          width: 90, height: 90,
          margin: const EdgeInsets.only(left: 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, width: 90, height: 90),
        ),
        Positioned(
          top: 2, right: 2,
          child: GestureDetector(
            onTap: () => setState(() => _existingImageUrls.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _newImageThumb(XFile xfile, int index) {
    return Stack(
      children: [
        Container(
          width: 90, height: 90,
          margin: const EdgeInsets.only(left: 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.divider),
          child: FutureBuilder<dynamic>(
            future: xfile.readAsBytes(),
            builder: (_, snap) {
              if (snap.hasData) return Image.memory(snap.data!, fit: BoxFit.cover, width: 90, height: 90);
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            },
          ),
        ),
        Positioned(
          top: 2, right: 2,
          child: GestureDetector(
            onTap: () => setState(() => _newImages.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
        width: 90, height: 90,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(10)),
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
        width: 90, height: 90,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 28, color: AppColors.primary),
            SizedBox(height: 4),
            Text('كاميرا', style: TextStyle(fontSize: 11, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
