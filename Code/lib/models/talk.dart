// models/talk.dart

class Talk {
  final String id;
  final String slug;
  final String speakers;
  final String title;
  final String url;
  final String description;
  final String duration;
  final DateTime createdAt;
  final List<String> tags;
  final List<String> relatedIds;
  String? videoUrl;    // ← nuovo campo opzionale

  Talk({
    required this.id,
    required this.slug,
    required this.speakers,
    required this.title,
    required this.url,
    required this.description,
    required this.duration,
    required this.createdAt,
    required this.tags,
    required this.relatedIds,
    this.videoUrl,
  });

  factory Talk.fromJson(Map<String, dynamic> json) {
    // parsing di createdAt con fallback
    dynamic raw = json['publishedAt'] ?? json['createdAt'];
    DateTime parsedDate;
    if (raw is String) {
      parsedDate = DateTime.tryParse(raw) ?? DateTime.now();
    } else if (raw is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is DateTime) {
      parsedDate = raw;
    } else {
      parsedDate = DateTime.now();
    }

    return Talk(
      id: json['_id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      speakers: json['speakers']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      createdAt: parsedDate,
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      relatedIds: (json['related_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      // videoUrl verrà settato dopo in getRandomTalk()
    );
  }
}
