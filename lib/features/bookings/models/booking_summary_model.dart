import 'package:prokat/features/bookings/models/work_status.dart';

class BookingSummaryModel {
  final String id;
  final String status;
  final WorkStatus workStatus;

  BookingSummaryModel({
    required this.id,
    required this.status,
    this.workStatus = WorkStatus.pending,
  });

  factory BookingSummaryModel.fromJson(Map<String, dynamic> json) {
    WorkStatus parseWorkStatus(dynamic value) {
      if (value == null) return WorkStatus.pending;
      final normalized = value.toString().trim().toLowerCase();
      for (final status in WorkStatus.values) {
        if (status.name.toLowerCase() == normalized) {
          return status;
        }
      }
      return WorkStatus.pending;
    }

    return BookingSummaryModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      workStatus: parseWorkStatus(json['workStatus']),
    );
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "status": status, "workStatus": workStatus.name};
  }
}
