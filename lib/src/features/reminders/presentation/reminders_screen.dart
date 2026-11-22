import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../entries/providers/entries_providers.dart';

/// Screen managing reminders for upcoming shagun, bahi deadlines, and family ceremonies.
/// Fully theme-adaptive with Material 3 styling and tactile feedback.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final db = ref.watch(databaseProvider);
    final l10n = context.l10n;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.remindersTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ExpressSquish(
          scale: 0.94,
          onTap: () => _showAddReminderDialog(context, db, l10n, cardBg, textPrimary, primaryAccent),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryAccent.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
      ),
      body: StreamBuilder<List<ReminderRow>>(
        stream: db.remindersDao.watchAllReminders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryAccent));
          }

          final reminders = snapshot.data ?? [];
          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noReminders,
                    style: TextStyle(fontSize: 16, color: textPrimary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.noRemindersSubtitle,
                    style: TextStyle(fontSize: 13, color: textSecondary),
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
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  db.remindersDao.deleteReminder(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.reminderDeleted)),
                  );
                },
                child: ExpressCard(
                  padding: EdgeInsets.zero,
                  radius: 14,
                  color: cardBg,
                  borderColor: cardBorder,
                  elevation: 0,
                  child: CheckboxListTile(
                    value: item.isCompleted,
                    activeColor: AppColors.milaGreen,
                    onChanged: (val) {
                      db.remindersDao.markCompleted(item.id, val ?? false);
                    },
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        color: item.isCompleted ? textSecondary : textPrimary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.datePrefix}${VyavahaarDateUtils.formatIsoDate(item.reminderDate, l10n.locale.languageCode)}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.notes!,
                            style: TextStyle(fontSize: 12, color: textSecondary),
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

  void _showAddReminderDialog(
    BuildContext context,
    AppDatabase db,
    AppLocalizations l10n,
    Color cardBg,
    Color textPrimary,
    Color primaryAccent,
  ) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.newReminder, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.reminderTitleLabel,
                    hintText: l10n.reminderTitleHint,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: primaryAccent),
                  title: Text(
                    '${l10n.datePrefix}${VyavahaarDateUtils.formatIsoDate(selectedDate.toIso8601String().substring(0, 10), l10n.locale.languageCode)}',
                    style: TextStyle(color: textPrimary, fontSize: 14),
                  ),
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
                    child: Text(l10n.changeDate, style: TextStyle(color: primaryAccent)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  style: TextStyle(color: textPrimary),
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
              style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
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
              child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
