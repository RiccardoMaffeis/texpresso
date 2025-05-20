class Talk {
  final String id;
  final String slug;
  final String speakers;
  final String title;
  final String url;
  final String description;
  final String duration;
  final String publishedAt;
  final List<String> tags;
  final List<String> relatedIds;

  Talk({
    required this.id,
    required this.slug,
    required this.speakers,
    required this.title,
    required this.url,
    required this.description,
    required this.duration,
    required this.publishedAt,
    required this.tags,
    required this.relatedIds,
  });

  factory Talk.fromJSON(Map<String, dynamic> json) {
    return Talk(
      id: json['_id'] ?? '',
      slug: json['slug'] ?? '',
      speakers: json['speakers'] ?? '',
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      relatedIds: (json['related_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}
