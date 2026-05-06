class Category {
  final String id;
  final String name;
  final String capacityUnit;
  final int sortIndex;
  // final bool isUserVisible;
  // final bool isOwnerVisible;
  final String? imageUrl;

  const Category({
    required this.id,
    required this.name,
    required this.capacityUnit,
    required this.sortIndex,
    // required this.isUserVisible,
    // required this.isOwnerVisible,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: json["id"] ?? "",
        name: json["name"] ?? "",
        capacityUnit: json["capacityUnit"] ?? "",
        sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
        // isUserVisible: json["isUserVisible"] ?? false,
        // isOwnerVisible: json["isOwnerVisible"] ?? false,
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
      "capacityUnit": capacityUnit,
      "sortIndex": sortIndex,
      "imageUrl": imageUrl,
    };
  }
}
