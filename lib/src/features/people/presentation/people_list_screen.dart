import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/entities.dart';
import '../../../app/app_providers.dart';

/// People Directory Screen (लोग व रिश्तेदार)
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
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(activePeopleListProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text(
          'लोग व रिश्तेदार (People)',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          onPressed: widget.onNewPerson,
          backgroundColor: AppColors.terracotta,
          icon: const Icon(Icons.person_add, color: AppColors.white),
          label: const Text('नया व्यक्ति', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.white,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'नाम, फोन या गाँव से खोजें...',
                prefixIcon: const Icon(Icons.search, color: AppColors.mutedText),
                filled: true,
                fillColor: AppColors.warmCream,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // People List
          Expanded(
            child: peopleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
              error: (err, stack) => Center(child: Text('त्रुटि: $err')),
              data: (people) {
                final filtered = people.where((p) {
                  if (_searchQuery.isEmpty) return true;
                  final matchName = p.fullName.toLowerCase().contains(_searchQuery);
                  final matchPhone = (p.phoneNumber ?? '').toLowerCase().contains(_searchQuery);
                  final matchAddress = (p.address ?? '').toLowerCase().contains(_searchQuery);
                  return matchName || matchPhone || matchAddress;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('कोई व्यक्ति नहीं मिला', style: TextStyle(color: AppColors.mutedText, fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                    bottom: AppSpacing.floatingTabBottomPadding,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final person = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.cardBorder),
                      ),
                      elevation: 0,
                      color: AppColors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.deepNavy,
                          child: Text(
                            person.fullName.isNotEmpty ? person.fullName[0] : '?',
                            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          person.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${person.relationshipLabel ?? 'रिश्तेदार'} • ${person.address ?? 'गाँव अज्ञात'}',
                          style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
                        onTap: () => widget.onOpenPersonDetail?.call(person.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
