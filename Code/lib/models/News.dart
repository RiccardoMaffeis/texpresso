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

  /// Fa una fábrica che costruisce un oggetto `NewsAPI` a partire da un singolo articolo
  /// nel formato JSON restituito da Get_news_by_tag (chiave "articles").
  factory News.fromJson(Map<String, dynamic> json) {
    // Di solito l’endpoint “Get_news_by_tag” restituisce, per ogni articolo:
    //  - "source": { "id": ..., "name": ... }
    //  - "author", "title", "description", "url", "urlToImage", "publishedAt", "content"
    // Diamo per scontato che “tags” possa essere un array vuoto o non esista.
    final sourceName = (json['source'] is Map)
        ? (json['source']['name']?.toString() ?? '')
        : (json['source']?.toString() ?? '');

    final author = json['author']?.toString() ?? '';

    final publishedAt = DateTime.tryParse(json['publishedAt']?.toString() ?? '')
        ?? DateTime.now();

    // Se l’endpoint fornisce già “urlToImage”, lo usiamo direttamente.
    final imageUrl = json['urlToImage']?.toString();

    // Se l’endpoint fornisce anche “tags” (array di stringhe), altrimenti lascio vuoto
    List<String> tagsList = [];
    if (json['tags'] is List) {
      tagsList = (json['tags'] as List<dynamic>).map((e) => e.toString()).toList();
    }

    return News(
      source: sourceName,
      author: author,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      publishedAt: publishedAt,
      tags: tagsList,
      imageUrl: imageUrl, 
    );
  }
}