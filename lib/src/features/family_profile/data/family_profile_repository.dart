import 'dart:convert';
import '../../../data/repositories/settings_repository.dart';
import '../../../domain/entities/family_profile.dart';

abstract class FamilyProfileRepository {
  Future<FamilyProfile> getFamilyProfile();
  Stream<FamilyProfile> watchFamilyProfile();
  Future<void> saveFamilyProfile(FamilyProfile profile);
  Future<void> addMember(FamilyMember member);
  Future<void> updateMember(FamilyMember member);
  Future<void> deleteMember(String memberId);
}

class DriftFamilyProfileRepository implements FamilyProfileRepository {
  static const String _settingKey = 'family_profile_data';
  final SettingsRepository _settingsRepository;

  DriftFamilyProfileRepository(this._settingsRepository);

  @override
  Future<FamilyProfile> getFamilyProfile() async {
    final raw = await _settingsRepository.getSetting(_settingKey);
    if (raw == null || raw.trim().isEmpty) {
      return const FamilyProfile();
    }
    return FamilyProfile.fromJsonString(raw);
  }

  @override
  Stream<FamilyProfile> watchFamilyProfile() {
    return _settingsRepository.watchSetting(_settingKey).map((raw) {
      if (raw == null || raw.trim().isEmpty) {
        return const FamilyProfile();
      }
      return FamilyProfile.fromJsonString(raw);
    });
  }

  @override
  Future<void> saveFamilyProfile(FamilyProfile profile) async {
    final raw = profile.toJsonString();
    await _settingsRepository.setSetting(_settingKey, raw);
  }

  @override
  Future<void> addMember(FamilyMember member) async {
    final current = await getFamilyProfile();
    final updatedMembers = List<FamilyMember>.from(current.members)..add(member);
    await saveFamilyProfile(current.copyWith(members: updatedMembers));
  }

  @override
  Future<void> updateMember(FamilyMember member) async {
    final current = await getFamilyProfile();
    final updatedMembers = current.members.map((m) {
      return m.id == member.id ? member : m;
    }).toList();
    await saveFamilyProfile(current.copyWith(members: updatedMembers));
  }

  @override
  Future<void> deleteMember(String memberId) async {
    final current = await getFamilyProfile();
    final updatedMembers = current.members.where((m) => m.id != memberId).toList();
    await saveFamilyProfile(current.copyWith(members: updatedMembers));
  }
}
