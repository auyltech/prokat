import 'package:prokat/features/catalog/models/localized_names.dart';

List<Map<String, dynamic>> companyObjectList(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

Map<String, dynamic> _object(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

String _text(dynamic value) => value?.toString() ?? '';
int _count(dynamic value) => value is num ? value.toInt() : 0;

class CompanyProfile {
  final String id;
  final String name;
  final String bin;
  final String description;
  final String city;
  final String? logoUrl;
  final String status;

  const CompanyProfile({
    required this.id,
    required this.name,
    required this.bin,
    required this.description,
    required this.city,
    this.logoUrl,
    required this.status,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
    id: _text(json['id']),
    name: _text(json['name']),
    bin: _text(json['bin']),
    description: _text(json['description']),
    city: _text(json['city']),
    logoUrl: json['logoUrl'] as String?,
    status: _text(json['status']),
  );
}

class CompanyMembership {
  final String id;
  final String role;
  final CompanyProfile organization;

  const CompanyMembership({
    required this.id,
    required this.role,
    required this.organization,
  });
  bool get canManageProfile => role == 'OWNER';

  factory CompanyMembership.fromJson(Map<String, dynamic> json) =>
      CompanyMembership(
        id: _text(json['id']),
        role: _text(json['role']),
        organization: CompanyProfile.fromJson(_object(json['organization'])),
      );
}

class CompanyApplication {
  final String id;
  final String name;
  final String bin;
  final String status;
  final String adminComment;

  const CompanyApplication({
    required this.id,
    required this.name,
    required this.bin,
    required this.status,
    required this.adminComment,
  });
  bool get isPending => status == 'PENDING';

  factory CompanyApplication.fromJson(Map<String, dynamic> json) =>
      CompanyApplication(
        id: _text(json['id']),
        name: _text(json['name']),
        bin: _text(json['bin']),
        status: _text(json['status']),
        adminComment: _text(json['adminComment']),
      );
}

class CompanyInvitation {
  final String id;
  final String role;
  final String companyName;
  const CompanyInvitation({
    required this.id,
    required this.role,
    required this.companyName,
  });
  factory CompanyInvitation.fromJson(Map<String, dynamic> json) =>
      CompanyInvitation(
        id: _text(json['id']),
        role: _text(json['role']),
        companyName: _text(_object(json['organization'])['name']),
      );
}

class CompanyContext {
  final List<CompanyMembership> memberships;
  final List<CompanyApplication> requests;
  final List<CompanyInvitation> invitations;
  const CompanyContext({
    this.memberships = const [],
    this.requests = const [],
    this.invitations = const [],
  });
  bool get hasPendingApplication =>
      requests.any((request) => request.isPending);
  factory CompanyContext.fromJson(Map<String, dynamic> json) => CompanyContext(
    memberships: companyObjectList(json['memberships'])
        .map(CompanyMembership.fromJson)
        .toList(),
    requests: companyObjectList(json['requests'])
        .map(CompanyApplication.fromJson)
        .toList(),
    invitations: companyObjectList(json['invitations'])
        .map(CompanyInvitation.fromJson)
        .toList(),
  );
}

class CompanyFleetItem {
  final String id;
  final String name;
  final String model;
  final String categoryId;
  final String? serviceCityId;
  final String ownerComment;
  final String status;
  final bool isVisible;
  final String? imageUrl;
  const CompanyFleetItem({
    required this.id,
    required this.name,
    required this.model,
    required this.categoryId,
    this.serviceCityId,
    required this.ownerComment,
    required this.status,
    required this.isVisible,
    this.imageUrl,
  });
  factory CompanyFleetItem.fromJson(Map<String, dynamic> json) {
    final images = companyObjectList(json['images']);
    return CompanyFleetItem(
      id: _text(json['id']),
      name: _text(json['name']),
      model: _text(json['model']),
      categoryId: _text(json['categoryId']),
      serviceCityId: json['serviceCityId'] as String?,
      ownerComment: _text(json['ownerComment']),
      status: _text(json['status']),
      isVisible: json['isVisible'] == true,
      imageUrl:
          json['mainImageUrl'] as String? ??
          (images.isEmpty ? null : images.first['imageUrl'] as String?),
    );
  }
}

class CompanyFleetCategory {
  final String id;
  final String name;
  final LocalizedNames names;
  final int total;
  final int visible;
  final int busy;
  final List<CompanyFleetItem> items;
  const CompanyFleetCategory({
    required this.id,
    required this.name,
    required this.names,
    required this.total,
    required this.visible,
    required this.busy,
    required this.items,
  });
  String label(String languageCode) =>
      names.pickPreferRu(languageCode, fallback: name);
  factory CompanyFleetCategory.fromJson(Map<String, dynamic> json) =>
      CompanyFleetCategory(
        id: _text(json['id']),
        name: _text(json['name']),
        names: LocalizedNames.fromJson(json['names']),
        total: _count(json['total']),
        visible: _count(json['visible']),
        busy: _count(json['busy']),
        items: companyObjectList(json['items'])
            .map(CompanyFleetItem.fromJson)
            .toList(),
      );
}

class CompanyFleetGroup {
  final String id;
  final String name;
  final LocalizedNames names;
  final List<CompanyFleetCategory> categories;
  const CompanyFleetGroup({
    required this.id,
    required this.name,
    required this.names,
    required this.categories,
  });
  factory CompanyFleetGroup.fromJson(Map<String, dynamic> json) =>
      CompanyFleetGroup(
        id: _text(json['id']),
        name: _text(json['name']),
        names: LocalizedNames.fromJson(json['names']),
        categories: companyObjectList(json['categories'])
            .map(CompanyFleetCategory.fromJson)
            .toList(),
      );
}

class CompanyFleet {
  final List<CompanyFleetGroup> groups;
  final int total;
  final int visible;
  final int busy;
  const CompanyFleet({
    required this.groups,
    required this.total,
    required this.visible,
    required this.busy,
  });
  factory CompanyFleet.fromJson(Map<String, dynamic> json) {
    final totals = _object(json['totals']);
    return CompanyFleet(
      groups: companyObjectList(json['groups'])
          .map(CompanyFleetGroup.fromJson)
          .toList(),
      total: _count(totals['total']),
      visible: _count(totals['visible']),
      busy: _count(totals['busy']),
    );
  }
}
