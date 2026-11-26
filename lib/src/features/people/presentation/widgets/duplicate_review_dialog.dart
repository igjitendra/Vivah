import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../domain/entities/entities.dart';

enum DuplicateResolutionChoice { skip, separate, merge }

/// Side-by-Side Duplicate Contact Review & Resolution Dialog
class DuplicateReviewDialog extends StatefulWidget {
  final Person existingPerson;
  final ContactDraft incomingDraft;
  final String matchedReason;

  const DuplicateReviewDialog({
    super.key,
    required this.existingPerson,
    required this.incomingDraft,
    required this.matchedReason,
  });

  @override
  State<DuplicateReviewDialog> createState() => _DuplicateReviewDialogState();
}

class _DuplicateReviewDialogState extends State<DuplicateReviewDialog> {
  // Field selection toggles for merge
  bool _useIncomingName = false;
  bool _useIncomingPhone = false;
  bool _useIncomingAddress = true;
  bool _useIncomingJob = true;
  final bool _useIncomingCompany = true;

  bool _isMergeMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.duplicateFoundTitle,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                      ),
                      Text(
                        '${l10n.duplicateFoundDesc} (${widget.matchedReason})',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Content Area: Side-by-side comparison or merge chooser
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _isMergeMode ? _buildMergeChooser(cardBorder, textPrimary, textSecondary, primaryAccent) : _buildSideBySideComparison(cardBorder, textPrimary, textSecondary),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Actions
            if (_isMergeMode)
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _isMergeMode = false),
                    child: Text(l10n.cancel),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'choice': DuplicateResolutionChoice.merge,
                        'keepIncomingField': {
                          'name': _useIncomingName,
                          'phone': _useIncomingPhone,
                          'address': _useIncomingAddress,
                          'job': _useIncomingJob,
                          'company': _useIncomingCompany,
                        },
                      });
                    },
                    child: Text(l10n.confirmMerge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context, {'choice': DuplicateResolutionChoice.skip}),
                          child: Text(l10n.skipImport, style: TextStyle(color: textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context, {'choice': DuplicateResolutionChoice.separate}),
                          child: Text(l10n.importAsSeparate, style: TextStyle(color: primaryAccent, fontSize: 12), textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.merge_type, color: Colors.white, size: 18),
                    label: Text(l10n.mergeWithExisting, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => setState(() => _isMergeMode = true),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBySideComparison(Color border, Color primary, Color secondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing Record
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'मौजूदा रिकॉर्ड (Existing)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.existingPerson.fullName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primary),
                ),
                if (widget.existingPerson.phoneNumber != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 12, color: secondary),
                      const SizedBox(width: 4),
                      Text(widget.existingPerson.phoneNumber!, style: TextStyle(fontSize: 12, color: secondary)),
                    ],
                  ),
                ],
                if (widget.existingPerson.emails.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 12, color: secondary),
                      const SizedBox(width: 4),
                      Text(widget.existingPerson.emails.first, style: TextStyle(fontSize: 12, color: secondary)),
                    ],
                  ),
                ],
                if (widget.existingPerson.address != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: secondary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(widget.existingPerson.address!, style: TextStyle(fontSize: 12, color: secondary))),
                    ],
                  ),
                ],
                if (widget.existingPerson.relationshipLabel != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.label_outlined, size: 12, color: secondary),
                      const SizedBox(width: 4),
                      Text(widget.existingPerson.relationshipLabel!, style: TextStyle(fontSize: 12, color: secondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Incoming Contact Draft
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.contacts, size: 14, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'नया संपर्क (Incoming)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.incomingDraft.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primary),
                ),
                if (widget.incomingDraft.phones.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 12, color: secondary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(widget.incomingDraft.phones.join(', '), style: TextStyle(fontSize: 12, color: secondary))),
                    ],
                  ),
                ],
                if (widget.incomingDraft.emails.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 12, color: secondary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(widget.incomingDraft.emails.join(', '), style: TextStyle(fontSize: 12, color: secondary))),
                    ],
                  ),
                ],
                if (widget.incomingDraft.address != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: secondary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(widget.incomingDraft.address!, style: TextStyle(fontSize: 12, color: secondary))),
                    ],
                  ),
                ],
                if (widget.incomingDraft.company != null || widget.incomingDraft.jobTitle != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.work_outline, size: 12, color: secondary),
                      const SizedBox(width: 4),
                      Expanded(child: Text([widget.incomingDraft.jobTitle, widget.incomingDraft.company].where((s) => s != null).join(' @ '), style: TextStyle(fontSize: 12, color: secondary))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMergeChooser(Color border, Color primary, Color secondary, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'विलय विकल्प चुनें (Select Fields to Update):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primary),
        ),
        const SizedBox(height: 4),
        Text(
          'नोट: सभी फ़ोन नंबर और ईमेल सुरक्षित रखे जाएँगे और पुराने व्यवहार रिकॉर्ड कभी नहीं बदलेंगे।',
          style: TextStyle(fontSize: 11.5, color: secondary),
        ),
        const SizedBox(height: 12),

        // Name Choice
        _buildMergeCheckboxRow(
          title: 'नाम (Name)',
          existingVal: widget.existingPerson.fullName,
          incomingVal: widget.incomingDraft.name,
          value: _useIncomingName,
          onChanged: (v) => setState(() => _useIncomingName = v ?? false),
          primary: primary,
          secondary: secondary,
        ),

        // Phone Choice
        if (widget.incomingDraft.primaryPhone != null && widget.incomingDraft.primaryPhone != widget.existingPerson.phoneNumber)
          _buildMergeCheckboxRow(
            title: 'प्राथमिक फ़ोन (Primary Phone)',
            existingVal: widget.existingPerson.phoneNumber ?? '—',
            incomingVal: widget.incomingDraft.primaryPhone!,
            value: _useIncomingPhone,
            onChanged: (v) => setState(() => _useIncomingPhone = v ?? false),
            primary: primary,
            secondary: secondary,
          ),

        // Address Choice
        if (widget.incomingDraft.address != null && widget.incomingDraft.address != widget.existingPerson.address)
          _buildMergeCheckboxRow(
            title: 'पता / गाँव (Address)',
            existingVal: widget.existingPerson.address ?? '—',
            incomingVal: widget.incomingDraft.address!,
            value: _useIncomingAddress,
            onChanged: (v) => setState(() => _useIncomingAddress = v ?? false),
            primary: primary,
            secondary: secondary,
          ),

        // Company / Job Choice
        if (widget.incomingDraft.company != null || widget.incomingDraft.jobTitle != null)
          _buildMergeCheckboxRow(
            title: 'व्यवसाय / कंपनी (Job / Company)',
            existingVal: [widget.existingPerson.occupation, widget.existingPerson.company].where((s) => s != null && s.isNotEmpty).join(' @ ').ifEmpty('—'),
            incomingVal: [widget.incomingDraft.jobTitle, widget.incomingDraft.company].where((s) => s != null && s.isNotEmpty).join(' @ '),
            value: _useIncomingJob,
            onChanged: (v) => setState(() => _useIncomingJob = v ?? false),
            primary: primary,
            secondary: secondary,
          ),
      ],
    );
  }

  Widget _buildMergeCheckboxRow({
    required String title,
    required String existingVal,
    required String incomingVal,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Color primary,
    required Color secondary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primary)),
            Row(
              children: [
                Expanded(
                  child: Text('मौजूदा: $existingVal', style: TextStyle(fontSize: 11.5, color: secondary)),
                ),
                Checkbox(value: value, onChanged: onChanged),
                Text('नया उपयोग करें', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension _StringEmptyExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
