import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/entities.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';

/// Modern Screen for adding a new relative or acquaintance
/// Fully theme-adaptive with suggested relationship chips and tactile spring squish.
class AddPersonScreen extends ConsumerStatefulWidget {
  const AddPersonScreen({super.key});

  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(l10n.addNewPerson, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator(color: primaryAccent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  ExpressCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    radius: 16,
                    color: cardBg,
                    borderColor: cardBorder,
                    elevation: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.personName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.personNameHint,
                            hintStyle: TextStyle(color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? l10n.validationRequired : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.relationCategory, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                            Text(l10n.suggestedRelationshipsTitle, style: TextStyle(fontSize: 12, color: textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _relationController,
                          style: TextStyle(color: textPrimary),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: l10n.relationCategoryHint,
                            hintStyle: TextStyle(color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _suggestedRelationships(l10n).map((rel) {
                            final isSelected = _relationController.text.trim() == rel;
                            return FilterChip(
                              label: Text(
                                rel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: primaryAccent,
                              backgroundColor: inputBg,
                              side: BorderSide(
                                color: isSelected ? primaryAccent : cardBorder,
                              ),
                              showCheckmark: false,
                              onSelected: (val) {
                                setState(() {
                                  _relationController.text = val ? rel : '';
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.villageCity, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressController,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.villageCityHint,
                            hintStyle: TextStyle(color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.phoneNumber, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.phoneNumberHint,
                            hintStyle: TextStyle(color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.notes, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.notesPlaceholder,
                            hintStyle: TextStyle(color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ExpressSquish(
                    scale: 0.96,
                    onTap: _savePerson,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: primaryAccent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryAccent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.savePerson,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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

      await repo.createPerson(person);

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

  List<String> _suggestedRelationships(AppLocalizations l10n) {
    if (l10n.isEnglish) {
      return const [
        'Uncle (Mama)',
        'Uncle (Chacha)',
        'Aunt (Bua)',
        'Aunt (Mausi)',
        'Brother-in-law (Jija)',
        'Brother-in-law (Sala)',
        'Samdhi',
        'Friend',
        'Neighbor',
        'Relative',
      ];
    } else if (l10n.isUrdu) {
      return const [
        'ماموں',
        'چچا',
        'پھوپھی',
        'خالہ',
        'بہنوئی',
        'سالا',
        'سمدھی',
        'دوست',
        'ہمسایہ',
        'رشتہ دار',
      ];
    }
    return const [
      'मामा',
      'चाचा',
      'ताऊ',
      'बुआ',
      'मौसी',
      'फूफा',
      'जीजा',
      'साला',
      'समधी',
      'मित्र',
      'पड़ोसी',
      'रिश्तेदार',
    ];
  }
}
