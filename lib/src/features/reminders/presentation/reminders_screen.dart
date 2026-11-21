import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/date_utils.dart';
import '../../../app/app_providers.dart';
import '../../../data/database/app_database.dart';

/// Reminders Screen (अनुस्मारक - आगामी व्यवहार)
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: Text(
          l10n.remindersTitle,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.terracotta,
        child: const Icon(Icons.add, color: AppColors.white),
        onPressed: () => _showAddReminderDialog(context, db, l10n),
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
                  Text(
                    l10n.noReminders,
                    style: const TextStyle(fontSize: 16, color: AppColors.mutedText, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.noRemindersSubtitle,
                    style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
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
                    SnackBar(content: Text(l10n.reminderDeleted)),
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
                          '${l10n.datePrefix}${VyavahaarDateUtils.formatIsoDate(item.reminderDate)}',
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

  void _showAddReminderDialog(BuildContext context, AppDatabase db, AppLocalizations l10n) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.newReminder),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: l10n.reminderTitleLabel,
                    hintText: l10n.reminderTitleHint,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: AppColors.terracotta),
                  title: Text('${l10n.datePrefix}${VyavahaarDateUtils.formatIsoDate(selectedDate.toIso8601String().substring(0, 10))}'),
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
                    child: Text(l10n.changeDate),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: l10n.notesOptional,
                    hintText: l10n.notesOptionalHint,
                  ),
                  maxLines: 2,
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
              child: Text(l10n.save, style: const TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
