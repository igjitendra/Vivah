import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../domain/entities/family_profile.dart';
import '../../../../app/app_providers.dart';

/// Screen to create or edit the user's primary family profile
class EditFamilyProfileScreen extends ConsumerStatefulWidget {
  const EditFamilyProfileScreen({super.key});

  @override
  ConsumerState<EditFamilyProfileScreen> createState() =>
      _EditFamilyProfileScreenState();
}

class _EditFamilyProfileScreenState
    extends ConsumerState<EditFamilyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _familyNameController;
  late TextEditingController _headOfFamilyController;
  late TextEditingController _nativePlaceController;
  late TextEditingController _currentCityController;
  late TextEditingController _addressController;
  late TextEditingController _gotraController;
  late TextEditingController _kuldeviController;
  late TextEditingController _primaryPhoneController;
  late TextEditingController _alternatePhoneController;
  late TextEditingController _emailController;
  late TextEditingController _aboutController;

  String? _photoPath;
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _familyNameController = TextEditingController();
    _headOfFamilyController = TextEditingController();
    _nativePlaceController = TextEditingController();
    _currentCityController = TextEditingController();
    _addressController = TextEditingController();
    _gotraController = TextEditingController();
    _kuldeviController = TextEditingController();
    _primaryPhoneController = TextEditingController();
    _alternatePhoneController = TextEditingController();
    _emailController = TextEditingController();
    _aboutController = TextEditingController();
  }

  void _populateForm(FamilyProfile profile) {
    if (_isInitialized) return;
    _isInitialized = true;
    _familyNameController.text = profile.familyName;
    _headOfFamilyController.text = profile.headOfFamily;
    _nativePlaceController.text = profile.nativePlace;
    _currentCityController.text = profile.currentCity;
    _addressController.text = profile.address;
    _gotraController.text = profile.gotra;
    _kuldeviController.text = profile.kuldevi;
    _primaryPhoneController.text = profile.primaryPhone;
    _alternatePhoneController.text = profile.alternatePhone;
    _emailController.text = profile.email;
    _aboutController.text = profile.about;
    _photoPath = profile.photoPath.isNotEmpty ? profile.photoPath : null;
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _headOfFamilyController.dispose();
    _nativePlaceController.dispose();
    _currentCityController.dispose();
    _addressController.dispose();
    _gotraController.dispose();
    _kuldeviController.dispose();
    _primaryPhoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickFamilyPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final pickedPath = result.files.first.path;
        if (pickedPath != null) {
          final appDir = await getApplicationDocumentsDirectory();
          final familyDir = Directory(p.join(appDir.path, 'family_profile'));
          if (!familyDir.existsSync()) {
            familyDir.createSync(recursive: true);
          }
          final ext = p.extension(pickedPath);
          final dest = p.join(
            familyDir.path,
            'family_avatar_${DateTime.now().millisecondsSinceEpoch}$ext',
          );
          await File(pickedPath).copy(dest);
          setState(() {
            _photoPath = dest;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _save(FamilyProfile existing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final l10n = context.l10n;

    final updated = existing.copyWith(
      familyName: _familyNameController.text.trim(),
      headOfFamily: _headOfFamilyController.text.trim(),
      nativePlace: _nativePlaceController.text.trim(),
      currentCity: _currentCityController.text.trim(),
      address: _addressController.text.trim(),
      gotra: _gotraController.text.trim(),
      kuldevi: _kuldeviController.text.trim(),
      primaryPhone: _primaryPhoneController.text.trim(),
      alternatePhone: _alternatePhoneController.text.trim(),
      email: _emailController.text.trim(),
      photoPath: _photoPath ?? '',
      about: _aboutController.text.trim(),
    );

    try {
      final repo = ref.read(familyProfileRepositoryProvider);
      await repo.saveFamilyProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.familyProfileSaved),
            backgroundColor: AppColors.milaGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final profileAsync = ref.watch(familyProfileProvider);
    final profile = profileAsync.value ?? const FamilyProfile();
    _populateForm(profile);

    final bg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF131720) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          profile.isEmpty ? l10n.setupFamilyProfile : l10n.editFamilyProfile,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(profile),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracotta),
                  )
                : Text(
                    l10n.save,
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Avatar Card
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _pickFamilyPhoto,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.terracotta.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          image: _photoPath != null && File(_photoPath!).existsSync()
                              ? DecorationImage(
                                  image: FileImage(File(_photoPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _photoPath == null || !File(_photoPath!).existsSync()
                            ? const Icon(
                                Icons.family_restroom,
                                size: 48,
                                color: AppColors.terracotta,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickFamilyPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.terracotta,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickFamilyPhoto,
                  child: Text(
                    _photoPath == null ? l10n.familyPhoto : l10n.changePhoto,
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section: Core Identity
              _FormSectionHeader(title: l10n.familyName, textSecondary: textSecondary),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Family Name
                    _CustomField(
                      label: '${l10n.familyName} *',
                      controller: _familyNameController,
                      hint: l10n.familyNameHint,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.enterValidFamilyName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Head of Family (Mukhiya)
                    _CustomField(
                      label: l10n.headOfFamily,
                      controller: _headOfFamilyController,
                      hint: l10n.headOfFamilyHint,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section: Heritage & Roots
              _FormSectionHeader(title: l10n.gotra, textSecondary: textSecondary),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Gotra
                    _CustomField(
                      label: l10n.gotra,
                      controller: _gotraController,
                      hint: l10n.gotraHint,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 14),

                    // Kuldevi / Deity
                    _CustomField(
                      label: l10n.kuldevi,
                      controller: _kuldeviController,
                      hint: l10n.kuldeviHint,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section: Location & Residence
              _FormSectionHeader(title: l10n.nativePlace, textSecondary: textSecondary),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Native Village / Place
                    _CustomField(
                      label: l10n.nativePlace,
                      controller: _nativePlaceController,
                      hint: l10n.nativePlaceHint,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 14),

                    // Current City
                    _CustomField(
                      label: l10n.currentCity,
                      controller: _currentCityController,
                      hint: l10n.currentCityHint,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 14),

                    // Full Address
                    _CustomField(
                      label: l10n.fullAddress,
                      controller: _addressController,
                      hint: 'Ward No., House/Street, Area...',
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section: Contact & Bio
              _FormSectionHeader(title: l10n.primaryPhone, textSecondary: textSecondary),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Primary Contact Phone
                    _CustomField(
                      label: l10n.primaryPhone,
                      controller: _primaryPhoneController,
                      hint: '9876543210',
                      keyboardType: TextInputType.phone,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 14),

                    // Alternate Phone
                    _CustomField(
                      label: l10n.alternatePhone,
                      controller: _alternatePhoneController,
                      hint: '9876543211',
                      keyboardType: TextInputType.phone,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 14),

                    // Family Email
                    _CustomField(
                      label: l10n.familyEmail,
                      controller: _emailController,
                      hint: 'sharmafamily@email.com',
                      keyboardType: TextInputType.emailAddress,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 14),

                    // Family Bio
                    _CustomField(
                      label: l10n.familyBio,
                      controller: _aboutController,
                      hint: l10n.familyBioHint,
                      maxLines: 3,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Save button
              ElevatedButton(
                onPressed: _isSaving ? null : () => _save(profile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        l10n.save,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSectionHeader extends StatelessWidget {
  final String title;
  final Color textSecondary;

  const _FormSectionHeader({required this.title, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: textSecondary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _CustomField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final Color inputBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _CustomField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.inputBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
