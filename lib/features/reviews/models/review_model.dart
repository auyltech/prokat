class ReviewModel {
  final String id;
  final String bookingId;
  final String? reviewerId;
  final String? revieweeId;
  final int stars;
  final String? comment;
  final DateTime? createdAt;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.stars,
    this.reviewerId,
    this.revieweeId,
    this.comment,
    this.createdAt,
  });

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    int parseStars(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return ReviewModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      reviewerId: json['reviewerId']?.toString(),
      revieweeId: json['revieweeId']?.toString(),
      stars: parseStars(json['stars'] ?? json['rating']),
      comment: json['comment']?.toString(),
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

