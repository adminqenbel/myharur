// ==============================================================================
// ALERT MODEL — MyHarur v1 core data model
// ==============================================================================
class Alert {
  final String id;
  final String category; // road | electricity | water | govt
  final int? wardId;
  final String title;
  final String body;
  final String source; // official | community
  final String status; // published | pending | rejected | expired
  final String? publishedAsRole;
  final String? createdByUid; // QenBel UID
  final DateTime? expiresAt;
  final bool emergencyTagged;
  final DateTime createdAt;
  // Optional: populated from join
  final String? wardName;

  const Alert({
    required this.id,
    required this.category,
    this.wardId,
    required this.title,
    required this.body,
    required this.source,
    required this.status,
    this.publishedAsRole,
    this.createdByUid,
    this.expiresAt,
    this.emergencyTagged = false,
    required this.createdAt,
    this.wardName,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      category: json['category'] as String? ?? 'govt',
      wardId: json['ward_id'] as int?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      source: json['source'] as String? ?? 'community',
      status: json['status'] as String? ?? 'pending',
      publishedAsRole: json['published_as_role'] as String?,
      createdByUid: json['created_by_uid'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      emergencyTagged: json['emergency_tagged'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      wardName: json['ward_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'ward_id': wardId,
    'title': title,
    'body': body,
    'source': source,
    'status': status,
    'published_as_role': publishedAsRole,
    'created_by_uid': createdByUid,
    'expires_at': expiresAt?.toIso8601String(),
    'emergency_tagged': emergencyTagged,
  };

  bool get isOfficial => source == 'official';
  bool get isPending => status == 'pending';
  bool get isPublished => status == 'published';
  bool get isExpired => status == 'expired' ||
      (expiresAt != null && DateTime.now().isAfter(expiresAt!));

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
