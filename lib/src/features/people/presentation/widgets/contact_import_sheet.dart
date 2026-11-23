import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../app/app_providers.dart';
import '../../../../data/repositories/people_repository.dart';
import '../widgets/duplicate_review_dialog.dart';
import '../../services/contacts_service.dart';

/// Modal Bottom Sheet allowing users to import contacts from native phone book or vCard
class ContactImportSheet extends ConsumerStatefulWidget {
  final ValueChanged<ContactDraft>? onSingleContactPicked;
  final VoidCallback? onImportCompleted;

  const ContactImportSheet({
    super.key,
    this.onSingleContactPicked,
    this.onImportCompleted,
  });

  @override
  ConsumerState<ContactImportSheet> createState() => _ContactImportSheetState();
}

class _ContactImportSheetState extends ConsumerState<ContactImportSheet> {
  bool _isLoading = false;
  String _statusText = '';

  // Multi-contact review state
  List<ContactDraft>? _fetchedDrafts;
  final Set<String> _selectedDraftIds = {};
  final Map<String, DuplicateResolutionChoice> _duplicateResolutions = {};
  final Map<String, Map<String, bool>> _mergeFieldChoices = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _defaultFamilyId;
  String? _defaultRelationship;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handlePickSingle() async {
    setState(() {
      _isLoading = true;
      _statusText = 'फ़ोन संपर्क खोला जा रहा है...';
    });

    final draft = await ContactsService.pickSinglePhoneContact();
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (draft != null) {
      if (widget.onSingleContactPicked != null) {
        widget.onSingleContactPicked!(draft);
        Navigator.pop(context);
      } else {
        // Multi-mode: add to review
        setState(() {
          _fetchedDrafts = [draft];
          _selectedDraftIds.add(draft.id);
        });
      }
    }
  }

  Future<void> _handleFetchAllPhoneContacts() async {
    setState(() {
      _isLoading = true;
      _statusText = 'फ़ोन संपर्क पढ़े जा रहे हैं...';
    });

    final drafts = await ContactsService.fetchAllPhoneContacts(withPhotos: false);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _fetchedDrafts = drafts;
      _selectedDraftIds.addAll(drafts.map((d) => d.id));
    });
  }

  Future<void> _handleImportVCard() async {
    setState(() {
      _isLoading = true;
      _statusText = 'vCard फ़ाइल पढ़ी जा रही है...';
    });

    final drafts = await ContactsService.pickAndParseVCardFile();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (drafts.isNotEmpty) {
        _fetchedDrafts = drafts;
        _selectedDraftIds.addAll(drafts.map((d) => d.id));
      }
    });
  }

  Future<void> _executeImport(List<Person> existingPeople) async {
    if (_fetchedDrafts == null || _selectedDraftIds.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusText = 'संपर्क सहेजे जा रहे हैं...';
    });

    final repo = ref.read(peopleRepositoryProvider);
    final selectedDrafts = _fetchedDrafts!.where((d) => _selectedDraftIds.contains(d.id)).toList();

    final toCreate = <ContactDraft>[];

    for (final draft in selectedDrafts) {
      final res = repo.detectDuplicate(draft, existingPeople);
      final userChoice = _duplicateResolutions[draft.id];

      if (res.isDuplicate && res.existingPerson != null) {
        if (userChoice == DuplicateResolutionChoice.skip) {
          continue;
        } else if (userChoice == DuplicateResolutionChoice.merge) {
          final keepFields = _mergeFieldChoices[draft.id] ?? {'name': false, 'phone': false, 'address': true, 'job': true, 'company': true};
          await repo.mergePersonWithDraft(res.existingPerson!, draft, keepFields);
          continue;
        }
      }
      toCreate.add(draft);
    }

    if (toCreate.isNotEmpty) {
      await repo.importBatchContacts(
        toCreate,
        defaultFamilyId: _defaultFamilyId,
        defaultRelationship: _defaultRelationship,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pop(context);
    widget.onImportCompleted?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${toCreate.length} संपर्क सफलतापूर्वक आयात किए गए'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final existingPeople = ref.watch(activePeopleListProvider).value ?? [];
    final families = ref.watch(activeFamiliesListProvider).value ?? [];

    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final searchBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    if (_isLoading) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryAccent),
              const SizedBox(height: 16),
              Text(_statusText, style: TextStyle(color: textPrimary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // Step 2: Review and Select Contacts Screen
    if (_fetchedDrafts != null) {
      final repo = ref.read(peopleRepositoryProvider);
      final filteredDrafts = _fetchedDrafts!.where((d) {
        if (_searchQuery.isEmpty) return true;
        return d.name.toLowerCase().contains(_searchQuery) ||
            d.phones.any((p) => p.contains(_searchQuery)) ||
            d.emails.any((e) => e.toLowerCase().contains(_searchQuery));
      }).toList();

      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _fetchedDrafts = null),
                ),
                Expanded(
                  child: Text(
                    l10n.selectContactsToImport,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedDraftIds.length == _fetchedDrafts!.length) {
                        _selectedDraftIds.clear();
                      } else {
                        _selectedDraftIds.addAll(_fetchedDrafts!.map((d) => d.id));
                      }
                    });
                  },
                  child: Text(
                    _selectedDraftIds.length == _fetchedDrafts!.length ? 'सब हटाएं' : 'सभी चुनें',
                    style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search Box
            Container(
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                style: TextStyle(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'नाम या नंबर से खोजें...',
                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                  prefixIcon: Icon(Icons.search, size: 18, color: textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Optional Family & Relationship assignment
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _defaultFamilyId,
                    hint: Text(l10n.selectFamilyOptional, style: TextStyle(fontSize: 11, color: textSecondary)),
                    isDense: true,
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.noFamily, style: const TextStyle(fontSize: 12))),
                      ...families.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, style: const TextStyle(fontSize: 12)))),
                    ],
                    onChanged: (val) => setState(() => _defaultFamilyId = val),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: searchBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _defaultRelationship,
                    hint: Text(l10n.relationCategory, style: TextStyle(fontSize: 11, color: textSecondary)),
                    isDense: true,
                    items: [
                      DropdownMenuItem(value: null, child: Text('रिश्ता (वैकल्पिक)', style: const TextStyle(fontSize: 12))),
                      ...const ['पिता', 'माता', 'भाई', 'बहन', 'चाचा', 'चाची', 'मामा', 'मामी', 'मित्र', 'रिश्तेदार', 'अन्य'].map(
                        (r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12))),
                      ),
                    ],
                    onChanged: (val) => setState(() => _defaultRelationship = val),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: searchBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Contacts List
            Expanded(
              child: filteredDrafts.isEmpty
                  ? Center(
                      child: Text(
                        'कोई संपर्क नहीं मिला',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredDrafts.length,
                      itemBuilder: (context, index) {
                        final draft = filteredDrafts[index];
                        final isSelected = _selectedDraftIds.contains(draft.id);
                        final dupResult = repo.detectDuplicate(draft, existingPeople);
                        final resolution = _duplicateResolutions[draft.id];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryAccent.withValues(alpha: isDark ? 0.12 : 0.06) : cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? primaryAccent : cardBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: Checkbox(
                              value: isSelected,
                              activeColor: primaryAccent,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedDraftIds.add(draft.id);
                                  } else {
                                    _selectedDraftIds.remove(draft.id);
                                  }
                                });
                              },
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    draft.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary),
                                  ),
                                ),
                                if (dupResult.isDuplicate) ...[
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () async {
                                      final res = await showDialog<Map<String, dynamic>>(
                                        context: context,
                                        builder: (_) => DuplicateReviewDialog(
                                          existingPerson: dupResult.existingPerson!,
                                          incomingDraft: draft,
                                          matchedReason: dupResult.matchedValue ?? '',
                                        ),
                                      );
                                      if (res != null && mounted) {
                                        setState(() {
                                          _duplicateResolutions[draft.id] = res['choice'] as DuplicateResolutionChoice;
                                          if (res['keepIncomingField'] != null) {
                                            _mergeFieldChoices[draft.id] = res['keepIncomingField'] as Map<String, bool>;
                                          }
                                        });
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.amber),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amber),
                                          const SizedBox(width: 3),
                                          Text(
                                            resolution == DuplicateResolutionChoice.merge
                                                ? 'विलय'
                                                : (resolution == DuplicateResolutionChoice.skip ? 'छोड़ें' : 'डुप्लीकेट'),
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              draft.phones.isNotEmpty ? draft.phones.join(', ') : (draft.emails.isNotEmpty ? draft.emails.first : 'फ़ोन उपलब्ध नहीं'),
                              style: TextStyle(fontSize: 11.5, color: textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),

            // Import Action Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAccent,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _selectedDraftIds.isNotEmpty ? () => _executeImport(existingPeople) : null,
              child: Text(
                '${_selectedDraftIds.length} संपर्क आयात करें',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    // Step 1: Initial Entry Options Sheet
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.contacts, color: primaryAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.importFromContacts,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '100% ऑफ़लाइन व सुरक्षित • कोई डेटा बाहर नहीं जाता',
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Option 1: Pick Single from Phone
          if (ContactsService.isPhoneContactsSupported)
            _buildOptionCard(
              icon: Icons.person_search_outlined,
              title: 'फ़ोन डायरेक्टरी से एक संपर्क चुनें',
              subtitle: 'फ़ोन की संपर्क सूची से तुरंत एक व्यक्ति चुनें और विवरण भरें',
              onTap: _handlePickSingle,
              cardBg: cardBg,
              cardBorder: cardBorder,
              primaryAccent: primaryAccent,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

          if (ContactsService.isPhoneContactsSupported) const SizedBox(height: 10),

          // Option 2: Browse & Multi-Select All Contacts
          if (ContactsService.isPhoneContactsSupported)
            _buildOptionCard(
              icon: Icons.checklist_rtl_rounded,
              title: 'सभी संपर्क सूची देखें व एक साथ आयात करें',
              subtitle: 'फ़ोन के सभी संपर्कों में से पसंदीदा रिश्तेदारों को चुनकर जोड़ें',
              onTap: _handleFetchAllPhoneContacts,
              cardBg: cardBg,
              cardBorder: cardBorder,
              primaryAccent: primaryAccent,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

          if (ContactsService.isPhoneContactsSupported) const SizedBox(height: 10),

          // Option 3: Import from vCard (.vcf) - Universal
          _buildOptionCard(
            icon: Icons.file_present_outlined,
            title: l10n.importVCard,
            subtitle: 'Google Contacts, iCloud या Outlook से निर्यातित .vcf फ़ाइल से आयात करें',
            onTap: _handleImportVCard,
            cardBg: cardBg,
            cardBorder: cardBorder,
            primaryAccent: primaryAccent,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryAccent,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryAccent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
