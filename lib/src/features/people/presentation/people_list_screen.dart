import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/entities.dart';
import '../../../shared/widgets/empty_detail_pane.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';
import 'person_detail_screen.dart';

/// Modern Card-Based Screen displaying the directory of relatives and families/clans
/// Fully theme-adaptive with search, tab switching, and tactile spring interactions.
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
  int _currentTab = 0; // 0 = People (लोग), 1 = Families (परिवार)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPersonId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                            'इस परिवार में अभी कोई सदस्य नहीं जुड़ा है।',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final peopleAsync = ref.watch(activePeopleListProvider);
    final familiesAsync = ref.watch(activeFamiliesListProvider);

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final searchBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;
    final wide = isWideLayout(context);

    final masterList = Column(
        children: [
          // 1. Tab Selector (People vs Families)
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
              ],
            ),
          ),

          // 2. Search Bar Pill
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
                  hintText: _currentTab == 0 ? l10n.searchPeopleHint : 'परिवार या गाँव से खोजें...',
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
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // 3. Tab Content View
          Expanded(
            child: _currentTab == 0
                // Tab A: People Directory
                ? peopleAsync.when(
                    loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text('${l10n.errorGeneric}: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                    data: (people) {
                      final filtered = people.where((p) {
                        if (_searchQuery.isEmpty) return true;
                        final matchName = p.fullName.toLowerCase().contains(_searchQuery);
                        final matchPhone = (p.phoneNumber ?? '').toLowerCase().contains(_searchQuery);
                        final matchAddress = (p.address ?? '').toLowerCase().contains(_searchQuery);
                        return matchName || matchPhone || matchAddress;
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
                                  child: Icon(Icons.people_outline, size: 48, color: textSecondary.withValues(alpha: 0.6)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.noPeopleFound,
                                  style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
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
                          final person = filtered[index];
                          final rel = person.relationshipLabel ?? l10n.relativeDefault;
                          final addr = person.address ?? l10n.villageUnknown;
                          final isSelected = wide && _selectedPersonId == person.id;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: ExpressCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              radius: 16,
                              color: isSelected
                                  ? primaryAccent.withValues(alpha: isDark ? 0.15 : 0.08)
                                  : cardBg,
                              borderColor: isSelected ? primaryAccent : cardBorder,
                              borderWidth: isSelected ? 2.0 : 1.0,
                              elevation: isSelected ? 2 : 0,
                              onTap: () {
                                if (wide) {
                                  setState(() => _selectedPersonId = person.id);
                                } else {
                                  widget.onOpenPersonDetail?.call(person.id);
                                }
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: primaryAccent.withValues(alpha: 0.18),
                                    child: Text(
                                      person.fullName.isNotEmpty ? person.fullName[0] : '?',
                                      style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          person.fullName,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$rel • $addr',
                                          style: TextStyle(color: textSecondary, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                  )
                // Tab B: Families Directory
                : familiesAsync.when(
                    loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text('${l10n.errorGeneric}: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                    data: (families) {
                      final filtered = families.where((f) {
                        if (_searchQuery.isEmpty) return true;
                        final matchName = f.name.toLowerCase().contains(_searchQuery);
                        final matchDesc = (f.description ?? '').toLowerCase().contains(_searchQuery);
                        return matchName || matchDesc;
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
                                Text(
                                  l10n.noFamiliesFound,
                                  style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          top: AppSpacing.md,
                          bottom: AppSpacing.floatingTabBottomPadding + 20,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final family = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: ExpressCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              radius: 16,
                              color: cardBg,
                              borderColor: cardBorder,
                              elevation: 0,
                              onTap: () => _showFamilyMembersSheet(context, family, l10n),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: primaryAccent.withValues(alpha: 0.15),
                                    child: Icon(Icons.house_siding_rounded, color: primaryAccent, size: 22),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          family.name,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (family.description != null && family.description!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            family.description!,
                                            style: TextStyle(color: textSecondary, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final peopleAsync = ref.watch(activePeopleListProvider);
                                      final count = peopleAsync.value?.where((p) => p.familyId == family.id).length ?? 0;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: searchBg,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: cardBorder),
                                        ),
                                        child: Text(
                                          '$count ${l10n.membersCount}',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right, color: textSecondary, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      );

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          _currentTab == 0 ? l10n.peopleTitle : l10n.familiesTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: headerBg,
        elevation: 0,
      ),
      floatingActionButton: wide
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 75),
              child: ExpressSquish(
                scale: 0.94,
                onTap: () {
                  if (_currentTab == 0) {
                    widget.onNewPerson();
                  } else {
                    _showAddFamilyDialog(context, ref, l10n);
                  }
                },
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
                      Icon(_currentTab == 0 ? Icons.person_add : Icons.group_add, color: Colors.white, size: 20),
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
                          icon: Icons.person_outline,
                          actionLabel: l10n.newPerson,
                          onAction: widget.onNewPerson,
                        ),
                ),
              ],
            )
          : masterList,
    );
  }
}
