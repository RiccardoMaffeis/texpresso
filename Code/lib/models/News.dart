class News {
  final String title;
  final String description;
  final String url;
  final String? imageUrl;

  News({
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      imageUrl: json['urlToImage'] as String? ?? json['imageUrl'] as String?,
    );
  }
}