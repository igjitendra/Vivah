import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/family_profile.dart';
import '../../../app/app_providers.dart';
import 'widgets/add_edit_member_dialog.dart';

/// Screen displaying the complete Profile of the user's own family (हमारा परिवार)
class FamilyProfileScreen extends ConsumerWidget {
  const FamilyProfileScreen({super.key});

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isNotEmpty) {
      final uri = Uri.parse('tel:$clean');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isNotEmpty) {
      final uri = Uri.parse('https://wa.me/$clean');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showDeleteMemberDialog(
    BuildContext context,
    AppLocalizations l10n,
    FamilyMember member,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteFamilyMember),
        content: Text(l10n.deleteFamilyMemberConfirm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(familyProfileRepositoryProvider);
              await repo.deleteMember(member.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.memberDeleted),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final profileAsync = ref.watch(familyProfileProvider);

    final bg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          l10n.myFamily,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.terracotta,
            tooltip: l10n.editProfile,
            onPressed: () => context.push('/family-profile/edit'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: Text(
          l10n.addFamilyMember,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          AddEditMemberDialog.show(
            context,
            onSave: (member) async {
              final repo = ref.read(familyProfileRepositoryProvider);
              await repo.addMember(member);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.memberAdded),
                    backgroundColor: AppColors.milaGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          );
        },
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.terracotta),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (famProfile) {
          if (famProfile.isEmpty) {
            return _EmptyFamilyProfileView(
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              l10n: l10n,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 90),
            children: [
              // 1. Hero Family Card
              _FamilyHeroCard(
                profile: famProfile,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                l10n: l10n,
                onEdit: () => context.push('/family-profile/edit'),
              ),
              const SizedBox(height: 18),

              // 2. Family Roots & Contact Card
              _FamilyDetailsCard(
                profile: famProfile,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                l10n: l10n,
                onCall: _makeCall,
                onWhatsApp: _openWhatsApp,
              ),
              const SizedBox(height: 24),

              // 3. Family Members Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.familyMembers,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${famProfile.members.length}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.terracotta,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      l10n.addFamilyMember,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    onPressed: () {
                      AddEditMemberDialog.show(
                        context,
                        onSave: (member) async {
                          final repo = ref.read(familyProfileRepositoryProvider);
                          await repo.addMember(member);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.memberAdded),
                                backgroundColor: AppColors.milaGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Members List
              if (famProfile.members.isEmpty)
                _NoMembersCard(
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textSecondary: textSecondary,
                  l10n: l10n,
                  onAdd: () {
                    AddEditMemberDialog.show(
                      context,
                      onSave: (member) async {
                        final repo = ref.read(familyProfileRepositoryProvider);
                        await repo.addMember(member);
                      },
                    );
                  },
                )
              else
                ...famProfile.members.map(
                  (member) => _FamilyMemberCard(
                    member: member,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    l10n: l10n,
                    onCall: () {
                      if (member.phone != null) _makeCall(member.phone!);
                    },
                    onWhatsApp: () {
                      if (member.phone != null) _openWhatsApp(member.phone!);
                    },
                    onEdit: () {
                      AddEditMemberDialog.show(
                        context,
                        existingMember: member,
                        onSave: (updated) async {
                          final repo = ref.read(familyProfileRepositoryProvider);
                          await repo.updateMember(updated);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.memberUpdated),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    },
                    onDelete: () => _showDeleteMemberDialog(context, l10n, member, ref),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FamilyHeroCard extends StatelessWidget {
  final FamilyProfile profile;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final AppLocalizations l10n;
  final VoidCallback onEdit;

  const _FamilyHeroCard({
    required this.profile,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.l10n,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile.photoPath.isNotEmpty && File(profile.photoPath).existsSync();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo Avatar
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.terracotta.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  image: hasPhoto
                      ? DecorationImage(
                          image: FileImage(File(profile.photoPath)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasPhoto
                    ? const Icon(
                        Icons.family_restroom,
                        size: 34,
                        color: AppColors.terracotta,
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Family Title & Head
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.familyName.isNotEmpty ? profile.familyName : l10n.myFamily,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (profile.headOfFamily.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.terracotta.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.mukhiyaBadge,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.terracotta,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              profile.headOfFamily,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (profile.nativePlace.isNotEmpty || profile.currentCity.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                if (profile.nativePlace.isNotEmpty) profile.nativePlace,
                                if (profile.currentCity.isNotEmpty) profile.currentCity,
                              ].join(' • '),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Heritage Badges (Gotra & Kuldevi)
          if (profile.gotra.isNotEmpty || profile.kuldevi.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                if (profile.gotra.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.gotra,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.gotra,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (profile.gotra.isNotEmpty && profile.kuldevi.isNotEmpty)
                  const SizedBox(width: 10),
                if (profile.kuldevi.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEAB308).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.kuldevi,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFCA8A04),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.kuldevi,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FamilyDetailsCard extends StatelessWidget {
  final FamilyProfile profile;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final AppLocalizations l10n;
  final Function(String) onCall;
  final Function(String) onWhatsApp;

  const _FamilyDetailsCard({
    required this.profile,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.l10n,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Primary Contact Phone
          if (profile.primaryPhone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.milaGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone, size: 18, color: AppColors.milaGreen),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.primaryPhone,
                          style: TextStyle(fontSize: 11.5, color: textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.primaryPhone,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, size: 20),
                    color: AppColors.milaGreen,
                    onPressed: () => onCall(profile.primaryPhone),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat, size: 20),
                    color: const Color(0xFF25D366),
                    onPressed: () => onWhatsApp(profile.primaryPhone),
                  ),
                ],
              ),
            ),

          if (profile.alternatePhone.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_android, size: 18, color: Color(0xFF0EA5E9)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.alternatePhone,
                          style: TextStyle(fontSize: 11.5, color: textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.alternatePhone,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, size: 20),
                    color: const Color(0xFF0EA5E9),
                    onPressed: () => onCall(profile.alternatePhone),
                  ),
                ],
              ),
            ),
          ],

          if (profile.email.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.familyEmail,
                          style: TextStyle(fontSize: 11.5, color: textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.email,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (profile.address.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.home_outlined, size: 18, color: AppColors.terracotta),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.fullAddress,
                          style: TextStyle(fontSize: 11.5, color: textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.address,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textPrimary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (profile.about.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_outlined, size: 18, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.familyBio,
                          style: TextStyle(fontSize: 11.5, color: textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.about,
                          style: TextStyle(fontSize: 13, color: textPrimary, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final AppLocalizations l10n;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FamilyMemberCard({
    required this.member,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.l10n,
    required this.onCall,
    required this.onWhatsApp,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getRelationColor(String rel) {
    final lower = rel.toLowerCase();
    if (lower.contains('mukhiya') || lower.contains('self')) return AppColors.terracotta;
    if (lower.contains('spouse') || lower.contains('wife') || lower.contains('husband')) {
      return const Color(0xFF8B5CF6);
    }
    if (lower.contains('son') || lower.contains('daughter')) return AppColors.milaGreen;
    if (lower.contains('father') || lower.contains('mother')) return const Color(0xFFD97706);
    return const Color(0xFF0284C7);
  }

  @override
  Widget build(BuildContext context) {
    final relColor = _getRelationColor(member.relationship);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Initial Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: relColor.withValues(alpha: 0.14),
                child: Text(
                  member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: relColor,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Relation badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: relColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member.relationship,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: relColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.editProfile),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Details row (Chips)
          if (member.dateOfBirth != null ||
              member.occupation != null ||
              member.bloodGroup != null ||
              member.gender != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (member.gender != null && member.gender!.isNotEmpty)
                  _MemberChip(
                    icon: Icons.person_outline,
                    label: member.gender!,
                    textSecondary: textSecondary,
                  ),
                if (member.dateOfBirth != null && member.dateOfBirth!.isNotEmpty)
                  _MemberChip(
                    icon: Icons.cake_outlined,
                    label: member.dateOfBirth!,
                    textSecondary: textSecondary,
                  ),
                if (member.occupation != null && member.occupation!.isNotEmpty)
                  _MemberChip(
                    icon: Icons.work_outline,
                    label: member.occupation!,
                    textSecondary: textSecondary,
                  ),
                if (member.bloodGroup != null && member.bloodGroup!.isNotEmpty)
                  _MemberChip(
                    icon: Icons.bloodtype_outlined,
                    label: member.bloodGroup!,
                    textSecondary: textSecondary,
                    tint: Colors.red.shade400,
                  ),
              ],
            ),
          ],

          // Phone & Communication Row
          if (member.phone != null && member.phone!.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 15, color: textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    member.phone!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onCall,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.milaGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call, size: 14, color: AppColors.milaGreen),
                        const SizedBox(width: 4),
                        Text(
                          l10n.callMember,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.milaGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onWhatsApp,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat, size: 14, color: Color(0xFF25D366)),
                        const SizedBox(width: 4),
                        Text(
                          l10n.whatsappMember,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF25D366),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (member.notes != null && member.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              member.notes!,
              style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textSecondary;
  final Color? tint;

  const _MemberChip({
    required this.icon,
    required this.label,
    required this.textSecondary,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = tint ?? textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMembersCard extends StatelessWidget {
  final Color cardBg;
  final Color borderColor;
  final Color textSecondary;
  final AppLocalizations l10n;
  final VoidCallback onAdd;

  const _NoMembersCard({
    required this.cardBg,
    required this.borderColor,
    required this.textSecondary,
    required this.l10n,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.group_outlined, size: 40, color: textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Text(
            l10n.noMembersYet,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.terracotta,
              side: const BorderSide(color: AppColors.terracotta),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addFirstMember),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _EmptyFamilyProfileView extends StatelessWidget {
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final AppLocalizations l10n;

  const _EmptyFamilyProfileView({
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.family_restroom,
                  size: 38,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.setupFamilyProfile,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.setupFamilyProfileSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add),
                label: Text(
                  l10n.setupFamilyProfile,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                onPressed: () => context.push('/family-profile/edit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
