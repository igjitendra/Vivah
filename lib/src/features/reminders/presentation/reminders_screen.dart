import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../app/app_providers.dart';
import '../../../data/database/app_database.dart';

/// Reminders Screen (अनुस्मारक - आगामी व्यवहार)
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text(
          'अनुस्मारक (Reminders)',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.terracotta,
        child: const Icon(Icons.add, color: AppColors.white),
        onPressed: () => _showAddReminderDialog(context, db),
      ),
      body: StreamBuilder<List<ReminderRow>>(
        stream: db.remindersDao.watchAllReminders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.terracotta));
          }

          final reminders = snapshot.data ?? [];
          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.mutedText.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'कोई अनुस्मारक नहीं है।',
                    style: TextStyle(fontSize: 16, color: AppColors.mutedText, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'आगामी आयोजनों या व्यवहार के लिए याद दिलाएं।',
                    style: TextStyle(fontSize: 13, color: AppColors.mutedText),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = reminders[index];
              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  db.remindersDao.deleteReminder(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('अनुस्मारक हटाया गया')),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: CheckboxListTile(
                    value: item.isCompleted,
                    activeColor: AppColors.forestGreen,
                    onChanged: (val) {
                      db.remindersDao.markCompleted(item.id, val ?? false);
                    },
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        color: item.isCompleted ? AppColors.mutedText : AppColors.darkSlate,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'दिनांक: ${VyavahaarDateUtils.formatIsoDate(item.reminderDate)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.notes!,
                            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context, AppDatabase db) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('नया अनुस्मारक बनाएं'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'शीर्षक *',
                    hintText: 'उदा. शादी में शगुन देना है',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: AppColors.terracotta),
                  title: Text('दिनांक: ${VyavahaarDateUtils.formatIsoDate(selectedDate.toIso8601String().substring(0, 10))}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2050),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: const Text('बदलें'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'टिप्पणी (वैकल्पिक)',
                    hintText: 'अतिरिक्त विवरण लिखें',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('रद्द करें'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final now = DateTime.now();
                await db.remindersDao.insertReminder(
                  RemindersCompanion.insert(
                    id: 'rem_${now.millisecondsSinceEpoch}',
                    reminderDate: selectedDate.toIso8601String().substring(0, 10),
                    title: title,
                    notes: drift.Value(notesController.text.trim().isEmpty ? null : notesController.text.trim()),
                  ),
                );
                if (context.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('सहेजें', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
