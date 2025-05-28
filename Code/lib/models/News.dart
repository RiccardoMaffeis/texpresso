class News {
  final String source;
  final String author;
  final String title;
  final String description;
  final String url;
  final DateTime publishedAt;
  final List<String> tags;
  String? imageUrl;  // ← campo opzionale per l’immagine

  News({
    required this.source,
    required this.author,
    required this.title,
    required this.description,
    required this.url,
    required this.publishedAt,
    required this.tags,
    this.imageUrl,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      source: json['source']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? '') 
                    ?? DateTime.now(),
      tags: (json['tags'] as List<dynamic>? ?? [])
               .map((e) => e.toString())
               .toList(),
      // imageUrl sarà popolato successivamente
    );
  }
}
