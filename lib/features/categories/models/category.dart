class Category {
  final String id;
  final String name;
  final int sortIndex;
  final String? imageUrl;

  const Category({
    required this.id,
    required this.name,
    required this.sortIndex,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: json["id"] ?? "",
        name: json["name"] ?? "",
        sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
        imageUrl: json["imageUrl"] ?? "",
      );
    } catch (e) {
      print("***** CATEGORY PARSE FAILED");
      print(e);
      print(json);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "sortIndex": sortIndex,
      "imageUrl": imageUrl,
    };
  }
}
