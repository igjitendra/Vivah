import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/profile_qr_service.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../domain/entities/entities.dart';
import '../../features/people/services/contacts_service.dart';
import 'vyavahaar_qr_share_sheet.dart';

/// Unified offline share helpers for [FamilyProfile] and Relative ([Person]) cards.
class ProfileShareActions {
  ProfileShareActions._();

  /// Shows offline QR card, formatted text share, and clipboard copy options for [FamilyProfile].
  static Future<void> showFamilyProfileShareSheet(
    BuildContext context,
    FamilyProfile profile,
  ) async {
    final l10n = context.l10n;
    final formattedText = ProfileQrService.formatFamilyProfileText(profile, l10n);
    final qrData = ProfileQrService.encodeFamilyProfile(profile);
    final cardTitle = profile.familyName.trim().isNotEmpty
        ? profile.familyName.trim()
        : (profile.headOfFamily.trim().isNotEmpty ? profile.headOfFamily.trim() : l10n.myFamily);

    final heroSubs = <String>[
      if (profile.headOfFamily.trim().isNotEmpty) '${l10n.mukhiyaBadge}: ${profile.headOfFamily.trim()}',
      if (profile.nativePlace.trim().isNotEmpty) profile.nativePlace.trim(),
    ];
    final bodyParts = <String>[
      if (profile.gotra.trim().isNotEmpty) '${l10n.gotra}: ${profile.gotra.trim()}',
      if (profile.primaryPhone.trim().isNotEmpty) profile.primaryPhone.trim(),
    ];
    final footerMembers = profile.members.isNotEmpty
        ? '${l10n.familyMembers} (${profile.members.length}): ${profile.members.map((m) => m.name).take(4).join(' • ')}'
        : null;

    await VyavahaarQrShareSheet.show(
      context,
      sheetTitle: l10n.familyQrTitle,
      badgeLabel: l10n.familyProfile,
      cardTitle: cardTitle,
      heroSubtitles: heroSubs,
      qrData: qrData,
      bodyDetail: bodyParts.isNotEmpty ? bodyParts.join(' • ') : null,
      footerSummary: footerMembers,
      shareCaption: formattedText,
      fileNamePrefix: 'vyavahaar_family_qr',
      hintText: l10n.qrShareProfileHint,
      secondaryActionLabel: l10n.shareTextCardLabel,
      secondaryActionIcon: Icons.text_snippet_outlined,
      onSecondaryAction: () async {
        await Clipboard.setData(ClipboardData(text: formattedText));
        await Share.share(formattedText, subject: cardTitle);
      },
    );
  }

  /// Shows action sheet to share a Relative ([Person]) as QR Card PNG, Formatted Text, or `.vcf` vCard.
  static Future<void> showRelativeShareSheet(
    BuildContext context,
    Person person,
  ) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: semantic.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: semantic.primary.withValues(alpha: 0.14),
                    child: Text(
                      person.initials,
                      style: TextStyle(color: semantic.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.shareRelativeTitle,
                          style: TextStyle(fontSize: 12, color: semantic.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          person.displayName,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: semantic.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: semantic.primary.withValues(alpha: 0.14),
                  child: Icon(Icons.qr_code_2_rounded, color: semantic.primary),
                ),
                title: Text(l10n.relativeQrTitle, style: TextStyle(fontWeight: FontWeight.w700, color: semantic.textPrimary)),
                subtitle: Text(
                  l10n.tr('Scannable offline QR card', 'स्कैन करने योग्य ऑफ़लाइन QR कार्ड', 'اسکین کرنے والا آف لائن QR کارڈ'),
                  style: TextStyle(fontSize: 12, color: semantic.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showRelativeQrCard(context, person);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: semantic.infoContainer,
                  child: Icon(Icons.share_outlined, color: semantic.info),
                ),
                title: Text(l10n.shareContactAction, style: TextStyle(fontWeight: FontWeight.w700, color: semantic.textPrimary)),
                subtitle: Text(
                  l10n.tr('WhatsApp / Text message summary', 'व्हाट्सएप / टेक्स्ट विवरण भेजें', 'واٹس ایپ / ٹیکسٹ تفصیل بھیجیں'),
                  style: TextStyle(fontSize: 12, color: semantic.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ContactsService.sharePersonCard(person);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: semantic.milaContainer,
                  child: Icon(Icons.contact_page_outlined, color: semantic.mila),
                ),
                title: Text(l10n.exportVCardAction, style: TextStyle(fontWeight: FontWeight.w700, color: semantic.textPrimary)),
                subtitle: Text(
                  l10n.tr('Phonebook compatible .vcf contact file', 'फ़ोन कॉन्टैक्ट्स में सेव करने योग्य .vcf फ़ाइल', '.vcf رابطہ فائل'),
                  style: TextStyle(fontSize: 12, color: semantic.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ContactsService.exportAndShareVCard([person]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays the offline scannable QR card directly for a Relative ([Person]).
  static Future<void> showRelativeQrCard(BuildContext context, Person person) async {
    final l10n = context.l10n;
    final qrData = ProfileQrService.encodePerson(person);
    final heroSubs = <String>[
      if (person.relationshipLabel != null && person.relationshipLabel!.trim().isNotEmpty)
        person.relationshipLabel!.trim(),
      if (person.fullAddress.isNotEmpty) person.fullAddress,
    ];
    final phoneStr = person.allPhoneNumbers.join(' • ');
    final badge = person.relationshipLabel != null && person.relationshipLabel!.trim().isNotEmpty
        ? person.relationshipLabel!.trim()
        : l10n.relativeDefault;

    await VyavahaarQrShareSheet.show(
      context,
      sheetTitle: l10n.relativeQrTitle,
      badgeLabel: badge,
      cardTitle: person.displayName,
      heroSubtitles: heroSubs,
      qrData: qrData,
      bodyDetail: phoneStr.isNotEmpty ? phoneStr : null,
      footerSummary: person.occupation?.trim().isNotEmpty == true ? person.occupation!.trim() : null,
      shareCaption: '${person.displayName}${phoneStr.isNotEmpty ? "\n$phoneStr" : ""}',
      fileNamePrefix: 'vyavahaar_relative_qr',
      hintText: l10n.qrShareProfileHint,
      secondaryActionLabel: l10n.shareTextCardLabel,
      secondaryActionIcon: Icons.share_outlined,
      onSecondaryAction: () => ContactsService.sharePersonCard(person),
    );
  }
}
