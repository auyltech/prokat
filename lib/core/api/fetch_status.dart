import 'package:prokat/core/errors/app_error.dart';

enum FetchStatus { initial, loading, success, empty, refreshing, error }

enum PaginationStatus { idle, loadingMore, error }

FetchStatus resolveFetchStatus<T>(List<T> data) {
  return data.isEmpty ? FetchStatus.empty : FetchStatus.success;
}

enum MutationStatus { idle, submitting, success, error }

// build action ids in this form
// module:action:?id
// modules: booking, request, offer, pricenegotiation,
// create, update, cancel, delete, accept, reject,
// offer:accept:id

class Mutation {
  final String id; // "booking:create"
  final MutationStatus? status;
  final AppError? error;

  Mutation({required this.id, this.status, this.error});

  bool get isSubmitting => status == MutationStatus.submitting;

  bool get isSuccess => status == MutationStatus.success;

  bool get isError => status == MutationStatus.error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mutation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Mutation(id: $id, status: $status)';
  }

  Mutation copyWith({MutationStatus? status, AppError? error}) {
    return Mutation(id: id, status: status ?? this.status, error: error);
  }
}
