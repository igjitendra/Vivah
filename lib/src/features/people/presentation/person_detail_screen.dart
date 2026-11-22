import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
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

/// Person Profile & Personal Ledger History Screen
/// Fully theme-adaptive with Mila/Diya balance passbook, editing, and transaction stream.
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
    final relationController = TextEditingController(text: person.relationshipLabel ?? '');
    final addressController = TextEditingController(text: person.address ?? '');
    final phoneController = TextEditingController(text: person.phoneNumber ?? '');
    final notesController = TextEditingController(text: person.notes ?? '');
    String? selectedFamilyId = person.familyId;

    final familiesAsync = ref.read(activeFamiliesListProvider);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.editPerson, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.personName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.relationCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: relationController,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.selectFamilyOptional, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                familiesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => const SizedBox.shrink(),
                  data: (families) => DropdownButtonFormField<String?>(
                    value: selectedFamilyId,
                    hint: Text(l10n.noFamily),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.noFamily)),
                      ...families.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))),
                    ],
                    onChanged: (val) => setDialogState(() => selectedFamilyId = val),
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.villageCity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.phoneNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.notes, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ],
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

                final repo = ref.read(peopleRepositoryProvider);
                final updated = Person(
                  id: person.id,
                  fullName: name,
                  familyId: selectedFamilyId,
                  relationshipLabel: relationController.text.trim().isNotEmpty ? relationController.text.trim() : null,
                  address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
                  phoneNumber: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                  notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                  createdAt: person.createdAt,
                  updatedAt: DateTime.now(),
                );

                await repo.updatePerson(updated);

                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() => _refreshKey++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.personUpdatedSuccess), backgroundColor: AppColors.milaGreen),
                  );
                }
              },
              child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
              await repo.archivePerson(person.id);
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
    final peopleRepo = ref.watch(peopleRepositoryProvider);
    final entriesRepo = ref.watch(entriesRepositoryProvider);
    final familiesRepo = ref.watch(familiesRepositoryProvider);
    final l10n = context.l10n;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      key: ValueKey(_refreshKey),
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: Text(l10n.personDetails, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
              tooltip: 'बंद करें',
            ),
        ],
      ),
      body: FutureBuilder<Person?>(
        future: peopleRepo.getPersonById(widget.personId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryAccent));
          }
          final person = snapshot.data;
          if (person == null) {
            return Center(child: Text(l10n.personNotFound, style: TextStyle(color: textPrimary)));
          }

          return FutureBuilder<Map<String, int>>(
            future: entriesRepo.getPersonHistoryStats(widget.personId),
            builder: (context, statsSnap) {
              final stats = statsSnap.data ?? {'received_paise': 0, 'given_paise': 0};
              final receivedPaise = stats['received_paise'] ?? 0;
              final givenPaise = stats['given_paise'] ?? 0;

              return Column(
                children: [
                  // Person Header Card
                  Container(
                    width: double.infinity,
                    color: headerBg,
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                person.fullName,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                              tooltip: l10n.editPerson,
                              onPressed: () => _showEditPersonDialog(context, person, l10n),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                              tooltip: l10n.deletePerson,
                              onPressed: () => _confirmDeletePerson(context, person, l10n),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${person.relationshipLabel ?? l10n.relativeDefault} • ${person.address ?? l10n.villageUnknown}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                            ),
                            if (person.familyId != null) ...[
                              const SizedBox(width: 8),
                              FutureBuilder<Family?>(
                                future: familiesRepo.getFamilyById(person.familyId!),
                                builder: (context, fSnap) {
                                  final fam = fSnap.data;
                                  if (fam == null) return const SizedBox.shrink();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.family_restroom, size: 12, color: Colors.white),
                                        const SizedBox(width: 3),
                                        Text(
                                          fam.name,
                                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                        if (person.phoneNumber != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                person.phoneNumber!,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Balance Cards Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.milaGreen.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.milaGreen.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.totalReceived,
                                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyUtils.formatPaise(receivedPaise),
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.diyaRed.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.diyaRed.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.totalGiven,
                                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyUtils.formatPaise(givenPaise),
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // History Heading
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 18, color: primaryAccent),
                        const SizedBox(width: 8),
                        Text(l10n.personHistory, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                      ],
                    ),
                  ),

                  // Entries Stream
                  Expanded(
                    child: StreamBuilder<List<TransactionEntry>>(
                      stream: entriesRepo.watchEntries(personId: widget.personId),
                      builder: (context, entrySnap) {
                        if (entrySnap.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: primaryAccent));
                        }
                        final entries = entrySnap.data ?? [];
                        if (entries.isEmpty) {
                          return Center(child: Text(l10n.noTransactionsForPerson, style: TextStyle(color: textSecondary)));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: entries.length,
                          itemBuilder: (context, idx) {
                            final e = entries[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ExpressCard(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                radius: 14,
                                color: cardBg,
                                borderColor: cardBorder,
                                elevation: 0,
                                child: Row(
                                  children: [
                                    DirectionBadge(direction: e.direction),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.amountPaise != null ? CurrencyUtils.formatPaise(e.amountPaise!) : l10n.giftItem,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: e.direction == TransactionDirection.received ? AppColors.milaGreen : AppColors.diyaRed,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${e.eventTitle ?? l10n.generalEvent} • ${VyavahaarDateUtils.formatIsoDate(e.transactionDate, l10n.locale.languageCode)}',
                                            style: TextStyle(color: textSecondary, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (e.items.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.card_giftcard, size: 15, color: textSecondary),
                                          const SizedBox(width: 4),
                                          Text('${e.items.length}', style: TextStyle(color: textSecondary, fontSize: 12)),
                                        ],
                                      ),
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
            },
          );
        },
      ),
    );
  }
}
