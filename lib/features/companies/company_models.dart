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
  final bool catalogVisible;

  const CompanyProfile({
    required this.id,
    required this.name,
    required this.bin,
    required this.description,
    required this.city,
    this.logoUrl,
    required this.status,
    this.catalogVisible = true,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
    id: _text(json['id']),
    name: _text(json['name']),
    bin: _text(json['bin']),
    description: _text(json['description']),
    city: _text(json['city']),
    logoUrl: json['logoUrl'] as String?,
    status: _text(json['status']),
    catalogVisible: json['catalogVisible'] != false,
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
  final String organizationId;
  const CompanyInvitation({
    required this.id,
    required this.role,
    required this.companyName,
    this.organizationId = '',
  });
  factory CompanyInvitation.fromJson(Map<String, dynamic> json) =>
      CompanyInvitation(
        id: _text(json['id']),
        role: _text(json['role']),
        companyName: _text(_object(json['organization'])['name']),
        organizationId: _text(_object(json['organization'])['id']),
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

class CompanyPrice {
  final int amount;
  final String rate;
  final String? label;
  final bool isStartingFrom;
  const CompanyPrice({
    required this.amount,
    required this.rate,
    this.label,
    this.isStartingFrom = false,
  });
  factory CompanyPrice.fromJson(Map<String, dynamic> json) => CompanyPrice(
    amount: json['price'] is num
        ? (json['price'] as num).toInt()
        : int.tryParse('${json['price']}') ?? 0,
    rate: json['priceRate'] as String? ?? '',
    label: json['label'] as String?,
    isStartingFrom: json['isStartingFrom'] == true,
  );
}

class CompanyFleetItem {
  final String id;
  final String name;
  final String model;
  final String plateNumber;
  final String categoryId;
  final String? serviceCityId;
  final String ownerComment;
  final String status;
  final bool isVisible;
  final bool busy;
  final String? imageUrl;
  final List<CompanyPrice> prices;
  const CompanyFleetItem({
    required this.id,
    required this.name,
    required this.model,
    this.plateNumber = '',
    required this.categoryId,
    this.serviceCityId,
    required this.ownerComment,
    required this.status,
    required this.isVisible,
    this.busy = false,
    this.imageUrl,
    this.prices = const [],
  });
  factory CompanyFleetItem.fromJson(Map<String, dynamic> json) {
    final images = companyObjectList(json['images']);
    return CompanyFleetItem(
      id: _text(json['id']),
      name: _text(json['name']),
      model: _text(json['model']),
      plateNumber: _text(json['plateNumber']),
      categoryId: _text(json['categoryId']),
      serviceCityId: json['serviceCityId'] as String?,
      ownerComment: _text(json['ownerComment']),
      status: _text(json['status']),
      isVisible: json['isVisible'] == true,
      busy: json['busy'] == true,
      imageUrl:
          json['mainImageUrl'] as String? ??
          (images.isEmpty ? null : images.first['imageUrl'] as String?),
      prices: companyObjectList(json['prices'])
          .map(CompanyPrice.fromJson)
          .toList(),
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

class PublicCompanySummary {
  final String id;
  final String name;
  final String description;
  final String city;
  final String? logoUrl;
  final List<String> photoUrls;
  final int total;
  final int busy;
  const PublicCompanySummary({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    this.logoUrl,
    this.photoUrls = const [],
    required this.total,
    this.busy = 0,
  });
  factory PublicCompanySummary.fromJson(Map<String, dynamic> json) =>
      PublicCompanySummary(
        id: _text(json['id']),
        name: _text(json['name']),
        description: _text(json['description']),
        city: _text(json['city']),
        logoUrl: json['logoUrl'] as String?,
        photoUrls: (json['photoUrls'] as List? ?? [])
            .whereType<String>()
            .toList(),
        total: _count(json['total']),
        busy: _count(json['busy']),
      );
}

class PublicCompanyCard {
  final PublicCompanySummary company;
  final List<CompanyFleetGroup> groups;
  final int total;
  final int busy;
  const PublicCompanyCard({
    required this.company,
    required this.groups,
    required this.total,
    required this.busy,
  });
  List<CompanyFleetItem> get items => [
    for (final group in groups)
      for (final category in group.categories) ...category.items,
  ];
  factory PublicCompanyCard.fromJson(Map<String, dynamic> json) {
    final totals = _object(json['totals']);
    final company = _object(json['company']);
    return PublicCompanyCard(
      company: PublicCompanySummary.fromJson({
        ...company,
        'total': totals['total'],
      }),
      groups: companyObjectList(json['groups'])
          .map(CompanyFleetGroup.fromJson)
          .toList(),
      total: _count(totals['total']),
      busy: _count(totals['busy']),
    );
  }
}

class CompanyBookingMachine {
  final String id;
  final String name;
  final String model;
  const CompanyBookingMachine({
    required this.id,
    required this.name,
    required this.model,
  });
  factory CompanyBookingMachine.fromJson(Map<String, dynamic> json) =>
      CompanyBookingMachine(
        id: _text(json['id']),
        name: _text(json['name']),
        model: _text(json['model']),
      );
}

class CompanyBookingRequest {
  final String id;
  final String status;
  final String comment;
  final int? budget;
  final DateTime? startsAt;
  final String? phoneNumber;
  final List<CompanyBookingMachine> machines;
  const CompanyBookingRequest({
    required this.id,
    required this.status,
    required this.comment,
    this.budget,
    this.startsAt,
    this.phoneNumber,
    required this.machines,
  });
  factory CompanyBookingRequest.fromJson(Map<String, dynamic> json) =>
      CompanyBookingRequest(
        id: _text(json['id']),
        status: _text(json['status']),
        comment: _text(json['comment']),
        budget: json['budget'] is num ? (json['budget'] as num).toInt() : null,
        startsAt: DateTime.tryParse(_text(json['startsAt'])),
        phoneNumber: json['phoneNumber'] as String?,
        machines: companyObjectList(json['machines'])
            .map(CompanyBookingMachine.fromJson)
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
  List<CompanyFleetItem> get items => [
    for (final group in groups)
      for (final category in group.categories) ...category.items,
  ];
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
