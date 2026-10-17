import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'store_provider.dart';

// Apna store banao: logo + naam + category + description.
// Store banne ke baad buyer apne store ka admin ban jata hai.
class CreateStoreScreen extends StatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  State<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _category = 'Fashion';
  String _logoUrl = '';
  bool _uploadingLogo = false;
  bool _loading = false;

  static const _categories = [
    'Fashion',
    'Electronics',
    'Beauty',
    'Home',
    'Sports',
    'Food',
    'General',
    'Other',
  ];

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  // Gallery se logo chuno aur Cloudinary par upload karo
  Future<void> _pickLogo() async {
    if (_uploadingLogo) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return; // user ne cancel kar diya
    setState(() => _uploadingLogo = true);
    final url = await context.read<StoreProvider>().uploadStoreLogo(picked);
    if (!mounted) return;
    setState(() => _uploadingLogo = false);
    if (url != null && url.isNotEmpty) {
      setState(() => _logoUrl = url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload logo. Try again.')),
      );
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final ok = await context.read<StoreProvider>().createStore(
          name: _name.text,
          category: _category,
          description: _desc.text,
          logoUrl: _logoUrl,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your store is ready!')),
      );
      Navigator.pop(context, true);
    } else {
      final msg = context.read<StoreProvider>().error ??
          'Could not create store. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Your Store', style: AppTextStyles.subHeading),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo picker — tap karo, gallery se logo chuno
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryViolet
                                  .withValues(alpha: 0.45),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _uploadingLogo
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : _logoUrl.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      _logoUrl,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _initialLetter(),
                                    ),
                                  )
                                : _initialLetter(),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: AppColors.primaryViolet,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 17,
                            color: AppColors.primaryViolet,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tap the circle to upload your store logo.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _label('Store Name'),
              const SizedBox(height: 8),
              _field(
                controller: _name,
                hint: 'e.g. Urban Outfitters',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your store name.';
                  }
                  if (v.trim().length < 3) {
                    return 'Store name must be at least 3 characters.';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              _label('Category'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.surface.withValues(alpha: 0.7),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white54,
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _label('About your store (optional)'),
              const SizedBox(height: 8),
              _field(
                controller: _desc,
                hint: 'What does your store sell?',
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _loading ? null : _create,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryViolet.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Create Store',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logo na ho to naam ka pehla letter
  Widget _initialLetter() {
    return Text(
      _name.text.isNotEmpty ? _name.text[0].toUpperCase() : 'S',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 44,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: AppColors.primaryViolet,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primaryViolet,
            width: 1.6,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }
}
