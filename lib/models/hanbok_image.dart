class HanbokImage {
  final String id;
  final String imagePath;
  final String title;
  final String category;
  final String description;

  HanbokImage({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.category,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HanbokImage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory HanbokImage.fromJson(Map<String, dynamic> json) {
    return HanbokImage(
      id: json['id'] as String,
      imagePath: json['storage_path'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storage_path': imagePath,
      'title': title,
      'category': category,
      'description': description,
    };
  }
}