import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/entities.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../shared/widgets/express_button.dart';
import '../../../app/app_providers.dart';
import 'widgets/contact_import_sheet.dart';
import '../services/contacts_service.dart';

/// Clean and focused screen for adding a new person or relative
class AddPersonScreen extends ConsumerStatefulWidget {
  final ContactDraft? initialDraft;

  const AddPersonScreen({super.key, this.initialDraft});

  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();

  // Essential Controllers
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _villageController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedFamilyId;
  String _contactSource = 'manual';
  String? _externalContactId;
  DateTime? _importedAt;
  ContactDraft? _importedDraft;
  bool _isSaving = false;

  final List<String> _quickRelations = [
    'रिश्तेदार',
    'मित्र',
    'परिवार',
    'पड़ोसी',
    'अन्य',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft != null) {
      _applyDraft(widget.initialDraft!);
    }
  }

  void _applyDraft(ContactDraft d) {
    _importedDraft = d;
    _contactSource = 'phone_import';
    _externalContactId = d.externalId;
    _importedAt = DateTime.now();

    _nameController.text = d.name;
    if (d.primaryPhone != null) _phoneController.text = d.primaryPhone!;
    if (d.village != null && d.village!.isNotEmpty) {
      _villageController.text = d.village!;
    } else if (d.city != null && d.city!.isNotEmpty) {
      _villageController.text = d.city!;
    } else if (d.address != null && d.address!.isNotEmpty) {
      _villageController.text = d.address!;
    }
    if (d.notes != null) _notesController.text = d.notes!;
  }

  void _populateFromDraft(ContactDraft d) {
    setState(() => _applyDraft(d));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _villageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _openContactImportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ContactImportSheet(
          onSingleContactPicked: (draft) {
            _populateFromDraft(draft);
          },
        ),
      ),
    );
  }

  void _showAddFamilyDialog(AppLocalizations l10n) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addNewFamily, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: l10n.familyNameHint,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                final repo = ref.read(familiesRepositoryProvider);
                final newId = const Uuid().v4();
                final now = DateTime.now();
                await repo.createFamily(Family(id: newId, name: name, createdAt: now, updatedAt: now));
                if (mounted) {
                  setState(() => _selectedFamilyId = newId);
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.errorGeneric}: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).whenComplete(nameController.dispose);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(peopleRepositoryProvider);
      final now = DateTime.now();
      final draft = _importedDraft;

      final person = Person(
        id: const Uuid().v4(),
        familyId: _selectedFamilyId,
        fullName: name,
        firstName: draft?.firstName,
        middleName: draft?.middleName,
        lastName: draft?.lastName,
        nickname: draft?.nickname,
        dateOfBirth: draft?.birthday,
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        secondaryPhones: draft?.secondaryPhones ?? const [],
        whatsappNumber: _whatsappController.text.trim().isNotEmpty ? _whatsappController.text.trim() : null,
        emails: draft?.emails ?? const [],
        village: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : draft?.village,
        city: draft?.city,
        district: draft?.district,
        state: draft?.state,
        pinCode: draft?.pinCode,
        address: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : draft?.address,
        relationshipLabel: _relationController.text.trim().isNotEmpty ? _relationController.text.trim() : null,
        occupation: draft?.jobTitle,
        company: draft?.company,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        tags: const [],
        contactSource: _contactSource,
        externalContactId: _externalContactId,
        importedAt: _importedAt,
        isAppEditedAfterImport: _contactSource == 'phone_import',
        createdAt: now,
        updatedAt: now,
      );

      await repo.createPerson(person);

      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.pop(context, person);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.personSavedSuccess), backgroundColor: AppColors.milaGreen),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.errorGeneric}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final familiesAsync = ref.watch(activeFamiliesListProvider);

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          _contactSource == 'phone_import' ? 'संपर्क से जोड़ें' : l10n.addNewPerson,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator(color: primaryAccent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                children: [
                  // Top Switcher: Add Manually vs Import from Phone Contacts
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_contactSource != 'manual') {
                                setState(() => _contactSource = 'manual');
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _contactSource == 'manual' ? primaryAccent.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _contactSource == 'manual' ? primaryAccent : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_note, size: 17, color: _contactSource == 'manual' ? primaryAccent : textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.addManually,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: _contactSource == 'manual' ? primaryAccent : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: InkWell(
                            onTap: _openContactImportSheet,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _contactSource == 'phone_import' ? primaryAccent.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _contactSource == 'phone_import' ? primaryAccent : cardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.contacts, size: 16, color: primaryAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.importFromContacts,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: primaryAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_contactSource == 'phone_import') ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'फ़ोन संपर्क से विवरण प्राप्त किया गया।',
                              style: TextStyle(fontSize: 12, color: textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 1. Personal & Relation Details Card
                  _buildSectionCard(
                    title: 'व्यक्तिगत जानकारी',
                    icon: Icons.person_outline,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      Text(l10n.personName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration(l10n.personNameHint, inputBg, textSecondary),
                        validator: (val) => val == null || val.trim().isEmpty ? l10n.validationRequired : null,
                      ),
                      const SizedBox(height: 14),
                      Text('रिश्ता / संबंध (वैकल्पिक)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _relationController,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration('उदा. मामाजी, चाचाजी, मित्र, रिश्तेदार', inputBg, textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _quickRelations.map((rel) {
                          final isSelected = _relationController.text.trim() == rel;
                          return ExpressSquish(
                            scale: 0.93,
                            onTap: () => setState(() => _relationController.text = rel),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryAccent : primaryAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? primaryAccent : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                rel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : primaryAccent,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 2. Contact Numbers Card
                  _buildSectionCard(
                    title: 'फ़ोन नंबर',
                    icon: Icons.phone_outlined,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      Text(l10n.primaryPhone, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration(l10n.phoneNumberHint, inputBg, textSecondary).copyWith(
                          prefixIcon: Icon(Icons.phone_outlined, size: 18, color: textSecondary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('व्हाट्सएप नंबर (वैकल्पिक)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration('व्हाट्सएप नंबर (यदि अलग हो)', inputBg, textSecondary).copyWith(
                          prefixIcon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.green),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 3. Location & Family Card
                  _buildSectionCard(
                    title: 'निवास व परिवार',
                    icon: Icons.location_on_outlined,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      Text('गाँव / शहर / पता', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _villageController,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration('उदा. रामपुर, जयपुर, या पूरा पता', inputBg, textSecondary).copyWith(
                          prefixIcon: Icon(Icons.pin_drop_outlined, size: 18, color: textSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('परिवार / घराना (वैकल्पिक)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                          TextButton.icon(
                            onPressed: () => _showAddFamilyDialog(l10n),
                            icon: const Icon(Icons.add, size: 14),
                            label: Text(l10n.addNewFamily, style: const TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                      familiesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => const SizedBox.shrink(),
                        data: (families) {
                          final safeValue = families.any((f) => f.id == _selectedFamilyId) ? _selectedFamilyId : null;
                          return DropdownButtonFormField<String?>(
                            value: safeValue,
                            hint: Text(l10n.noFamily, style: TextStyle(color: textSecondary, fontSize: 13)),
                            items: [
                              DropdownMenuItem(value: null, child: Text(l10n.noFamily, style: TextStyle(color: textPrimary))),
                              ...families.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, style: TextStyle(color: textPrimary)))),
                            ],
                            onChanged: (val) => setState(() => _selectedFamilyId = val),
                            decoration: _inputDecoration(l10n.selectFamilyOptional, inputBg, textSecondary),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 4. Notes Card (Optional)
                  _buildSectionCard(
                    title: 'अतिरिक्त नोट्स (वैकल्पिक)',
                    icon: Icons.notes_outlined,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration(l10n.notesOptionalHint, inputBg, textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  ExpressButton(
                    onPressed: _handleSave,
                    label: l10n.save,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color primaryAccent,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primaryAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color fill, Color hintColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 13),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
