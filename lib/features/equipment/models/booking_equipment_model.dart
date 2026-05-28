class BookingEquiment {
  final String? id;

  final String? name;
  final String? model;
  final String? plateNumber;

  final String? imageUrl;

  final String? ownerId;
  final String? ownerName;

  BookingEquiment({
    this.id,
    this.name,
    this.model,
    this.plateNumber,
    this.imageUrl,
    this.ownerId,
    this.ownerName,
  });

  factory BookingEquiment.fromJson(Map<String, dynamic> json) {
    return BookingEquiment(
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      model: json['model'] ?? "",
      plateNumber: json['plateNumber'] ?? "",
      imageUrl: json['imageUrl'] ?? "",
      ownerId: json['ownerId'] ?? "",
      ownerName: json['ownerName'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "model": model,
      "plateNumber": plateNumber,
      "imageUrl": imageUrl,
      "ownerId": ownerId,
      "ownerName": ownerName,
    };
  }
}