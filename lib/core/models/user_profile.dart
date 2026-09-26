import 'place.dart';

// ==============================================================================
// USER PROFILE MODEL — MyHarur product-specific profile
// Product data (mmid, address, occupation, onboarding) lives in the MyHarur Supabase project.
// ==============================================================================
class UserProfile {
  final String id; // Supabase auth.users.id
  final String? qenbelUid;

  final String mmid;
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final bool phoneVerified;
  final String? avatarUrl;
  final String onboardingState; // PENDING_USERNAME | PENDING_PROFILE | PENDING_OCCUPATION | PENDING_SOURCE | COMPLETE
  final String? occupation;
  final String bloodGroup;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String bio;
  final int emergencyStrikes;
  final bool isActive;

  /// Set after a super admin recovered the account: the person must choose a new password first.
  final bool mustChangePassword;

  /// Optional home address (typed and/or pinned on the map). Null for everyone until they set it.
  final PickedLocation? address;

  final List<String> roles; // ['resident'] | ['resident','moderator'] etc.

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
    this.onboardingState = 'PENDING_USERNAME',
    this.occupation,
    this.bloodGroup = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.bio = '',
    this.emergencyStrikes = 0,
    this.isActive = true,
    this.mustChangePassword = false,
    this.address,
    this.roles = const ['resident'],
  });

  // ── Role helpers ─────────────────────────────────────────────────────────────
  bool get isSuperAdmin => roles.contains('superadmin');
  bool get isAdmin => roles.contains('admin') || isSuperAdmin;
  bool get isModerator => roles.contains('moderator');
  bool get isGovtOfficial => roles.contains('govt_official');
  bool get isResident => roles.contains('resident');

  /// Can review (approve / reject) pending alerts. Mirrors is_staff() in the DB,
  /// which is the real gate — this only decides whether to show the Review tab.
  bool get isStaff => isModerator || isAdmin;

  /// Admins and super admins must use an authenticator app (enforced in the database too).
  bool get requiresMfa => isAdmin;

  /// Lost emergency-tag privilege after 2 strikes
  bool get hasEmergencyPrivilege => emergencyStrikes < 2;

  bool get isOnboardingComplete => onboardingState == 'COMPLETE';

  String get primaryRole {
    if (isSuperAdmin) return 'SuperAdmin';
    if (isAdmin) return 'Admin';
    if (isModerator) return 'Moderator';
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
      onboardingState: json['onboarding_state'] as String? ?? 'PENDING_USERNAME',
      occupation: json['occupation'] as String?,
      bloodGroup: json['blood_group'] as String? ?? '',
      emergencyContactName: json['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone: json['emergency_contact_phone'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      emergencyStrikes: json['emergency_strikes'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
      address: PickedLocation.fromColumns(
        text: json['address_text'] as String?,
        lat: (json['address_lat'] as num?)?.toDouble(),
        lng: (json['address_lng'] as num?)?.toDouble(),
        source: json['address_source'] as String?,
      ),
      roles: roles ?? const ['resident'],
    );
  }

  UserProfile copyWith({
    String? username,
    String? fullName,
    String? phone,
    bool? phoneVerified,
    String? avatarUrl,
    String? onboardingState,
    String? occupation,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bio,
    int? emergencyStrikes,
    bool? isActive,
    bool? mustChangePassword,
    PickedLocation? address,
    bool clearAddress = false,
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
      onboardingState: onboardingState ?? this.onboardingState,
      occupation: occupation ?? this.occupation,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bio: bio ?? this.bio,
      emergencyStrikes: emergencyStrikes ?? this.emergencyStrikes,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      address: clearAddress ? null : (address ?? this.address),
      roles: roles ?? this.roles,
    );
  }
}
