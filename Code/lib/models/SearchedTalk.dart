class SearchedTalk {
  final String id;
  final String slug;
  final String speakers;
  final String title;
  final String url;
  final String description;
  final String duration;
  final String publishedAt;
  final String internalId;
  final List<String> tags;
  final List<String> comprehendAnalysis;

  SearchedTalk({
    required this.id,
    required this.slug,
    required this.speakers,
    required this.title,
    required this.url,
    required this.description,
    required this.duration,
    required this.publishedAt,
    required this.internalId,
    required this.tags,
    required this.comprehendAnalysis,
  });

  factory SearchedTalk.fromJson(Map<String, dynamic> json) => SearchedTalk(
    id: json['_id'] as String,
    slug: json['slug'] as String,
    speakers: json['speakers'] as String,
    title: json['title'] as String,
    url: json['url'] as String,
    description: json['description'] as String,
    duration: json['duration'] as String,
    publishedAt: json['publishedAt'] as String,
    internalId: json['internal_id'] as String,
    tags: List<String>.from(json['tags'] as List<dynamic>),
    comprehendAnalysis: json['comprehend_analysis']?['KeyPhrases'] != null
        ? List<String>.from(
            (json['comprehend_analysis']['KeyPhrases'] as List<dynamic>))
        : <String>[],
  );
}
