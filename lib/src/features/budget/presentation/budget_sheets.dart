import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../app/app_providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/express_type.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/entities.dart';
import '../../../shared/widgets/express_button.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';
import '../domain/budget_models.dart';
import 'budget_providers.dart';

const _uuid = Uuid();
const List<String> _upiApps = ['GPay', 'PhonePe', 'Paytm', 'BHIM', 'Bank/NEFT'];

/// Shared rounded modal container respecting tablet max-width & keyboard insets.
Widget _budgetModalShell({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<Widget> children,
}) {
  final semantic = AppSemanticColors.of(context);
  return SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: ExpressType.titleLarge(
                color: semantic.textPrimary,
                weight: FontWeight.w800,
              ).copyWith(fontSize: 19),
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: ExpressType.bodySmall(color: semantic.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    ),
  );
}

/// Opens Cash vs Online/UPI mode & optional UPI App + Reference inputs.
class _PaymentModeSection extends StatelessWidget {
  final String mode;
  final String? upiApp;
  final TextEditingController upiRefController;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String?> onUpiAppChanged;

  const _PaymentModeSection({
    required this.mode,
    required this.upiApp,
    required this.upiRefController,
    required this.onModeChanged,
    required this.onUpiAppChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final isOnline = mode == 'upi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.paymentMode,
          style: ExpressType.labelLarge(color: semantic.textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ModeChoiceChip(
                icon: Icons.payments_outlined,
                label: l10n.paymentCash,
                selected: !isOnline,
                onTap: () => onModeChanged('cash'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ModeChoiceChip(
                icon: Icons.qr_code_2_rounded,
                label: l10n.paymentOnline,
                selected: isOnline,
                onTap: () => onModeChanged('upi'),
              ),
            ),
          ],
        ),
        if (isOnline) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _upiApps.map((app) {
              final active = upiApp == app;
              return ChoiceChip(
                label: Text(app, style: const TextStyle(fontSize: 12)),
                selected: active,
                selectedColor: semantic.primary.withValues(alpha: 0.16),
                onSelected: (sel) => onUpiAppChanged(sel ? app : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: upiRefController,
            decoration: InputDecoration(
              labelText: l10n.upiRefLabel,
              hintText: l10n.upiRefHint,
              prefixIcon: const Icon(Icons.tag_rounded, size: 18),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeChoiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChoiceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return ExpressSquish(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Express.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? semantic.primary.withValues(alpha: 0.14)
              : semantic.cardSubtleBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? semantic.primary : semantic.cardBorder,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? semantic.primary : semantic.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ExpressType.labelMedium(
                  color: selected ? semantic.primary : semantic.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final String? isoDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerTile({
    required this.label,
    required this.isoDate,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final display = (isoDate != null && isoDate!.isNotEmpty)
        ? AppDateUtils.formatLocalizedDate(isoDate, l10n.locale.languageCode)
        : '-';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: semantic.cardSubtleBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: semantic.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 17, color: semantic.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ExpressType.labelSmall(color: semantic.textSecondary),
                  ),
                  Text(
                    display,
                    style: ExpressType.titleSmall(color: semantic.textPrimary),
                  ),
                ],
              ),
            ),
            if (onClear != null && isoDate != null && isoDate!.isNotEmpty)
              IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close_rounded, size: 17, color: semantic.textSecondary),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

/// Opens safe `tel:` dialer link when a contact phone number is present.
Future<void> launchPhoneCall(BuildContext context, String phone) async {
  final clean = phone.trim();
  if (clean.isEmpty) return;
  try {
    await launchUrl(Uri(scheme: 'tel', path: clean));
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(clean)),
      );
    }
  }
}

/// Sheet 1: Add New Event Expense / Vendor Deal (Cash/UPI + Receipt Photo + Optional Balance Reminder).
Future<void> showAddBudgetExpenseSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<Event> events,
  required List<EventBudgetCategory> allCategories,
  String? preselectedEventId,
  String? preselectedCategoryId,
  String? prefillVendorName,
  String? prefillVendorPhone,
}) async {
  final l10n = context.l10n;
  final semantic = AppSemanticColors.of(context);
  if (events.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.createEventBeforeExpenseHint)),
    );
    return;
  }

  final people = [...(ref.read(activePeopleListProvider).value ?? const <Person>[])]
    ..sort((a, b) => a.fullName.compareTo(b.fullName));

  var selectedEventId = preselectedEventId ?? events.first.id;
  var selectedCategoryId = preselectedCategoryId;
  String? selectedPersonId;
  var paymentMode = 'cash';
  String? selectedUpiApp = 'GPay';
  var expenseDate = AppDateUtils.getTodayIsoString();
  String? targetPayDate;
  var autoReminder = true;
  String? receiptPath;
  var saving = false;

  final vendorCtrl = TextEditingController(text: prefillVendorName ?? '');
  final phoneCtrl = TextEditingController(text: prefillVendorPhone ?? '');
  final titleCtrl = TextEditingController();
  final agreedCtrl = TextEditingController();
  final paidCtrl = TextEditingController();
  final upiRefCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: semantic.cardBg,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: phoneWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final eventCats =
            allCategories.where((c) => c.eventId == selectedEventId).toList();
        if (selectedCategoryId != null &&
            !eventCats.any((c) => c.id == selectedCategoryId)) {
          selectedCategoryId = null;
        }
        final agreedPaise =
            CurrencyUtils.parseInputToPaise(agreedCtrl.text.trim()) ?? 0;
        final paidPaise =
            CurrencyUtils.parseInputToPaise(paidCtrl.text.trim()) ?? 0;
        final remainingPaise =
            agreedPaise > paidPaise ? agreedPaise - paidPaise : 0;

        return _budgetModalShell(
          context: ctx,
          title: l10n.addExpenseBtn,
          subtitle: l10n.budgetIsolatedNote,
          children: [
            DropdownButtonFormField<String>(
              value: selectedEventId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.tabEvents),
              items: events
                  .map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.title, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setSheetState(() {
                  selectedEventId = val;
                  selectedCategoryId = null;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              value: selectedCategoryId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.budgetTabCategories),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.unlinkedGeneralLabel),
                ),
                ...eventCats.map((c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.categoryName, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (val) => setSheetState(() => selectedCategoryId = val),
            ),
            if (people.isNotEmpty) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                value: selectedPersonId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.pickFromRelativesHint),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.unlinkedGeneralLabel),
                  ),
                  ...people.map((p) => DropdownMenuItem<String?>(
                        value: p.id,
                        child: Text(p.fullName, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (val) {
                  setSheetState(() {
                    selectedPersonId = val;
                    final match = people.where((p) => p.id == val).firstOrNull;
                    if (match != null) {
                      if (vendorCtrl.text.trim().isEmpty) {
                        vendorCtrl.text = match.fullName;
                      }
                      if (phoneCtrl.text.trim().isEmpty &&
                          (match.phoneNumber?.isNotEmpty ?? false)) {
                        phoneCtrl.text = match.phoneNumber!;
                      }
                    }
                  });
                },
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: vendorCtrl,
              decoration: InputDecoration(
                labelText: l10n.payeeVendorLabel,
                prefixIcon: const Icon(Icons.storefront_outlined, size: 19),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: '${l10n.phoneNumber} (${l10n.optionalField})',
                prefixIcon: const Icon(Icons.phone_outlined, size: 19),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: l10n.expenseItemLabel,
                prefixIcon: const Icon(Icons.receipt_long_outlined, size: 19),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: agreedCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.agreedDealLabel,
                      prefixText: '₹ ',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: paidCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.paidNowLabel,
                      prefixText: '₹ ',
                    ),
                  ),
                ),
              ],
            ),
            if (remainingPaise > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: semantic.warningContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${l10n.balanceRemainingLabel}: ${CurrencyUtils.formatPaise(remainingPaise)}',
                  style: ExpressType.labelLarge(color: semantic.warning),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _PaymentModeSection(
              mode: paymentMode,
              upiApp: selectedUpiApp,
              upiRefController: upiRefCtrl,
              onModeChanged: (m) => setSheetState(() => paymentMode = m),
              onUpiAppChanged: (a) => setSheetState(() => selectedUpiApp = a),
            ),
            const SizedBox(height: 12),
            _DatePickerTile(
              label: l10n.transactionDate,
              isoDate: expenseDate,
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.tryParse(expenseDate) ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setSheetState(
                    () => expenseDate = AppDateUtils.toIsoDateString(picked),
                  );
                }
              },
            ),
            if (remainingPaise > 0) ...[
              const SizedBox(height: 10),
              _DatePickerTile(
                label: l10n.returnTargetDateLabel,
                isoDate: targetPayDate,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setSheetState(
                      () => targetPayDate = AppDateUtils.toIsoDateString(picked),
                    );
                  }
                },
                onClear: () => setSheetState(() => targetPayDate = null),
              ),
              if (targetPayDate != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: autoReminder,
                  onChanged: (v) => setSheetState(() => autoReminder = v),
                  title: Text(
                    l10n.autoReminderBalanceToggle,
                    style: ExpressType.bodySmall(
                      color: semantic.textPrimary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final saved = await ImageStorageService.pickAndSaveCompressedImage(
                  context: ctx,
                  l10n: l10n,
                  subFolder: 'budget_receipts',
                  prefix: 'bill',
                );
                if (saved != null) {
                  setSheetState(() => receiptPath = saved.path);
                }
              },
              icon: Icon(
                receiptPath != null
                    ? Icons.check_circle_outline
                    : Icons.receipt_outlined,
              ),
              label: Text(
                receiptPath != null
                    ? l10n.billAttachedBadge
                    : l10n.attachReceiptPhotoLabel,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.notesOptional),
            ),
            const SizedBox(height: 16),
            ExpressButton(
              label: l10n.save,
              expand: true,
              isLoading: saving,
              onPressed: () async {
                final vendor = vendorCtrl.text.trim();
                final title = titleCtrl.text.trim().isNotEmpty
                    ? titleCtrl.text.trim()
                    : vendor;
                if (vendor.isEmpty || (agreedPaise <= 0 && paidPaise <= 0)) {
                  return;
                }
                setSheetState(() => saving = true);
                final matchedCat = eventCats
                    .where((c) => c.id == selectedCategoryId)
                    .firstOrNull;
                final now = DateTime.now();
                final expense = BudgetExpense(
                  id: _uuid.v4(),
                  eventId: selectedEventId,
                  categoryId: selectedCategoryId,
                  categoryName: matchedCat?.categoryName ?? '',
                  vendorName: vendor,
                  vendorPhone: phoneCtrl.text.trim(),
                  personId: selectedPersonId,
                  title: title,
                  agreedAmountPaise: agreedPaise,
                  paidAmountPaise: paidPaise,
                  paymentMode: paymentMode,
                  upiApp: paymentMode == 'upi' ? selectedUpiApp : null,
                  upiRef: paymentMode == 'upi' ? upiRefCtrl.text.trim() : null,
                  expenseDate: expenseDate,
                  targetPayDate: targetPayDate,
                  billPhotoPath: receiptPath,
                  notes: notesCtrl.text.trim(),
                  createdAt: now,
                  updatedAt: now,
                );
                await ref.read(budgetRepositoryProvider).saveExpense(
                      expense: expense,
                      autoAddReminder: autoReminder && targetPayDate != null,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    ),
  );

  vendorCtrl.dispose();
  phoneCtrl.dispose();
  titleCtrl.dispose();
  agreedCtrl.dispose();
  paidCtrl.dispose();
  upiRefCtrl.dispose();
  notesCtrl.dispose();
}

/// Sheet 2: Record an installment payment towards an existing [BudgetExpense].
Future<void> showAddInstallmentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required BudgetExpense expense,
}) async {
  final l10n = context.l10n;
  final semantic = AppSemanticColors.of(context);
  final amountCtrl = TextEditingController();
  final upiRefCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  var paymentMode = 'cash';
  String? selectedUpiApp = 'GPay';
  var paymentDate = AppDateUtils.getTodayIsoString();
  String? receiptPath;
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: semantic.cardBg,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: phoneWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setSheetState) => _budgetModalShell(
        context: ctx,
        title: l10n.addInstallmentLabel,
        subtitle: '${expense.vendorName} • ${expense.title}',
        children: [
          if (expense.remainingPaise > 0) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: Icon(Icons.flash_on_rounded, size: 15, color: semantic.primary),
                label: Text(
                  '${l10n.balanceRemainingLabel}: ${CurrencyUtils.formatPaise(expense.remainingPaise)}',
                ),
                onPressed: () {
                  amountCtrl.text = (expense.remainingPaise / 100).round().toString();
                  setSheetState(() {});
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.paidNowLabel,
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 12),
          _PaymentModeSection(
            mode: paymentMode,
            upiApp: selectedUpiApp,
            upiRefController: upiRefCtrl,
            onModeChanged: (m) => setSheetState(() => paymentMode = m),
            onUpiAppChanged: (a) => setSheetState(() => selectedUpiApp = a),
          ),
          const SizedBox(height: 12),
          _DatePickerTile(
            label: l10n.transactionDate,
            isoDate: paymentDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: DateTime.tryParse(paymentDate) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setSheetState(() => paymentDate = AppDateUtils.toIsoDateString(picked));
              }
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final saved = await ImageStorageService.pickAndSaveCompressedImage(
                context: ctx,
                l10n: l10n,
                subFolder: 'budget_receipts',
                prefix: 'pay',
              );
              if (saved != null) setSheetState(() => receiptPath = saved.path);
            },
            icon: Icon(receiptPath != null ? Icons.check_circle_outline : Icons.receipt_outlined),
            label: Text(
              receiptPath != null ? l10n.billAttachedBadge : l10n.attachReceiptPhotoLabel,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteCtrl,
            decoration: InputDecoration(labelText: l10n.notesOptional),
          ),
          const SizedBox(height: 16),
          ExpressButton(
            label: l10n.save,
            expand: true,
            isLoading: saving,
            onPressed: () async {
              final paise = CurrencyUtils.parseInputToPaise(amountCtrl.text.trim()) ?? 0;
              if (paise <= 0) return;
              setSheetState(() => saving = true);
              await ref.read(budgetRepositoryProvider).addExpensePayment(
                    payment: BudgetExpensePayment(
                      id: _uuid.v4(),
                      expenseId: expense.id,
                      eventId: expense.eventId,
                      amountPaise: paise,
                      paymentMode: paymentMode,
                      upiApp: paymentMode == 'upi' ? selectedUpiApp : null,
                      upiRef: paymentMode == 'upi' ? upiRefCtrl.text.trim() : null,
                      paymentDate: paymentDate,
                      receiptPhotoPath: receiptPath,
                      note: noteCtrl.text.trim(),
                      createdAt: DateTime.now(),
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );

  amountCtrl.dispose();
  upiRefCtrl.dispose();
  noteCtrl.dispose();
}

/// Sheet 3: View Expense / Vendor Deal details, photo receipt, installment timeline, & delete.
Future<void> showExpenseDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required BudgetExpense expense,
}) async {
  final l10n = context.l10n;
  final semantic = AppSemanticColors.of(context);
  final hasBill =
      expense.billPhotoPath != null && File(expense.billPhotoPath!).existsSync();

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: semantic.cardBg,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: phoneWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _budgetModalShell(
      context: ctx,
      title: expense.vendorName,
      subtitle: expense.categoryName.isNotEmpty
          ? '${expense.title} • ${expense.categoryName}'
          : expense.title,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: semantic.cardSubtleBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: semantic.cardBorder),
          ),
          child: Row(
            children: [
              _statPair(
                l10n.agreedDealLabel,
                CurrencyUtils.formatPaise(expense.effectiveTotalPaise),
                semantic.textPrimary,
                semantic,
              ),
              _statPair(
                l10n.totalPaidOutLabel,
                CurrencyUtils.formatPaise(expense.paidAmountPaise),
                semantic.mila,
                semantic,
              ),
              _statPair(
                l10n.balanceRemainingLabel,
                CurrencyUtils.formatPaise(expense.remainingPaise),
                expense.remainingPaise > 0 ? semantic.diya : semantic.mila,
                semantic,
              ),
            ],
          ),
        ),
        if (hasBill) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => FullScreenImageViewer.show(
              ctx,
              expense.billPhotoPath!,
              title: expense.title,
            ),
            borderRadius: BorderRadius.circular(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(expense.billPhotoPath!),
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          l10n.paymentHistoryLabel,
          style: ExpressType.titleSmall(color: semantic.textPrimary),
        ),
        const SizedBox(height: 8),
        if (expense.payments.isEmpty)
          Text(
            '-',
            style: ExpressType.bodySmall(color: semantic.textSecondary),
          )
        else
          ...expense.payments.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: semantic.cardSubtleBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: semantic.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      p.paymentMode == 'upi'
                          ? Icons.qr_code_2_rounded
                          : Icons.payments_outlined,
                      size: 16,
                      color: semantic.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppDateUtils.formatLocalizedDate(
                              p.paymentDate,
                              l10n.locale.languageCode,
                            ),
                            style: ExpressType.labelMedium(
                              color: semantic.textPrimary,
                            ),
                          ),
                          if (p.upiApp != null || (p.note?.isNotEmpty ?? false))
                            Text(
                              [
                                if (p.upiApp != null) p.upiApp!,
                                if (p.upiRef?.isNotEmpty ?? false) p.upiRef!,
                                if (p.note?.isNotEmpty ?? false) p.note!,
                              ].join(' • '),
                              style: ExpressType.bodySmall(
                                color: semantic.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyUtils.formatPaise(p.amountPaise),
                      style: ExpressType.titleSmall(color: semantic.mila),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 14),
        Row(
          children: [
            if ((expense.vendorPhone?.isNotEmpty ?? false)) ...[
              ExpressIconButton(
                icon: Icons.call_outlined,
                onPressed: () => launchPhoneCall(ctx, expense.vendorPhone!),
              ),
              const SizedBox(width: 8),
            ],
            ExpressIconButton(
              icon: Icons.delete_outline_rounded,
              tint: semantic.diya,
              onPressed: () async {
                await ref.read(budgetRepositoryProvider).deleteExpense(expense.id);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ExpressButton(
                label: l10n.addInstallmentLabel,
                icon: Icons.add_rounded,
                expand: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  showAddInstallmentSheet(
                    context: context,
                    ref: ref,
                    expense: expense,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Sheet 4: Record a Temporary Borrowed Fund Arrangement (किससे कितना लिया).
Future<void> showAddFundArrangementSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<Event> events,
  String? preselectedEventId,
}) async {
  final l10n = context.l10n;
  final semantic = AppSemanticColors.of(context);
  final people = [...(ref.read(activePeopleListProvider).value ?? const <Person>[])]
    ..sort((a, b) => a.fullName.compareTo(b.fullName));

  String? selectedEventId = preselectedEventId;
  String? selectedPersonId;
  var paymentMode = 'cash';
  String? selectedUpiApp = 'GPay';
  var takenDate = AppDateUtils.getTodayIsoString();
  String? returnTargetDate;
  var autoReminder = true;
  var saving = false;

  final lenderCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final principalCtrl = TextEditingController();
  final extraCtrl = TextEditingController();
  final upiRefCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: semantic.cardBg,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: phoneWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setSheetState) => _budgetModalShell(
        context: ctx,
        title: l10n.addBorrowBtn,
        subtitle: l10n.budgetIsolatedNote,
        children: [
          if (people.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              value: selectedPersonId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.pickFromRelativesHint),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.unlinkedGeneralLabel),
                ),
                ...people.map((p) => DropdownMenuItem<String?>(
                      value: p.id,
                      child: Text(p.fullName, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (val) {
                setSheetState(() {
                  selectedPersonId = val;
                  final match = people.where((p) => p.id == val).firstOrNull;
                  if (match != null) {
                    lenderCtrl.text = match.fullName;
                    if (match.phoneNumber?.isNotEmpty ?? false) {
                      phoneCtrl.text = match.phoneNumber!;
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: lenderCtrl,
            decoration: InputDecoration(
              labelText: l10n.lenderNameLabel,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 19),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: '${l10n.phoneNumber} (${l10n.optionalField})',
              prefixIcon: const Icon(Icons.phone_outlined, size: 19),
            ),
          ),
          const SizedBox(height: 10),
          if (events.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              value: selectedEventId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.tabEvents),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.unlinkedGeneralLabel),
                ),
                ...events.map((e) => DropdownMenuItem<String?>(
                      value: e.id,
                      child: Text(e.title, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (val) => setSheetState(() => selectedEventId = val),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: principalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.takenAmountLabel,
                    prefixText: '₹ ',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: extraCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.extraReturnLabel,
                    prefixText: '₹ ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PaymentModeSection(
            mode: paymentMode,
            upiApp: selectedUpiApp,
            upiRefController: upiRefCtrl,
            onModeChanged: (m) => setSheetState(() => paymentMode = m),
            onUpiAppChanged: (a) => setSheetState(() => selectedUpiApp = a),
          ),
          const SizedBox(height: 12),
          _DatePickerTile(
            label: l10n.takenDateLabel,
            isoDate: takenDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: DateTime.tryParse(takenDate) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setSheetState(() => takenDate = AppDateUtils.toIsoDateString(picked));
              }
            },
          ),
          const SizedBox(height: 10),
          _DatePickerTile(
            label: l10n.returnTargetDateLabel,
            isoDate: returnTargetDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setSheetState(
                  () => returnTargetDate = AppDateUtils.toIsoDateString(picked),
                );
              }
            },
            onClear: () => setSheetState(() => returnTargetDate = null),
          ),
          if (returnTargetDate != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: autoReminder,
              onChanged: (v) => setSheetState(() => autoReminder = v),
              title: Text(
                l10n.autoReminderReturnToggle,
                style: ExpressType.bodySmall(
                  color: semantic.textPrimary,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(labelText: l10n.notesOptional),
          ),
          const SizedBox(height: 16),
          ExpressButton(
            label: l10n.save,
            expand: true,
            isLoading: saving,
            onPressed: () async {
              final lender = lenderCtrl.text.trim();
              final principal =
                  CurrencyUtils.parseInputToPaise(principalCtrl.text.trim()) ?? 0;
              if (lender.isEmpty || principal <= 0) return;
              final extra =
                  CurrencyUtils.parseInputToPaise(extraCtrl.text.trim()) ?? 0;
              setSheetState(() => saving = true);
              final now = DateTime.now();
              await ref.read(budgetRepositoryProvider).saveFundArrangement(
                    arrangement: FundArrangement(
                      id: _uuid.v4(),
                      eventId: selectedEventId,
                      lenderName: lender,
                      lenderPhone: phoneCtrl.text.trim(),
                      personId: selectedPersonId,
                      principalPaise: principal,
                      extraAgreedPaise: extra,
                      returnedPaise: 0,
                      paymentMode: paymentMode,
                      upiApp: paymentMode == 'upi' ? selectedUpiApp : null,
                      upiRef:
                          paymentMode == 'upi' ? upiRefCtrl.text.trim() : null,
                      takenDate: takenDate,
                      returnTargetDate: returnTargetDate,
                      notes: notesCtrl.text.trim(),
                      isSettled: false,
                      createdAt: now,
                      updatedAt: now,
                    ),
                    autoAddReminder: autoReminder && returnTargetDate != null,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );

  lenderCtrl.dispose();
  phoneCtrl.dispose();
  principalCtrl.dispose();
  extraCtrl.dispose();
  upiRefCtrl.dispose();
  notesCtrl.dispose();
}

/// Sheet 5: Record a partial or full repayment towards a [FundArrangement].
Future<void> showRecordRepaymentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required FundArrangement arrangement,
}) async {
  final l10n = context.l10n;
  final semantic = AppSemanticColors.of(context);
  final amountCtrl = TextEditingController();
  final upiRefCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  var paymentMode = 'cash';
  String? selectedUpiApp = 'GPay';
  var repaymentDate = AppDateUtils.getTodayIsoString();
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: semantic.cardBg,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: phoneWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setSheetState) => _budgetModalShell(
        context: ctx,
        title: l10n.recordReturnBtn,
        subtitle: arrangement.lenderName,
        children: [
          if (arrangement.remainingPaise > 0) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: Icon(Icons.flash_on_rounded, size: 15, color: semantic.mila),
                label: Text(
                  '${l10n.returnRemainingLabel}: ${CurrencyUtils.formatPaise(arrangement.remainingPaise)}',
                ),
                onPressed: () {
                  amountCtrl.text =
                      (arrangement.remainingPaise / 100).round().toString();
                  setSheetState(() {});
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.returnedAmountLabel,
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 12),
          _PaymentModeSection(
            mode: paymentMode,
            upiApp: selectedUpiApp,
            upiRefController: upiRefCtrl,
            onModeChanged: (m) => setSheetState(() => paymentMode = m),
            onUpiAppChanged: (a) => setSheetState(() => selectedUpiApp = a),
          ),
          const SizedBox(height: 12),
          _DatePickerTile(
            label: l10n.transactionDate,
            isoDate: repaymentDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: DateTime.tryParse(repaymentDate) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setSheetState(
                  () => repaymentDate = AppDateUtils.toIsoDateString(picked),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteCtrl,
            decoration: InputDecoration(labelText: l10n.notesOptional),
          ),
          const SizedBox(height: 16),
          ExpressButton(
            label: l10n.save,
            expand: true,
            isLoading: saving,
            onPressed: () async {
              final paise = CurrencyUtils.parseInputToPaise(amountCtrl.text.trim()) ?? 0;
              if (paise <= 0) return;
              setSheetState(() => saving = true);
              await ref.read(budgetRepositoryProvider).addFundRepayment(
                    repayment: FundRepayment(
                      id: _uuid.v4(),
                      arrangementId: arrangement.id,
                      amountPaise: paise,
                      paymentMode: paymentMode,
                      upiApp: paymentMode == 'upi' ? selectedUpiApp : null,
                      upiRef:
                          paymentMode == 'upi' ? upiRefCtrl.text.trim() : null,
                      repaymentDate: repaymentDate,
                      note: noteCtrl.text.trim(),
                      createdAt: DateTime.now(),
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );

  amountCtrl.dispose();
  upiRefCtrl.dispose();
  noteCtrl.dispose();
}

/// Sheet 6: Detail & Repayment History for a [FundArrangement].
Future<void> showArrangementDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required FundArrangement arrangement,
  String? eventName,
}) async {
  final l10n = context.l10n;
  final semantic = AppSemanticColors.of(context);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: semantic.cardBg,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: phoneWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _budgetModalShell(
      context: ctx,
      title: arrangement.lenderName,
      subtitle: [
        if (eventName != null) eventName,
        AppDateUtils.formatLocalizedDate(
          arrangement.takenDate,
          l10n.locale.languageCode,
        ),
      ].join(' • '),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: semantic.cardSubtleBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: semantic.cardBorder),
          ),
          child: Row(
            children: [
              _statPair(
                l10n.takenAmountLabel,
                CurrencyUtils.formatPaise(arrangement.totalReturnablePaise),
                semantic.textPrimary,
                semantic,
              ),
              _statPair(
                l10n.returnedAmountLabel,
                CurrencyUtils.formatPaise(arrangement.returnedPaise),
                semantic.mila,
                semantic,
              ),
              _statPair(
                l10n.returnRemainingLabel,
                CurrencyUtils.formatPaise(arrangement.remainingPaise),
                arrangement.effectiveIsSettled ? semantic.mila : semantic.diya,
                semantic,
              ),
            ],
          ),
        ),
        if (arrangement.notes?.isNotEmpty ?? false) ...[
          const SizedBox(height: 10),
          Text(
            arrangement.notes!,
            style: ExpressType.bodySmall(color: semantic.textSecondary),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          l10n.returnHistoryLabel,
          style: ExpressType.titleSmall(color: semantic.textPrimary),
        ),
        const SizedBox(height: 8),
        if (arrangement.repayments.isEmpty)
          Text('-', style: ExpressType.bodySmall(color: semantic.textSecondary))
        else
          ...arrangement.repayments.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: semantic.cardSubtleBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: semantic.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      r.paymentMode == 'upi'
                          ? Icons.qr_code_2_rounded
                          : Icons.payments_outlined,
                      size: 16,
                      color: semantic.mila,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppDateUtils.formatLocalizedDate(
                              r.repaymentDate,
                              l10n.locale.languageCode,
                            ),
                            style: ExpressType.labelMedium(
                              color: semantic.textPrimary,
                            ),
                          ),
                          if (r.upiApp != null || (r.note?.isNotEmpty ?? false))
                            Text(
                              [
                                if (r.upiApp != null) r.upiApp!,
                                if (r.note?.isNotEmpty ?? false) r.note!,
                              ].join(' • '),
                              style: ExpressType.bodySmall(
                                color: semantic.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyUtils.formatPaise(r.amountPaise),
                      style: ExpressType.titleSmall(color: semantic.mila),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 14),
        Row(
          children: [
            if ((arrangement.lenderPhone?.isNotEmpty ?? false)) ...[
              ExpressIconButton(
                icon: Icons.call_outlined,
                onPressed: () =>
                    launchPhoneCall(ctx, arrangement.lenderPhone!),
              ),
              const SizedBox(width: 8),
            ],
            ExpressIconButton(
              icon: Icons.delete_outline_rounded,
              tint: semantic.diya,
              onPressed: () async {
                await ref
                    .read(budgetRepositoryProvider)
                    .deleteFundArrangement(arrangement.id);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ExpressButton(
                label: l10n.recordReturnBtn,
                icon: Icons.reply_rounded,
                expand: true,
                onPressed: arrangement.effectiveIsSettled
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        showRecordRepaymentSheet(
                          context: context,
                          ref: ref,
                          arrangement: arrangement,
                        );
                      },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Sheet 7: Quick 1-Tap Category Presets or Custom Category creation for an Event.
Future<void> showAddCategoryPresetsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<Event> events,
  String? preselectedEventId,
}) async {
  final l10n = context.l10n;
  final semantic = AppSemanticColors.of(context);
  if (events.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.createEventBeforeExpenseHint)),
    );
    return;
  }

  var selectedEventId = preselectedEventId ?? events.first.id;
  final lang = l10n.locale.languageCode;
  final selectedKeys = <String>{
    'catering',
    'tent',
    'jewelry_clothes',
    'photo',
  };
  final customNameCtrl = TextEditingController();
  final customBudgetCtrl = TextEditingController();
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: semantic.cardBg,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: phoneWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setSheetState) => _budgetModalShell(
        context: ctx,
        title: l10n.addCategoryPresetsBtn,
        children: [
          DropdownButtonFormField<String>(
            value: selectedEventId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.tabEvents),
            items: events
                .map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.title, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setSheetState(() => selectedEventId = v);
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BudgetCalculations.standardWeddingPresets.map((preset) {
              final chosen = selectedKeys.contains(preset.key);
              return FilterChip(
                label: Text(preset.labelForLanguage(lang)),
                selected: chosen,
                selectedColor: semantic.primary.withValues(alpha: 0.16),
                onSelected: (v) {
                  setSheetState(() {
                    if (v) {
                      selectedKeys.add(preset.key);
                    } else {
                      selectedKeys.remove(preset.key);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: customNameCtrl,
                  decoration: InputDecoration(labelText: l10n.addNewCategoryBtn),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: customBudgetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.plannedBudgetLabel,
                    prefixText: '₹ ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ExpressButton(
            label: l10n.save,
            expand: true,
            isLoading: saving,
            onPressed: () async {
              setSheetState(() => saving = true);
              final presetsToAdd = <({String name, int estimatedPaise})>[
                for (final p in BudgetCalculations.standardWeddingPresets)
                  if (selectedKeys.contains(p.key))
                    (name: p.labelForLanguage(lang), estimatedPaise: 0),
              ];
              final customName = customNameCtrl.text.trim();
              if (customName.isNotEmpty) {
                final customEst = CurrencyUtils.parseInputToPaise(
                      customBudgetCtrl.text.trim(),
                    ) ??
                    0;
                presetsToAdd.add((name: customName, estimatedPaise: customEst));
              }
              await ref.read(budgetRepositoryProvider).createCategoriesFromPresets(
                    eventId: selectedEventId,
                    presets: presetsToAdd,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );

  customNameCtrl.dispose();
  customBudgetCtrl.dispose();
}

Widget _statPair(
  String label,
  String value,
  Color valueColor,
  AppSemanticColors semantic,
) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ExpressType.labelSmall(color: semantic.textSecondary),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: ExpressType.titleSmall(color: valueColor, weight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}
