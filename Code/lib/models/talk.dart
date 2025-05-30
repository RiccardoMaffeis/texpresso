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
  String? videoUrl;      // ← rimane opzionale
  final String thumbnailUrl;

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
    required this.thumbnailUrl,
  });

  factory Talk.fromJson(Map<String, dynamic> json) {
    // parsing di createdAt
    dynamic rawDate = json['publishedAt'] ?? json['createdAt'];
    DateTime parsedDate;
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }

    // estrazione thumbnail da URL YouTube se non fornita
    final videoUrlString = json['url']?.toString() ?? '';
    final thumb = json['thumbnailUrl']?.toString() ??
        (() {
          final match = RegExp(r'v=([^&]+)').firstMatch(videoUrlString);
          final id = match?.group(1);
          return id != null
              ? 'https://img.youtube.com/vi/$id/hqdefault.jpg'
              : '';
        })();

    return Talk(
      id: json['_id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      speakers: json['speakers']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      url: videoUrlString,
      description: json['description']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      createdAt: parsedDate,
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      relatedIds:
          (json['related_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      thumbnailUrl: thumb,
      // videoUrl lo lasci null qui, lo imposti dove ti serve
    );
  }
}
