import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/entities.dart';
import '../../../app/app_providers.dart';

/// Screen to Add a New Person / Relative (Fully Localized, Zero Hardcoding)
class AddPersonScreen extends ConsumerStatefulWidget {
  const AddPersonScreen({super.key});

  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: Text(l10n.addNewPerson, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Card(
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.personName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: l10n.personNameHint,
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? l10n.validationRequired : null,
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.relationCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _relationController,
                            decoration: InputDecoration(
                              hintText: l10n.relationCategoryHint,
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.villageCity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              hintText: l10n.villageCityHint,
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.phoneNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: l10n.phoneNumberHint,
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.notes, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: l10n.notesPlaceholder,
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _savePerson,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(l10n.savePerson, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _savePerson() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(peopleRepositoryProvider);
      final now = DateTime.now();
      final person = Person(
        id: const Uuid().v4(),
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        relationshipLabel: _relationController.text.trim().isNotEmpty ? _relationController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: now,
        updatedAt: now,
      );

      await repo.savePerson(person);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personSavedSuccess), backgroundColor: AppColors.milaGreen),
        );
        Navigator.pop(context);
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $err')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
