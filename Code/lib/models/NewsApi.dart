// lib/models/news.dart

class NewsAPI {
  final String source;
  final String author;
  final String title;
  final String description;
  final String url;
  final DateTime publishedAt;
  final List<String> tags;
  String? imageUrl; // campo opzionale per l’immagine

  NewsAPI({
    required this.source,
    required this.author,
    required this.title,
    required this.description,
    required this.url,
    required this.publishedAt,
    required this.tags,
    required this.imageUrl,
  });

  /// Fábrica che costruisce un oggetto `News` a partire da un singolo articolo
  /// nel formato JSON mostrato (sotto la chiave `"articles"`).
  factory NewsAPI.fromJson(Map<String, dynamic> json) {
    // Estraggo il campo "creator" (List<String>?) e ne prendo il primo elemento, altrimenti stringa vuota
    String author = '';
    if (json['creator'] is List && (json['creator'] as List).isNotEmpty) {
      author = (json['creator'] as List).first.toString();
    }

    // Estraggo i tags: json['tags'] è una List<List<dynamic>>, ne faccio il flatten
    List<String> flattenTags = [];
    if (json['tags'] is List) {
      for (var inner in (json['tags'] as List)) {
        if (inner is List) {
          flattenTags.addAll(inner.map((e) => e.toString()));
        }
      }
    }

    // Parsing della data
    DateTime published;
    try {
      published = DateTime.parse(json['pubDate']?.toString() ?? '');
    } catch (_) {
      published = DateTime.now();
    }

    return NewsAPI(
      source: json['source_name']?.toString() ?? '',
      author: author,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['link']?.toString() ?? '',
      publishedAt: published,
      tags: flattenTags,
      imageUrl: json['image_url']?.toString(),
    );
  }
}
