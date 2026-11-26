import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../app/app_providers.dart';
import '../../../shared/widgets/direction_badge.dart';
import '../../../shared/widgets/express_squish.dart';
import '../services/contacts_service.dart';

/// Person Profile & Personal Ledger History Screen
/// Comprehensive offline profile with intent triggers (Call, WhatsApp, SMS, Email),
/// complete multi-phone/multi-email management, and Mila/Diya transaction ledger.
class PersonDetailScreen extends ConsumerStatefulWidget {
  final String personId;
  final bool showBackButton;
  final VoidCallback? onClose;

  const PersonDetailScreen({
    super.key,
    required this.personId,
    this.showBackButton = true,
    this.onClose,
  });

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  int _refreshKey = 0;

  void _showEditPersonDialog(BuildContext context, Person person, AppLocalizations l10n) {
    final nameController = TextEditingController(text: person.fullName);
    final nicknameController = TextEditingController(text: person.nickname ?? '');
    final dobController = TextEditingController(text: person.dateOfBirth ?? '');

    final phoneController = TextEditingController(text: person.phoneNumber ?? '');
    final whatsappController = TextEditingController(text: person.whatsappNumber ?? '');

    final villageController = TextEditingController(text: person.village ?? person.address ?? '');
    final cityController = TextEditingController(text: person.city ?? '');
    final districtController = TextEditingController(text: person.district ?? '');
    final stateController = TextEditingController(text: person.state ?? '');
    final pinCodeController = TextEditingController(text: person.pinCode ?? '');

    final relationController = TextEditingController(text: person.relationshipLabel ?? '');
    final notesController = TextEditingController(text: person.notes ?? '');
    final occupationController = TextEditingController(text: person.occupation ?? '');
    final companyController = TextEditingController(text: person.company ?? '');
    final tagsController = TextEditingController(text: person.tags.join(', '));

    String? selectedFamilyId = person.familyId;
    final familiesAsync = ref.read(activeFamiliesListProvider);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.editPerson, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name
                  Text(l10n.personName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: l10n.personNameHint,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nickname & DOB
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('उपनाम (Nickname)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            const SizedBox(height: 5),
                            TextField(
                              controller: nicknameController,
                              decoration: InputDecoration(
                                hintText: 'उपनाम',
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('जन्म तिथि', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            const SizedBox(height: 5),
                            TextField(
                              controller: dobController,
                              decoration: InputDecoration(
                                hintText: 'YYYY-MM-DD',
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Primary Phone
                  Text(l10n.primaryPhone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: l10n.phoneNumberHint,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // WhatsApp
                  Text(l10n.whatsappNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'व्हाट्सएप नंबर',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Family dropdown
                  Text(l10n.selectFamilyOptional, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 5),
                  familiesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => const SizedBox.shrink(),
                    data: (families) => DropdownButtonFormField<String?>(
                      value: families.any((f) => f.id == selectedFamilyId) ? selectedFamilyId : null,
                      hint: Text(l10n.noFamily),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.noFamily, overflow: TextOverflow.ellipsis)),
                        ...families.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (val) => setDialogState(() => selectedFamilyId = val),
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Relationship
                  Text(l10n.relationCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: relationController,
                    decoration: InputDecoration(
                      hintText: l10n.hintRelationExample,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Address parts
                  Text('गाँव / कस्बा', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: villageController,
                    decoration: InputDecoration(
                      hintText: 'गाँव / कस्बा / पता',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          decoration: InputDecoration(
                            hintText: 'शहर',
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: districtController,
                          decoration: InputDecoration(
                            hintText: 'ज़िला',
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stateController,
                          decoration: InputDecoration(
                            hintText: 'राज्य',
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: pinCodeController,
                          decoration: InputDecoration(
                            hintText: 'पिन कोड',
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Occupation & Company
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: occupationController,
                          decoration: InputDecoration(
                            hintText: 'व्यवसाय',
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: companyController,
                          decoration: InputDecoration(
                            hintText: 'कंपनी / दुकान',
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tags & Notes
                  Text(l10n.tags, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: tagsController,
                    decoration: InputDecoration(
                      hintText: 'टैग (उदा. रिश्तेदार, VIP)',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(l10n.notesOptional, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: l10n.notesOptionalHint,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                try {
                  final repo = ref.read(peopleRepositoryProvider);
                  String? nonEmpty(TextEditingController c) =>
                      c.text.trim().isNotEmpty ? c.text.trim() : null;

                  final updated = Person(
                    id: person.id,
                    familyId: selectedFamilyId,
                    fullName: name,
                    firstName: person.firstName,
                    middleName: person.middleName,
                    lastName: person.lastName,
                    nickname: nonEmpty(nicknameController),
                    gender: person.gender,
                    dateOfBirth: nonEmpty(dobController),
                    photoPath: person.photoPath,
                    phoneNumber: nonEmpty(phoneController),
                    secondaryPhones: person.secondaryPhones,
                    whatsappNumber: nonEmpty(whatsappController),
                    emails: person.emails,
                    address: nonEmpty(villageController),
                    village: nonEmpty(villageController),
                    city: nonEmpty(cityController),
                    district: nonEmpty(districtController),
                    state: nonEmpty(stateController),
                    pinCode: nonEmpty(pinCodeController),
                    relationshipLabel: nonEmpty(relationController),
                    relationshipNotes: person.relationshipNotes,
                    notes: nonEmpty(notesController),
                    occupation: nonEmpty(occupationController),
                    company: nonEmpty(companyController),
                    tags: tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
                    contactSource: person.contactSource,
                    externalContactId: person.externalContactId,
                    importedAt: person.importedAt,
                    isAppEditedAfterImport: true,
                    createdAt: person.createdAt,
                    updatedAt: DateTime.now(),
                    archivedAt: person.archivedAt,
                  );

                  await repo.updatePerson(updated);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    setState(() => _refreshKey++);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.personUpdatedSuccess), backgroundColor: AppColors.milaGreen),
                    );
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
      ),
    ).whenComplete(() {
      nameController.dispose();
      nicknameController.dispose();
      dobController.dispose();
      phoneController.dispose();
      whatsappController.dispose();
      villageController.dispose();
      cityController.dispose();
      districtController.dispose();
      stateController.dispose();
      pinCodeController.dispose();
      relationController.dispose();
      notesController.dispose();
      occupationController.dispose();
      companyController.dispose();
      tagsController.dispose();
    });
  }

  Future<void> _confirmDeletePerson(BuildContext context, Person person, AppLocalizations l10n) async {
    final repo = ref.read(peopleRepositoryProvider);
    final canDelete = await repo.canDeletePerson(person.id);

    if (!context.mounted) return;

    if (!canDelete) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.confirmDeletePersonTitle),
          content: Text(l10n.cannotDeletePersonWithTransactions),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.done),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeletePersonTitle),
        content: Text(l10n.confirmDeletePerson),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.deletePersonSafely(person.id);
              if (widget.onClose != null) {
                widget.onClose!();
              } else if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final personFuture = ref.watch(peopleRepositoryProvider).getPersonById(widget.personId);
    final entriesStream = ref.watch(entriesListProvider(null));

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.personDetails,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : (widget.onClose != null
                ? IconButton(
                    icon: Icon(Icons.close, color: textPrimary),
                    onPressed: widget.onClose,
                  )
                : null),
        actions: [
          FutureBuilder<Person?>(
            key: ValueKey(_refreshKey),
            future: personFuture,
            builder: (context, snapshot) {
              final person = snapshot.data;
              if (person == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: textPrimary),
                onSelected: (val) {
                  if (val == 'edit') _showEditPersonDialog(context, person, l10n);
                  if (val == 'share') ContactsService.sharePersonCard(person);
                  if (val == 'vcard') ContactsService.exportAndShareVCard([person]);
                  if (val == 'delete') _confirmDeletePerson(context, person, l10n);
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.editPerson)),
                  PopupMenuItem(value: 'share', child: Text(l10n.shareContactAction)),
                  PopupMenuItem(value: 'vcard', child: Text(l10n.exportVCardAction)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.deletePerson, style: const TextStyle(color: Colors.red))),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Person?>(
        key: ValueKey(_refreshKey),
        future: personFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryAccent));
          }
          final person = snapshot.data;
          if (person == null) {
            return Center(child: Text(l10n.noPeopleFound));
          }

          return entriesStream.when(
            loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
            error: (err, _) => Center(child: Text('${l10n.errorGeneric}: $err')),
            data: (allEntries) {
              final personEntries = allEntries
                  .where((e) => e.personId == person.id && e.archivedAt == null)
                  .toList();

              int totalMila = 0;
              int totalDiya = 0;

              for (final e in personEntries) {
                if (e.status == TransactionStatus.recorded) {
                  if (e.direction == TransactionDirection.received ||
                      e.direction == TransactionDirection.mila) {
                    totalMila += (e.amountPaise ?? 0);
                  } else if (e.direction == TransactionDirection.given ||
                      e.direction == TransactionDirection.diya) {
                    totalDiya += (e.amountPaise ?? 0);
                  }
                }
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 40),
                children: [
                  // Profile Header Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: primaryAccent.withValues(alpha: 0.15),
                          child: Text(
                            person.initials,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          person.displayName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            if (person.relationshipLabel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: primaryAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  person.relationshipLabel!,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                                ),
                              ),
                            if (person.isPhoneImported)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.contacts, size: 12, color: Colors.blue),
                                    SizedBox(width: 4),
                                    Text(
                                      'फ़ोन संपर्क',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons Bar (Call, WhatsApp, SMS, Email, Share)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (person.phoneNumber != null && person.phoneNumber!.isNotEmpty) ...[
                              _buildActionButton(
                                icon: Icons.phone,
                                label: 'कॉल',
                                color: Colors.green,
                                onTap: () => ContactsService.callPhone(person.phoneNumber!),
                              ),
                              _buildActionButton(
                                icon: Icons.chat_bubble,
                                label: 'व्हाट्सएप',
                                color: Colors.teal,
                                onTap: () => ContactsService.openWhatsApp(person.whatsappNumber ?? person.phoneNumber!),
                              ),
                              _buildActionButton(
                                icon: Icons.sms,
                                label: 'एसएमएस',
                                color: Colors.blue,
                                onTap: () => ContactsService.sendSms(person.phoneNumber!),
                              ),
                            ],
                            if (person.emails.isNotEmpty)
                              _buildActionButton(
                                icon: Icons.email,
                                label: 'ईमेल',
                                color: Colors.deepPurple,
                                onTap: () => ContactsService.sendEmail(person.emails.first),
                              ),
                            _buildActionButton(
                              icon: Icons.share,
                              label: 'शेयर',
                              color: primaryAccent,
                              onTap: () => ContactsService.sharePersonCard(person),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Contact Details Card
                  Container(
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
                            Icon(Icons.contact_phone_outlined, size: 16, color: primaryAccent),
                            const SizedBox(width: 8),
                            Text(
                              'संपर्क व पता विवरण',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        // All Phones
                        if (person.allPhoneNumbers.isNotEmpty) ...[
                          _buildDetailRow(
                            Icons.phone_outlined,
                            l10n.primaryPhone,
                            person.allPhoneNumbers.join(' • '),
                            textPrimary,
                            textSecondary,
                          ),
                          const SizedBox(height: 8),
                        ],

                        // WhatsApp
                        if (person.whatsappNumber != null && person.whatsappNumber!.isNotEmpty) ...[
                          _buildDetailRow(
                            Icons.chat_bubble_outline,
                            l10n.whatsappNumber,
                            person.whatsappNumber!,
                            textPrimary,
                            textSecondary,
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Emails
                        if (person.emails.isNotEmpty) ...[
                          _buildDetailRow(
                            Icons.email_outlined,
                            l10n.emailAddresses,
                            person.emails.join(' • '),
                            textPrimary,
                            textSecondary,
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Full Address
                        if (person.fullAddress.isNotEmpty) ...[
                          _buildDetailRow(
                            Icons.location_on_outlined,
                            l10n.villageCity,
                            person.fullAddress,
                            textPrimary,
                            textSecondary,
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Occupation & Company
                        if (person.occupation != null || person.company != null) ...[
                          _buildDetailRow(
                            Icons.work_outline,
                            l10n.occupation,
                            [person.occupation, person.company].where((s) => s != null && s.isNotEmpty).join(' @ '),
                            textPrimary,
                            textSecondary,
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Notes
                        if (person.notes != null && person.notes!.isNotEmpty)
                          _buildDetailRow(
                            Icons.notes_outlined,
                            l10n.notes,
                            person.notes!,
                            textPrimary,
                            textSecondary,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Financial Ledger Passbook KPI
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 16, color: primaryAccent),
                            const SizedBox(width: 8),
                            Text(
                              'पारिवारिक व्यवहार हिसाब (Ledger)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.totalReceived, style: const TextStyle(fontSize: 11.5, color: Colors.green, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(CurrencyUtils.formatPaise(totalMila), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.totalGiven, style: const TextStyle(fontSize: 11.5, color: Colors.red, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(CurrencyUtils.formatPaise(totalDiya), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Pro Dual Fast-Entry Buttons: + मिला and + दिया
                        Row(
                          children: [
                            Expanded(
                              child: ExpressSquish(
                                scale: 0.96,
                                onTap: () => context.push('/entry/new?direction=received&personId=${person.id}'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.milaGreen,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.milaGreen.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.arrow_downward, color: Colors.white, size: 14),
                                      SizedBox(width: 6),
                                      Text(
                                        '+ मिला दर्ज करें',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ExpressSquish(
                                scale: 0.96,
                                onTap: () => context.push('/entry/new?direction=given&personId=${person.id}'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.diyaRed,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.diyaRed.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.arrow_upward, color: Colors.white, size: 14),
                                      SizedBox(width: 6),
                                      Text(
                                        '+ दिया दर्ज करें',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Transactions Header with Add Transaction Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.eventTransactions,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/entry/new?personId=${person.id}'),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(l10n.newTransaction, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Transactions List
                  if (personEntries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Center(
                        child: Text(
                          l10n.noTransactionsFound,
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...personEntries.map((e) {
                      final isReceived = e.direction == TransactionDirection.received ||
                          e.direction == TransactionDirection.mila;
                      final amountColor = isReceived ? Colors.green : Colors.red;
                      final prefix = isReceived ? '+' : '-';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ExpressCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          radius: 14,
                          color: cardBg,
                          borderColor: cardBorder,
                          elevation: 0,
                          onTap: () => context.push('/entry/${e.id}'),
                          child: Row(
                            children: [
                              DirectionBadge(direction: e.direction),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppDateUtils.formatIsoDate(e.transactionDate, l10n.isEnglish ? 'en' : 'hi'),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary),
                                    ),
                                    if (e.notes != null && e.notes!.isNotEmpty)
                                      Text(
                                        e.notes!,
                                        style: TextStyle(color: textSecondary, fontSize: 11.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '$prefix ${CurrencyUtils.formatPaise(e.amountPaise ?? 0)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: amountColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String val, Color primary, Color secondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10.5, color: secondary)),
              Text(val, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: primary)),
            ],
          ),
        ),
      ],
    );
  }
}
