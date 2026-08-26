// ==============================================================================
// USER PROFILE MODEL — MyHarur product-specific profile
// Identity (UID, email, global roles) comes from QenBel Supabase
// Product data (mmid, ward, occupation, onboarding) lives in MyHarur Supabase
// ==============================================================================
class UserProfile {
  // Identity (from QenBel Supabase JWT)
  final String id;           // Supabase auth.users.id (same UID across both DBs)
  final String? qenbelUid;   // Explicit QenBel UID reference

  // MyHarur product fields (from MyHarur profiles table)
  final String mmid;
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final bool phoneVerified;
  final String? avatarUrl;
  final int? wardId;
  final String wardLocality;  // denormalized display name
  final bool wardVerified;
  final String onboardingState; // PENDING_USERNAME | PENDING_PROFILE | PENDING_OCCUPATION | PENDING_SOURCE | COMPLETE
  final String? occupation;
  final String bloodGroup;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String bio;
  final int emergencyStrikes;
  final bool isActive;

  // Roles (from MyHarur user_roles join table)
  final List<String> roles; // ['resident'] | ['resident','govt_official'] etc.

  const UserProfile({
    required this.id,
    this.qenbelUid,
    required this.mmid,
    required this.username,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.phoneVerified = false,
    this.avatarUrl,
    this.wardId,
    this.wardLocality = 'Harur Town',
    this.wardVerified = false,
    this.onboardingState = 'PENDING_USERNAME',
    this.occupation,
    this.bloodGroup = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.bio = '',
    this.emergencyStrikes = 0,
    this.isActive = true,
    this.roles = const ['resident'],
  });

  // ── Role helpers ─────────────────────────────────────────────────────────────
  bool get isSuperAdmin => roles.contains('superadmin');
  bool get isAdmin => roles.contains('admin') || isSuperAdmin;
  bool get isGovtOfficial => roles.contains('govt_official');
  bool get isResident => roles.contains('resident');

  /// Can directly publish to official categories
  bool get canDirectPublish => isAdmin || isSuperAdmin;

  /// Can bypass moderation queue for govt category
  bool get canPublishGovt => isGovtOfficial || isAdmin || isSuperAdmin;

  /// Lost emergency-tag privilege after 2 strikes
  bool get hasEmergencyPrivilege => emergencyStrikes < 2;

  /// Onboarding is fully complete
  bool get isOnboardingComplete => onboardingState == 'COMPLETE';

  String get primaryRole {
    if (isSuperAdmin) return 'SuperAdmin';
    if (isAdmin) return 'Admin';
    if (isGovtOfficial) return 'Govt Official';
    return 'Resident';
  }

  // ── Guest sentinel ───────────────────────────────────────────────────────────
  static const guest = UserProfile(
    id: 'guest',
    mmid: 'GUEST',
    username: 'guest',
    fullName: 'Harur Resident',
    email: '',
    roles: ['resident'],
    onboardingState: 'PENDING_USERNAME',
  );

  bool get isGuest => id == 'guest';

  // ── Factory ──────────────────────────────────────────────────────────────────
  factory UserProfile.fromJson(Map<String, dynamic> json, {List<String>? roles}) {
    return UserProfile(
      id: json['id'] as String? ?? 'guest',
      qenbelUid: json['qenbel_uid'] as String?,
      mmid: json['mmid'] as String? ?? 'MMID-UNKNOWN',
      username: json['username'] as String? ?? 'resident',
      fullName: json['full_name'] as String? ?? 'Harur Resident',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      phoneVerified: json['phone_verified'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      wardId: json['ward_id'] as int?,
      wardLocality: json['ward_locality'] as String? ?? 'Harur Town',
      wardVerified: json['ward_verified'] as bool? ?? false,
      onboardingState: json['onboarding_state'] as String? ?? 'PENDING_USERNAME',
      occupation: json['occupation'] as String?,
      bloodGroup: json['blood_group'] as String? ?? '',
      emergencyContactName: json['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone: json['emergency_contact_phone'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      emergencyStrikes: json['emergency_strikes'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      roles: roles ?? const ['resident'],
    );
  }

  UserProfile copyWith({
    String? username,
    String? fullName,
    String? phone,
    bool? phoneVerified,
    String? avatarUrl,
    int? wardId,
    String? wardLocality,
    bool? wardVerified,
    String? onboardingState,
    String? occupation,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bio,
    int? emergencyStrikes,
    bool? isActive,
    List<String>? roles,
  }) {
    return UserProfile(
      id: id,
      qenbelUid: qenbelUid,
      mmid: mmid,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      wardId: wardId ?? this.wardId,
      wardLocality: wardLocality ?? this.wardLocality,
      wardVerified: wardVerified ?? this.wardVerified,
      onboardingState: onboardingState ?? this.onboardingState,
      occupation: occupation ?? this.occupation,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bio: bio ?? this.bio,
      emergencyStrikes: emergencyStrikes ?? this.emergencyStrikes,
      isActive: isActive ?? this.isActive,
      roles: roles ?? this.roles,
    );
  }
}
