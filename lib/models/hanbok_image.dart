class HanbokImage {
  final String id;
  final String category;
  final String imagePath;
  final String? name;
  final String? description;
  final String? originalFilename;

  HanbokImage({
    required this.id,
    required this.category,
    required this.imagePath,
    this.name,
    this.description,
    this.originalFilename,
  });

  factory HanbokImage.fromJson(Map<String, dynamic> json) {
    return HanbokImage(
      id: json['id'] as String,
      category: json['category'] as String,
      imagePath: json['imagePath'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      originalFilename: json['originalFilename'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'imagePath': imagePath,
      'name': name,
      'description': description,
      'originalFilename': originalFilename,
    };
  }
} 