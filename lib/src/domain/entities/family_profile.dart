import 'dart:convert';

/// A single member belonging to the user's family
class FamilyMember {
  final String id;
  final String name;
  final String relationship; // e.g. 'Self / Mukhiya', 'Spouse', 'Son', 'Daughter', 'Father', 'Mother'
  final String? phone;
  final String? dateOfBirth; // or age
  final String? gender; // 'Male', 'Female', 'Other'
  final String? occupation;
  final String? bloodGroup;
  final String? notes;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.occupation,
    this.bloodGroup,
    this.notes,
  });

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relationship,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? occupation,
    String? bloodGroup,
    String? notes,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'occupation': occupation,
        'blood_group': bloodGroup,
        'notes': notes,
      };

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? '',
        relationship: json['relationship'] as String? ?? '',
        phone: json['phone'] as String?,
        dateOfBirth: json['date_of_birth'] as String?,
        gender: json['gender'] as String?,
        occupation: json['occupation'] as String?,
        bloodGroup: json['blood_group'] as String?,
        notes: json['notes'] as String?,
      );
}

/// Profile of the user's own family (हमारा परिवार / मुख्य पारिवारिक प्रोफ़ाइल)
class FamilyProfile {
  final String familyName; // e.g. "शर्मा परिवार"
  final String headOfFamily; // e.g. "श्री रमेश चंद्र शर्मा"
  final String nativePlace; // पैतृक गाँव / स्थान e.g. "सीकर, राजस्थान"
  final String currentCity; // वर्तमान शहर e.g. "जयपुर, राजस्थान"
  final String address; // पूरा पता
  final String gotra; // गोत्र e.g. "कौशिक"
  final String kuldevi; // कुलदेवी / कुलदेवता e.g. "मां शाकम्भरी"
  final String primaryPhone; // मुख्य संपर्क नंबर
  final String alternatePhone; // अन्य संपर्क नंबर
  final String email; // पारिवारिक ईमेल
  final String photoPath; // परिवार की तस्वीर / फ़ोटो
  final String about; // पारिवारिक परिचय / विवरण
  final List<FamilyMember> members;

  const FamilyProfile({
    this.familyName = '',
    this.headOfFamily = '',
    this.nativePlace = '',
    this.currentCity = '',
    this.address = '',
    this.gotra = '',
    this.kuldevi = '',
    this.primaryPhone = '',
    this.alternatePhone = '',
    this.email = '',
    this.photoPath = '',
    this.about = '',
    this.members = const [],
  });

  bool get isEmpty =>
      familyName.trim().isEmpty &&
      headOfFamily.trim().isEmpty &&
      nativePlace.trim().isEmpty &&
      members.isEmpty;

  bool get isNotEmpty => !isEmpty;

  FamilyProfile copyWith({
    String? familyName,
    String? headOfFamily,
    String? nativePlace,
    String? currentCity,
    String? address,
    String? gotra,
    String? kuldevi,
    String? primaryPhone,
    String? alternatePhone,
    String? email,
    String? photoPath,
    String? about,
    List<FamilyMember>? members,
  }) {
    return FamilyProfile(
      familyName: familyName ?? this.familyName,
      headOfFamily: headOfFamily ?? this.headOfFamily,
      nativePlace: nativePlace ?? this.nativePlace,
      currentCity: currentCity ?? this.currentCity,
      address: address ?? this.address,
      gotra: gotra ?? this.gotra,
      kuldevi: kuldevi ?? this.kuldevi,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      about: about ?? this.about,
      members: members ?? this.members,
    );
  }

  Map<String, dynamic> toJson() => {
        'family_name': familyName,
        'head_of_family': headOfFamily,
        'native_place': nativePlace,
        'current_city': currentCity,
        'address': address,
        'gotra': gotra,
        'kuldevi': kuldevi,
        'primary_phone': primaryPhone,
        'alternate_phone': alternatePhone,
        'email': email,
        'photo_path': photoPath,
        'about': about,
        'members': members.map((m) => m.toJson()).toList(),
      };

  factory FamilyProfile.fromJson(Map<String, dynamic> json) => FamilyProfile(
        familyName: json['family_name'] as String? ?? '',
        headOfFamily: json['head_of_family'] as String? ?? '',
        nativePlace: json['native_place'] as String? ?? '',
        currentCity: json['current_city'] as String? ?? '',
        address: json['address'] as String? ?? '',
        gotra: json['gotra'] as String? ?? '',
        kuldevi: json['kuldevi'] as String? ?? '',
        primaryPhone: json['primary_phone'] as String? ?? '',
        alternatePhone: json['alternate_phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        photoPath: json['photo_path'] as String? ?? '',
        about: json['about'] as String? ?? '',
        members: (json['members'] as List<dynamic>?)
                ?.map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  factory FamilyProfile.fromJsonString(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return FamilyProfile.fromJson(decoded);
      }
    } catch (_) {}
    return const FamilyProfile();
  }

  String toJsonString() => jsonEncode(toJson());
}
