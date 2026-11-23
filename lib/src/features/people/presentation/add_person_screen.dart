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
import 'widgets/duplicate_review_dialog.dart';
import '../services/contacts_service.dart';

/// Advanced Screen for adding a new relative, acquaintance, or importing from phonebook
class AddPersonScreen extends ConsumerStatefulWidget {
  final ContactDraft? initialDraft;

  const AddPersonScreen({super.key, this.initialDraft});

  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Info
  final _nameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _dobController = TextEditingController();

  // Contact Info
  final _phoneController = TextEditingController();
  final List<TextEditingController> _secondaryPhoneControllers = [];
  final _whatsappController = TextEditingController();
  final List<TextEditingController> _emailControllers = [];

  // Address
  final _addressController = TextEditingController();
  final _villageController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  // Relationship & Notes
  final _relationController = TextEditingController();
  final _relationNotesController = TextEditingController();
  final _notesController = TextEditingController();

  // Professional & Metadata
  final _occupationController = TextEditingController();
  final _companyController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _selectedFamilyId;
  String _contactSource = 'manual';
  String? _externalContactId;
  DateTime? _importedAt;

  bool _isSaving = false;

  final List<String> _suggestedRelations = [
    'पिता', 'माता', 'भाई', 'बहन', 'पुत्र', 'पुत्री',
    'पति', 'पत्नी', 'चाचा', 'चाची', 'ताऊ', 'ताई',
    'मामा', 'मामी', 'दादा', 'दादी', 'नाना', 'नानी',
    'साला', 'साली', 'समधी', 'मित्र', 'अन्य',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft != null) {
      _populateFromDraft(widget.initialDraft!);
    }
  }

  void _populateFromDraft(ContactDraft d) {
    setState(() {
      _contactSource = 'phone_import';
      _externalContactId = d.externalId;
      _importedAt = DateTime.now();

      _nameController.text = d.name;
      if (d.firstName != null) _firstNameController.text = d.firstName!;
      if (d.middleName != null) _middleNameController.text = d.middleName!;
      if (d.lastName != null) _lastNameController.text = d.lastName!;
      if (d.nickname != null) _nicknameController.text = d.nickname!;
      if (d.birthday != null) _dobController.text = d.birthday!;

      if (d.primaryPhone != null) _phoneController.text = d.primaryPhone!;
      _secondaryPhoneControllers.clear();
      for (final p in d.secondaryPhones) {
        _secondaryPhoneControllers.add(TextEditingController(text: p));
      }

      _emailControllers.clear();
      for (final e in d.emails) {
        _emailControllers.add(TextEditingController(text: e));
      }

      if (d.address != null) _addressController.text = d.address!;
      if (d.village != null) _villageController.text = d.village!;
      if (d.city != null) _cityController.text = d.city!;
      if (d.state != null) _stateController.text = d.state!;
      if (d.pinCode != null) _pinCodeController.text = d.pinCode!;

      if (d.company != null) _companyController.text = d.company!;
      if (d.jobTitle != null) _occupationController.text = d.jobTitle!;
      if (d.notes != null) _notesController.text = d.notes!;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _dobController.dispose();

    _phoneController.dispose();
    for (final c in _secondaryPhoneControllers) {
      c.dispose();
    }
    _whatsappController.dispose();
    for (final c in _emailControllers) {
      c.dispose();
    }

    _addressController.dispose();
    _villageController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();

    _relationController.dispose();
    _relationNotesController.dispose();
    _notesController.dispose();

    _occupationController.dispose();
    _companyController.dispose();
    _tagsController.dispose();

    super.dispose();
  }

  void _addSecondaryPhoneField() {
    setState(() {
      _secondaryPhoneControllers.add(TextEditingController());
    });
  }

  void _removeSecondaryPhoneField(int index) {
    setState(() {
      _secondaryPhoneControllers[index].dispose();
      _secondaryPhoneControllers.removeAt(index);
    });
  }

  void _addEmailField() {
    setState(() {
      _emailControllers.add(TextEditingController());
    });
  }

  void _removeEmailField(int index) {
    setState(() {
      _emailControllers[index].dispose();
      _emailControllers.removeAt(index);
    });
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
              final repo = ref.read(familiesRepositoryProvider);
              final newId = const Uuid().v4();
              final now = DateTime.now();
              await repo.createFamily(Family(id: newId, name: name, createdAt: now, updatedAt: now));
              if (mounted) {
                setState(() => _selectedFamilyId = newId);
                Navigator.pop(ctx);
              }
            },
            child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    final repo = ref.read(peopleRepositoryProvider);
    final now = DateTime.now();

    final secondaryPhones = _secondaryPhoneControllers
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty && p != _phoneController.text.trim())
        .toList();

    final emails = _emailControllers
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final person = Person(
      id: const Uuid().v4(),
      familyId: _selectedFamilyId,
      fullName: name,
      firstName: _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : null,
      middleName: _middleNameController.text.trim().isNotEmpty ? _middleNameController.text.trim() : null,
      lastName: _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim() : null,
      nickname: _nicknameController.text.trim().isNotEmpty ? _nicknameController.text.trim() : null,
      dateOfBirth: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
      phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      secondaryPhones: secondaryPhones,
      whatsappNumber: _whatsappController.text.trim().isNotEmpty ? _whatsappController.text.trim() : null,
      emails: emails,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      village: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : null,
      city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      district: _districtController.text.trim().isNotEmpty ? _districtController.text.trim() : null,
      state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
      pinCode: _pinCodeController.text.trim().isNotEmpty ? _pinCodeController.text.trim() : null,
      relationshipLabel: _relationController.text.trim().isNotEmpty ? _relationController.text.trim() : null,
      relationshipNotes: _relationNotesController.text.trim().isNotEmpty ? _relationNotesController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      occupation: _occupationController.text.trim().isNotEmpty ? _occupationController.text.trim() : null,
      company: _companyController.text.trim().isNotEmpty ? _companyController.text.trim() : null,
      tags: tags,
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
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.personSavedSuccess), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final familiesAsync = ref.watch(activeFamiliesListProvider);

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
        title: Text(
          _contactSource == 'phone_import' ? 'संपर्क से जोड़ें' : l10n.addNewPerson,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                  // Top Entry Switcher Banner: Add Manually vs Import from Phone Contacts
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
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
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _contactSource == 'manual' ? primaryAccent.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _contactSource == 'manual' ? primaryAccent : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_note, size: 18, color: _contactSource == 'manual' ? primaryAccent : textSecondary),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: _openContactImportSheet,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _contactSource == 'phone_import' ? primaryAccent.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _contactSource == 'phone_import' ? primaryAccent : cardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.contacts, size: 18, color: primaryAccent),
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'फ़ोन संपर्क से विवरण प्राप्त किया गया। आप इसे सहेजने से पहले संपादित कर सकते हैं।',
                              style: TextStyle(fontSize: 12, color: textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Section 1: Personal Information
                  _buildSectionCard(
                    title: '1. व्यक्तिगत विवरण (Personal Information)',
                    icon: Icons.person_outline,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      Text(l10n.personName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration(l10n.personNameHint, inputBg, textSecondary),
                        validator: (val) => val == null || val.trim().isEmpty ? l10n.validationRequired : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('उपनाम / पुकारू नाम', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nicknameController,
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: _inputDecoration('उदा. चिंटू, बबुआ', inputBg, textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('जन्म तिथि', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _dobController,
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: _inputDecoration('YYYY-MM-DD', inputBg, textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Section 2: Contact Numbers & Emails
                  _buildSectionCard(
                    title: '2. फ़ोन व संपर्क नंबर (Phone & Emails)',
                    icon: Icons.phone_outlined,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      Text(l10n.primaryPhone, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration(l10n.phoneNumberHint, inputBg, textSecondary).copyWith(
                          prefixIcon: Icon(Icons.phone, size: 18, color: textSecondary),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Dynamic Secondary Phones
                      if (_secondaryPhoneControllers.isNotEmpty) ...[
                        Text(l10n.secondaryPhones, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                        const SizedBox(height: 6),
                        ..._secondaryPhoneControllers.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final ctrl = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.phone,
                                    style: TextStyle(color: textPrimary, fontSize: 14),
                                    decoration: _inputDecoration('अतिरिक्त मोबाइल', inputBg, textSecondary),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                  onPressed: () => _removeSecondaryPhoneField(idx),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addSecondaryPhoneField,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+ अतिरिक्त फ़ोन जोड़ें', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // WhatsApp Number
                      Text(l10n.whatsappNumber, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration('व्हाट्सएप नंबर (यदि अलग है)', inputBg, textSecondary).copyWith(
                          prefixIcon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.green),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Emails
                      if (_emailControllers.isNotEmpty) ...[
                        Text(l10n.emailAddresses, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                        const SizedBox(height: 6),
                        ..._emailControllers.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final ctrl = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(color: textPrimary, fontSize: 14),
                                    decoration: _inputDecoration('ईमेल पता', inputBg, textSecondary),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                  onPressed: () => _removeEmailField(idx),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addEmailField,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+ ईमेल पता जोड़ें', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Section 3: Family & Relationship
                  _buildSectionCard(
                    title: '3. परिवार व रिश्ता (Family & Relationship)',
                    icon: Icons.diversity_3_outlined,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      // Family dropdown with inline add
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.selectFamilyOptional, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
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
                        data: (families) => DropdownButtonFormField<String?>(
                          value: _selectedFamilyId,
                          hint: Text(l10n.noFamily, style: TextStyle(color: textSecondary, fontSize: 13)),
                          items: [
                            DropdownMenuItem(value: null, child: Text(l10n.noFamily, style: TextStyle(color: textPrimary))),
                            ...families.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, style: TextStyle(color: textPrimary)))),
                          ],
                          onChanged: (val) => setState(() => _selectedFamilyId = val),
                          decoration: _inputDecoration(l10n.selectFamilyOptional, inputBg, textSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Relationship Chips
                      Text(l10n.relationCategory, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _relationController,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration(l10n.hintRelationExample, inputBg, textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _suggestedRelations.map((rel) {
                          final isSelected = _relationController.text.trim() == rel;
                          return ExpressSquish(
                            scale: 0.92,
                            onTap: () => setState(() => _relationController.text = rel),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryAccent : primaryAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                rel,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
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

                  // Section 4: Address & Geography
                  _buildSectionCard(
                    title: '4. गाँव व पता (Address & Location)',
                    icon: Icons.location_on_outlined,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      Text(l10n.villageCity, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _villageController,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration('गाँव / मोहल्ला / कस्बा', inputBg, textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.city, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _cityController,
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: _inputDecoration('शहर', inputBg, textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.district, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _districtController,
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: _inputDecoration('ज़िला', inputBg, textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.state, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _stateController,
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: _inputDecoration('राज्य', inputBg, textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.pinCode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _pinCodeController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: _inputDecoration('पिन कोड', inputBg, textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Section 5: Professional, Tags & Notes
                  _buildSectionCard(
                    title: '5. व्यवसाय, टैग व नोट्स (Additional Info)',
                    icon: Icons.work_outline,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.occupation, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _occupationController,
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: _inputDecoration('व्यवसाय', inputBg, textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.company, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _companyController,
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: _inputDecoration('कंपनी / दुकान', inputBg, textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('टैग (अल्पविराम से अलग करें)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _tagsController,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration('उदा. रिश्तेदार, गाँव के लोग, वीआईपी', inputBg, textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.notesOptional, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
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
                  const SizedBox(height: 30),
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
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 14),
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
