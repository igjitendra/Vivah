import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/empty_detail_pane.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';
import 'person_detail_screen.dart';
import 'widgets/contact_import_sheet.dart';
import '../services/contacts_service.dart';

enum PeopleSort { nameAsc, mostTransactions, highestReceived, highestGiven, recentlyAdded }
enum PeopleFilter { all, activeOnly, zeroBalance, phoneImported, manual }

/// Advanced Screen displaying the directory of relatives and families/clans
/// Supports Contact Book Import, vCard/CSV Export, Multi-Select Bulk Actions, and Direct Intent Triggers.
class PeopleListScreen extends ConsumerStatefulWidget {
  final VoidCallback onNewPerson;
  final ValueChanged<String>? onOpenPersonDetail;

  const PeopleListScreen({
    super.key,
    required this.onNewPerson,
    this.onOpenPersonDetail,
  });

  @override
  ConsumerState<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends ConsumerState<PeopleListScreen> {
  int _currentTab = 0; // 0 = People, 1 = Families
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPersonId;

  // Filtering & Sorting
  PeopleFilter _activeFilter = PeopleFilter.all;
  PeopleSort _activeSort = PeopleSort.nameAsc;

  // Multi-Select Bulk Mode
  bool _isMultiSelectMode = false;
  final Set<String> _selectedPersonIds = {};

  @override
  void dispose() {
    _searchController.dispose();
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
          onImportCompleted: () {
            ref.invalidate(activePeopleListProvider);
          },
        ),
      ),
    );
  }

  void _showAddFamilyDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addNewFamily, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.familyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: l10n.familyNameHint,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.familyDescription, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                hintText: l10n.familyDescriptionHint,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final repo = ref.read(familiesRepositoryProvider);
              final now = DateTime.now();
              final family = Family(
                id: const Uuid().v4(),
                name: name,
                description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                createdAt: now,
                updatedAt: now,
              );

              await repo.createFamily(family);

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.familySavedSuccess)),
                );
              }
            },
            child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFamilyMembersSheet(BuildContext context, Family family, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final peopleAsync = ref.watch(activePeopleListProvider);
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      family.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                if (family.description != null && family.description!.isNotEmpty)
                  Text(family.description!, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const Divider(height: 20),
                peopleAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('${l10n.errorGeneric}: $err'),
                  data: (people) {
                    final members = people.where((p) => p.familyId == family.id).toList();
                    if (members.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            l10n.noFamilyMembersYet,
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final m = members[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(m.fullName.isNotEmpty ? m.fullName[0] : '?'),
                          ),
                          title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(m.relationshipLabel ?? l10n.relativeDefault),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () {
                            Navigator.pop(ctx);
                            widget.onOpenPersonDetail?.call(m.id);
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // Bulk Operations Handlers
  Future<void> _handleBulkAssignFamily(List<Person> allPeople, List<Family> families) async {
    String? chosenFamilyId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('परिवार असाइन करें (Assign Family)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: DropdownButtonFormField<String?>(
            value: chosenFamilyId,
            hint: const Text('परिवार चुनें'),
            items: [
              const DropdownMenuItem(value: null, child: Text('परिवार से हटाएं (None)')),
              ...families.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))),
            ],
            onChanged: (val) => setDialogState(() => chosenFamilyId = val),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('रद्द करें')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('असाइन करें')),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(peopleRepositoryProvider);
      await repo.bulkAssignFamily(_selectedPersonIds.toList(), chosenFamilyId);
      setState(() {
        _isMultiSelectMode = false;
        _selectedPersonIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('परिवार सफलतापूर्वक अपडेट किया गया')));
      }
    }
  }

  Future<void> _handleBulkAddTag() async {
    final tagCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('टैग जोड़ें (Add Tag)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: tagCtrl,
          decoration: const InputDecoration(hintText: 'उदा. रिश्तेदार, VIP, गांव'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('रद्द करें')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('जोड़ें')),
        ],
      ),
    );

    if (confirmed == true && tagCtrl.text.trim().isNotEmpty) {
      final repo = ref.read(peopleRepositoryProvider);
      await repo.bulkAddTag(_selectedPersonIds.toList(), tagCtrl.text.trim());
      setState(() {
        _isMultiSelectMode = false;
        _selectedPersonIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('टैग सफलतापूर्वक लगाया गया')));
      }
    }
  }

  Future<void> _handleBulkExportVCard(List<Person> allPeople) async {
    final selected = allPeople.where((p) => _selectedPersonIds.contains(p.id)).toList();
    if (selected.isEmpty) return;
    await ContactsService.exportAndShareVCard(selected);
  }

  Future<void> _handleBulkExportCsv(List<Person> allPeople) async {
    final selected = allPeople.where((p) => _selectedPersonIds.contains(p.id)).toList();
    if (selected.isEmpty) return;
    await ContactsService.exportAndShareCsv(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final peopleAsync = ref.watch(activePeopleListProvider);
    final familiesAsync = ref.watch(activeFamiliesListProvider);
    final entriesAsync = ref.watch(entriesListProvider(null));

    // Aggregate person-wise transactions for Pro Level Relative Directory
    final Map<String, ({int totalMila, int totalDiya, int count})> personStats = {};
    if (entriesAsync.hasValue) {
      for (final entry in entriesAsync.value!) {
        if (entry.archivedAt != null || entry.status != TransactionStatus.recorded) continue;
        final existing = personStats[entry.personId] ?? (totalMila: 0, totalDiya: 0, count: 0);
        final isReceived = entry.direction == TransactionDirection.received;
        final amount = entry.amountPaise ?? 0;
        personStats[entry.personId] = (
          totalMila: existing.totalMila + (isReceived ? amount : 0),
          totalDiya: existing.totalDiya + (!isReceived ? amount : 0),
          count: existing.count + 1,
        );
      }
    }

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final searchBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;
    final wide = isWideLayout(context);

    final masterList = Column(
      children: [
        // Multi-Select Top Bar OR Standard Tab Bar
        if (_isMultiSelectMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            color: primaryAccent.withValues(alpha: 0.15),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _isMultiSelectMode = false;
                    _selectedPersonIds.clear();
                  }),
                ),
                Text(
                  '${_selectedPersonIds.length} चयनित',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                ),
                const Spacer(),
                peopleAsync.when(
                  data: (people) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'vCard निर्यात',
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: () => _handleBulkExportVCard(people),
                      ),
                      IconButton(
                        tooltip: 'CSV निर्यात',
                        icon: const Icon(Icons.file_download, size: 20),
                        onPressed: () => _handleBulkExportCsv(people),
                      ),
                      familiesAsync.when(
                        data: (fams) => PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (val) {
                            if (val == 'family') _handleBulkAssignFamily(people, fams);
                            if (val == 'tag') _handleBulkAddTag();
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'family', child: Text('परिवार से जोड़ें')),
                            const PopupMenuItem(value: 'tag', child: Text('टैग लगाएं')),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 0,
                        label: Text(l10n.peopleTab, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        icon: const Icon(Icons.person, size: 16),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text(l10n.familiesTab, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        icon: const Icon(Icons.family_restroom, size: 16),
                      ),
                    ],
                    selected: {_currentTab},
                    onSelectionChanged: (set) => setState(() => _currentTab = set.first),
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                if (_currentTab == 0) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'संपर्क आयात करें',
                    icon: Icon(Icons.person_add_alt_1, color: primaryAccent),
                    onPressed: _openContactImportSheet,
                  ),
                ],
              ],
            ),
          ),

        // Search Bar & Filter Chips
        if (_currentTab == 0)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: searchBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cardBorder),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                          style: TextStyle(fontSize: 14, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.searchPeopleHint,
                            hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                            prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: textSecondary, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Pro Smart Sort Button
                    Container(
                      decoration: BoxDecoration(
                        color: _activeSort != PeopleSort.nameAsc ? primaryAccent.withValues(alpha: 0.15) : searchBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _activeSort != PeopleSort.nameAsc ? primaryAccent : cardBorder),
                      ),
                      child: PopupMenuButton<PeopleSort>(
                        tooltip: 'सॉर्ट करें',
                        icon: Icon(
                          Icons.sort_rounded,
                          color: _activeSort != PeopleSort.nameAsc ? primaryAccent : textSecondary,
                          size: 20,
                        ),
                        initialValue: _activeSort,
                        onSelected: (sort) => setState(() => _activeSort = sort),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: PeopleSort.nameAsc,
                            child: Row(
                              children: [
                                Icon(Icons.sort_by_alpha, size: 18, color: _activeSort == PeopleSort.nameAsc ? primaryAccent : textSecondary),
                                const SizedBox(width: 8),
                                const Text('नाम (A-Z)'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: PeopleSort.mostTransactions,
                            child: Row(
                              children: [
                                Icon(Icons.trending_up, size: 18, color: _activeSort == PeopleSort.mostTransactions ? primaryAccent : textSecondary),
                                const SizedBox(width: 8),
                                const Text('सर्वाधिक लेन-देन'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: PeopleSort.highestReceived,
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward, size: 18, color: _activeSort == PeopleSort.highestReceived ? AppColors.milaGreen : textSecondary),
                                const SizedBox(width: 8),
                                const Text('सर्वाधिक मिला'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: PeopleSort.highestGiven,
                            child: Row(
                              children: [
                                Icon(Icons.arrow_upward, size: 18, color: _activeSort == PeopleSort.highestGiven ? AppColors.diyaRed : textSecondary),
                                const SizedBox(width: 8),
                                const Text('सर्वाधिक दिया'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: PeopleSort.recentlyAdded,
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: _activeSort == PeopleSort.recentlyAdded ? primaryAccent : textSecondary),
                                const SizedBox(width: 8),
                                const Text('हाल ही में जोड़े गए'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Pro Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: l10n.all,
                        isSelected: _activeFilter == PeopleFilter.all,
                        onTap: () => setState(() => _activeFilter = PeopleFilter.all),
                        primaryAccent: primaryAccent,
                        cardBorder: cardBorder,
                        textSecondary: textSecondary,
                      ),
                      _buildFilterChip(
                        label: 'सक्रिय लेन-देन',
                        isSelected: _activeFilter == PeopleFilter.activeOnly,
                        onTap: () => setState(() => _activeFilter = PeopleFilter.activeOnly),
                        primaryAccent: primaryAccent,
                        cardBorder: cardBorder,
                        textSecondary: textSecondary,
                      ),
                      _buildFilterChip(
                        label: 'बिना लेन-देन',
                        isSelected: _activeFilter == PeopleFilter.zeroBalance,
                        onTap: () => setState(() => _activeFilter = PeopleFilter.zeroBalance),
                        primaryAccent: primaryAccent,
                        cardBorder: cardBorder,
                        textSecondary: textSecondary,
                      ),
                      _buildFilterChip(
                        label: 'फ़ोन से आयातित',
                        isSelected: _activeFilter == PeopleFilter.phoneImported,
                        onTap: () => setState(() => _activeFilter = PeopleFilter.phoneImported),
                        primaryAccent: primaryAccent,
                        cardBorder: cardBorder,
                        textSecondary: textSecondary,
                      ),
                      _buildFilterChip(
                        label: 'मैन्युअल प्रविष्टि',
                        isSelected: _activeFilter == PeopleFilter.manual,
                        onTap: () => setState(() => _activeFilter = PeopleFilter.manual),
                        primaryAccent: primaryAccent,
                        cardBorder: cardBorder,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                style: TextStyle(fontSize: 14, color: textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.searchPeopleHint,
                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                  prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

        // Tab Content
        Expanded(
          child: _currentTab == 0
              ? _buildPeopleTab(
                  peopleAsync: peopleAsync,
                  personStats: personStats,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  primaryAccent: primaryAccent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  wide: wide,
                  isDark: isDark,
                  l10n: l10n,
                )
              : _buildFamiliesTab(
                  familiesAsync: familiesAsync,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  primaryAccent: primaryAccent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  l10n: l10n,
                ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.peopleTitle,
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
        shape: const Border(),
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          if (_currentTab == 0 && !_isMultiSelectMode)
            IconButton(
              tooltip: 'मल्टी-सेलेक्ट मोड',
              icon: Icon(Icons.checklist, color: textPrimary),
              onPressed: () => setState(() => _isMultiSelectMode = true),
            ),
        ],
      ),
      floatingActionButton: wide
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 75),
              child: ExpressSquish(
                scale: 0.94,
                onTap: _currentTab == 0
                    ? widget.onNewPerson
                    : () => _showAddFamilyDialog(context, ref, l10n),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: primaryAccent,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAccent.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _currentTab == 0 ? l10n.newPerson : l10n.newFamily,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: wide
          ? Row(
              children: [
                SizedBox(
                  width: 440,
                  child: masterList,
                ),
                VerticalDivider(width: 1, thickness: 1, color: cardBorder),
                Expanded(
                  child: _selectedPersonId != null
                      ? PersonDetailScreen(
                          key: ValueKey(_selectedPersonId),
                          personId: _selectedPersonId!,
                          showBackButton: false,
                          onClose: () => setState(() => _selectedPersonId = null),
                        )
                      : EmptyDetailPane(
                          title: l10n.selectPersonToViewDetails,
                          icon: Icons.person_pin_outlined,
                          actionLabel: l10n.newPerson,
                          onAction: widget.onNewPerson,
                        ),
                ),
              ],
            )
          : masterList,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryAccent,
    required Color cardBorder,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? primaryAccent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryAccent : cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryAccent : textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeopleTab({
    required AsyncValue<List<Person>> peopleAsync,
    required Map<String, ({int totalMila, int totalDiya, int count})> personStats,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryAccent,
    required Color textPrimary,
    required Color textSecondary,
    required bool wide,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return peopleAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
      error: (err, stack) => Center(child: Text('${l10n.errorGeneric}: $err', style: const TextStyle(color: Colors.red))),
      data: (people) {
        var filtered = people.where((p) {
          // Search
          if (_searchQuery.isNotEmpty) {
            final match = p.fullName.toLowerCase().contains(_searchQuery) ||
                (p.phoneNumber ?? '').contains(_searchQuery) ||
                p.secondaryPhones.any((sec) => sec.contains(_searchQuery)) ||
                (p.address ?? '').toLowerCase().contains(_searchQuery) ||
                (p.village ?? '').toLowerCase().contains(_searchQuery) ||
                (p.relationshipLabel ?? '').toLowerCase().contains(_searchQuery);
            if (!match) return false;
          }

          // Source & Ledger Activity filter
          final stats = personStats[p.id];
          final hasTransactions = stats != null && stats.count > 0;
          if (_activeFilter == PeopleFilter.activeOnly && !hasTransactions) return false;
          if (_activeFilter == PeopleFilter.zeroBalance && hasTransactions) return false;
          if (_activeFilter == PeopleFilter.phoneImported && !p.isPhoneImported) return false;
          if (_activeFilter == PeopleFilter.manual && p.isPhoneImported) return false;

          return true;
        }).toList();

        // Pro Smart Multi-Sorting
        switch (_activeSort) {
          case PeopleSort.nameAsc:
            filtered.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
            break;
          case PeopleSort.mostTransactions:
            filtered.sort((a, b) {
              final countA = personStats[a.id]?.count ?? 0;
              final countB = personStats[b.id]?.count ?? 0;
              if (countB != countA) return countB.compareTo(countA);
              return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
            });
            break;
          case PeopleSort.highestReceived:
            filtered.sort((a, b) {
              final milaA = personStats[a.id]?.totalMila ?? 0;
              final milaB = personStats[b.id]?.totalMila ?? 0;
              if (milaB != milaA) return milaB.compareTo(milaA);
              return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
            });
            break;
          case PeopleSort.highestGiven:
            filtered.sort((a, b) {
              final diyaA = personStats[a.id]?.totalDiya ?? 0;
              final diyaB = personStats[b.id]?.totalDiya ?? 0;
              if (diyaB != diyaA) return diyaB.compareTo(diyaA);
              return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
            });
            break;
          case PeopleSort.recentlyAdded:
            filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
        }

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBorder),
                    ),
                    child: Icon(Icons.people_outline, size: 48, color: textSecondary.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.noPeopleFound, style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'खोज के अनुसार कोई व्यक्ति नहीं मिला।'
                        : 'अपने रिश्तेदारों को जोड़ने के लिए "+ नया व्यक्ति" पर टैप करें या ऊपर दिए बटन से फ़ोन संपर्क आयात करें।',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: wide ? AppSpacing.md : AppSpacing.floatingTabBottomPadding + 20,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final p = filtered[index];
            final isSelected = wide && _selectedPersonId == p.id;
            final isMultiChecked = _selectedPersonIds.contains(p.id);
            final stats = personStats[p.id];

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ExpressCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                radius: 16,
                color: isSelected ? primaryAccent.withValues(alpha: 0.1) : cardBg,
                borderColor: isSelected ? primaryAccent : cardBorder,
                borderWidth: isSelected ? 2.0 : 1.0,
                elevation: isSelected ? 2 : 0,
                onLongPress: () {
                  setState(() {
                    _isMultiSelectMode = true;
                    _selectedPersonIds.add(p.id);
                  });
                },
                onTap: () {
                  if (_isMultiSelectMode) {
                    setState(() {
                      if (isMultiChecked) {
                        _selectedPersonIds.remove(p.id);
                        if (_selectedPersonIds.isEmpty) _isMultiSelectMode = false;
                      } else {
                        _selectedPersonIds.add(p.id);
                      }
                    });
                  } else if (wide) {
                    setState(() => _selectedPersonId = p.id);
                  } else {
                    widget.onOpenPersonDetail?.call(p.id);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isMultiSelectMode) ...[
                          Checkbox(
                            value: isMultiChecked,
                            activeColor: primaryAccent,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedPersonIds.add(p.id);
                                } else {
                                  _selectedPersonIds.remove(p.id);
                                  if (_selectedPersonIds.isEmpty) _isMultiSelectMode = false;
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                        ],

                        // Avatar with Initials
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: primaryAccent.withValues(alpha: 0.15),
                          child: Text(
                            p.initials,
                            style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.displayName,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (p.isPhoneImported) ...[
                                    const SizedBox(width: 4),
                                    Tooltip(
                                      message: 'फ़ोन संपर्क से आयातित',
                                      child: Icon(Icons.contacts, size: 14, color: primaryAccent),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  if (p.relationshipLabel != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryAccent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        p.relationshipLabel!,
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: primaryAccent),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (p.village != null && p.village!.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p.village!,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (p.phoneNumber != null)
                                    Expanded(
                                      child: Text(
                                        p.phoneNumber!,
                                        style: TextStyle(color: textSecondary, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  else if (p.address != null)
                                    Expanded(
                                      child: Text(
                                        p.address!,
                                        style: TextStyle(color: textSecondary, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Direct Intent Quick Action Buttons (Call, WhatsApp, Add Transaction)
                        if (!_isMultiSelectMode) ...[
                          if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.phone_outlined, size: 19, color: Colors.green),
                              tooltip: l10n.callAction,
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              padding: EdgeInsets.zero,
                              onPressed: () => ContactsService.callPhone(p.phoneNumber!),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline, size: 19, color: Colors.teal),
                              tooltip: l10n.whatsappAction,
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              padding: EdgeInsets.zero,
                              onPressed: () => ContactsService.openWhatsApp(p.phoneNumber!),
                            ),
                          ],
                          PopupMenuButton<String>(
                            tooltip: 'व्यवहार जोड़ें',
                            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                            padding: EdgeInsets.zero,
                            icon: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: primaryAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.add, size: 16, color: primaryAccent),
                            ),
                            onSelected: (val) {
                              if (val == 'received') {
                                context.push('/entry/new?direction=received&personId=${p.id}');
                              } else if (val == 'given') {
                                context.push('/entry/new?direction=given&personId=${p.id}');
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'received',
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_downward, size: 16, color: AppColors.milaGreen),
                                    SizedBox(width: 8),
                                    Text('+ मिला दर्ज करें', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.milaGreen, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'given',
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_upward, size: 16, color: AppColors.diyaRed),
                                    SizedBox(width: 8),
                                    Text('+ दिया दर्ज करें', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.diyaRed, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    // Pro Financial Ledger Snapshot Row
                    if (stats != null && stats.count > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131720) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cardBorder.withValues(alpha: 0.7)),
                        ),
                        child: Row(
                          children: [
                            if (stats.totalMila > 0) ...[
                              const Icon(Icons.arrow_downward, size: 12, color: AppColors.milaGreen),
                              const SizedBox(width: 3),
                              Text(
                                'मिला: ${CurrencyUtils.formatPaise(stats.totalMila)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.milaGreen),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (stats.totalDiya > 0) ...[
                              const Icon(Icons.arrow_upward, size: 12, color: AppColors.diyaRed),
                              const SizedBox(width: 3),
                              Text(
                                'दिया: ${CurrencyUtils.formatPaise(stats.totalDiya)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.diyaRed),
                              ),
                            ],
                            if (stats.totalMila == 0 && stats.totalDiya == 0)
                              Text(
                                'उपहार / वस्तु (${stats.count})',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                              ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: primaryAccent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${stats.count} व्यवहार',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFamiliesTab({
    required AsyncValue<List<Family>> familiesAsync,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryAccent,
    required Color textPrimary,
    required Color textSecondary,
    required AppLocalizations l10n,
  }) {
    return familiesAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
      error: (err, stack) => Center(child: Text('${l10n.errorGeneric}: $err', style: const TextStyle(color: Colors.red))),
      data: (families) {
        final filtered = families.where((f) {
          if (_searchQuery.isEmpty) return true;
          return f.name.toLowerCase().contains(_searchQuery) ||
              (f.description ?? '').toLowerCase().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBorder),
                    ),
                    child: Icon(Icons.family_restroom, size: 48, color: textSecondary.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.noFamiliesFound, style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final f = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ExpressCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                radius: 16,
                color: cardBg,
                borderColor: cardBorder,
                elevation: 0,
                onTap: () => _showFamilyMembersSheet(context, f, l10n),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryAccent.withValues(alpha: 0.15),
                      child: Icon(Icons.family_restroom, color: primaryAccent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                          ),
                          if (f.description != null && f.description!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              f.description!,
                              style: TextStyle(color: textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: textSecondary, size: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
