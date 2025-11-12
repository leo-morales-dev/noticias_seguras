class Article {
  final String title;
  final String source;
  final String? description;
  final String? url;

  Article({
    required this.title,
    required this.source,
    this.description,
    this.url,
  });

  factory Article.fromJson(Map<String, dynamic> j) {
    return Article(
      title: (j['title'] ?? '').toString(),
      source: ((j['source'] ?? const {})['name'] ?? '').toString(),
      description: (j['description'] ?? '')?.toString(),
      url: (j['url'] ?? '')?.toString(),
    );
  }
}
