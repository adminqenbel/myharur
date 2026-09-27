import 'place.dart';

// ==============================================================================
// ALERT MODEL — a community or official report
// ==============================================================================
class Alert {
  final String id;
  final String kind; // report | news
  final String category; // report: road | electricity | water | govt; news: traffic | civic | health | education | community | other
  final String title;
  final String body;
  final String source; // official | community
  final String status; // published | pending | rejected | expired
  final String? publishedAsRole;
  final String? createdByUid;
  final DateTime? expiresAt;
  final bool emergencyTagged;
  final DateTime createdAt;

  /// Optional https link (news/event registration/job apply link) and up to three private photos
  /// (paths in the content-images bucket).
  final String? linkUrl;
  final List<String> imagePaths;

  /// Events: when it starts, and optionally ends; whether it runs all day; ticketed vs free.
  final DateTime? startsAt;
  final DateTime? endsAt; // events: optional end; jobs: closing date/time
  final bool allDay;
  final bool isPaid;

  /// Jobs.
  final String? employer;
  final String? payText;
  final String? contactText;

  /// Where it happened: a pinned point and/or typed text. Optional.
  final PickedLocation? location;

  // Automated filter output (visible to the author and to staff only)
  final List<String> moderationFlags; // profanity | dangerous_terms | link | phone_number
  final bool flaggedBySystem;
  final String? moderationReason;

  const Alert({
    required this.id,
    this.kind = 'report',
    required this.category,
    required this.title,
    required this.body,
    required this.source,
    required this.status,
    this.publishedAsRole,
    this.createdByUid,
    this.expiresAt,
    this.emergencyTagged = false,
    required this.createdAt,
    this.linkUrl,
    this.imagePaths = const [],
    this.startsAt,
    this.endsAt,
    this.allDay = false,
    this.isPaid = false,
    this.employer,
    this.payText,
    this.contactText,
    this.location,
    this.moderationFlags = const [],
    this.flaggedBySystem = false,
    this.moderationReason,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? 'report',
      category: json['category'] as String? ?? 'govt',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      source: json['source'] as String? ?? 'community',
      status: json['status'] as String? ?? 'pending',
      publishedAsRole: json['published_as_role'] as String?,
      createdByUid: json['created_by_uid'] as String?,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
      emergencyTagged: json['emergency_tagged'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      linkUrl: json['link_url'] as String?,
      imagePaths: (json['image_paths'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      startsAt: json['starts_at'] != null ? DateTime.tryParse(json['starts_at'] as String) : null,
      endsAt: json['ends_at'] != null ? DateTime.tryParse(json['ends_at'] as String) : null,
      allDay: json['all_day'] as bool? ?? false,
      isPaid: json['is_paid'] as bool? ?? false,
      employer: json['employer'] as String?,
      payText: json['pay_text'] as String?,
      contactText: json['contact_text'] as String?,
      location: PickedLocation.fromColumns(
        text: json['location_text'] as String?,
        lat: (json['location_lat'] as num?)?.toDouble(),
        lng: (json['location_lng'] as num?)?.toDouble(),
        source: json['location_source'] as String?,
      ),
      moderationFlags: (json['moderation_flags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      flaggedBySystem: json['flagged_by_system'] as bool? ?? false,
      moderationReason: json['moderation_reason'] as String?,
    );
  }

  bool get isNews => kind == 'news';
  bool get isEvent => kind == 'event';
  bool get isJob => kind == 'job';
  bool get isOfficial => source == 'official';
  bool get isPending => status == 'pending';
  bool get isPublished => status == 'published';
  bool get isExpired => status == 'expired' || (expiresAt != null && DateTime.now().isAfter(expiresAt!));

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
