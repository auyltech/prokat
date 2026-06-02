// Aligns with EquipmentListItemDTO
class EquipmentSummaryModel {
  final String? id;

  final String? name;
  final String? model;
  final String? plateNumber;

  final String? imageUrl;

  EquipmentSummaryModel({
    this.id,
    this.name,
    this.model,
    this.plateNumber,
    this.imageUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentSummaryModel &&
          runtimeType == other.runtimeType &&
          id == other.id; // Compares by unique ID

  @override
  int get hashCode => id.hashCode;

  factory EquipmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return EquipmentSummaryModel(
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      model: json['model'] ?? "",
      plateNumber: json['plateNumber'] ?? "",
      imageUrl: json['imageUrl'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "model": model,
      "plateNumber": plateNumber,
      "imageUrl": imageUrl,
    };
  }
}
