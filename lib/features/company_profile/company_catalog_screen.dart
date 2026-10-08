import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/equipment_image_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/widgets/client_equipment_tile.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_card.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/screens/create_booking_screen.dart';
import 'package:prokat/features/bookings/widgets/equipment_image_header.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_profile_api.dart';
import 'company_information_screen.dart';

UserModel companyPublicUser(Map company) => UserModel(
  id: company['id'],
  role: UserRole.company,
  companyName: company['name'],
  imageUrl: company['avatarUrl'],
  rating: company['ratingAverage'] as num,
  orderCount: company['orderCount'] ?? 0,
  onlineStatus: company['onlineStatus'] == 'ONLINE'
      ? OwnerStatus.online
      : OwnerStatus.offline,
);

Equipment companyDisplayEquipment(Map company) {
  final images = (company['images'] as List)
      .map((i) => EquipmentImage.fromJson(Map<String, dynamic>.from(i)))
      .toList();
  return Equipment(
    id: company['id'],
    companyId: company['id'],
    name: company['advertisingName'],
    model: '',
    status: EquipmentStatus.available,
    isVisible: true,
    city: company['city'],
    ownerComment: company['description'],
    owner: companyPublicUser(company),
    images: images,
    imageUrl: images.firstOrNull?.imageUrl,
    prices: (company['tariffs'] as List)
        .map((t) => PriceEntry.fromJson(Map<String, dynamic>.from(t)))
        .toList(),
  );
}

final companyPublicDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, id) async => Map<String, dynamic>.from(
        await ref.watch(companyProfileApiProvider).request('/catalog/$id'),
      ),
    );

class CompanyCatalogScreen extends ConsumerStatefulWidget {
  const CompanyCatalogScreen({super.key});
  @override
  ConsumerState<CompanyCatalogScreen> createState() =>
      _CompanyCatalogScreenState();
}

class _CompanyCatalogScreenState extends ConsumerState<CompanyCatalogScreen> {
  final List<Map<String, dynamic>> items = [];
  int page = 0, count = 0;
  bool loading = true;
  Object? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load(reset: true));
  }

  Future<void> load({bool reset = false}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final city = ref.read(locationProvider).city;
      final next = reset ? 1 : page + 1;
      final response = await ref
          .read(companyProfileApiProvider)
          .dio
          .get(
            '/company-profile/catalog',
            queryParameters: {
              'page': next,
              'itemsPerPage': 20,
              if (city != null && city.isNotEmpty) 'city': city,
            },
          );
      if (!mounted) return;
      setState(() {
        if (reset) items.clear();
        items.addAll(
          (response.data['data'] as List).map(
            (c) => Map<String, dynamic>.from(c),
          ),
        );
        count = response.data['count'];
        page = next;
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ProkatAppBar(
      title: const Text('Компании'),
      onBack: () => Navigator.of(context).pop(),
    ),
    body: RefreshIndicator(
      onRefresh: () => load(reset: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (loading && items.isEmpty)
            const Center(child: CircularProgressIndicator()),
          if (error != null)
            AppElevatedButton(
              title: 'Повторить',
              onTap: () => load(reset: true),
            ),
          if (!loading && error == null && items.isEmpty)
            const AppCard(child: Text('В этом городе пока нет компаний.')),
          for (final company in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: ClientEquipmentTile(
                equipment: companyDisplayEquipment(company),
                companyCard: true,
                onShare: () => shareCompany(context, ref, {
                  'company': {...company, 'isVisible': true},
                }),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ClientCompanyDetailsScreen(companyId: company['id']),
                  ),
                ),
              ),
            ),
          if (items.length < count)
            AppElevatedButton(
              title: loading ? 'Загрузка…' : 'Показать ещё',
              onTap: loading ? null : () => load(),
            ),
        ],
      ),
    ),
  );
}

class ClientCompanyDetailsScreen extends ConsumerStatefulWidget {
  final String companyId;
  const ClientCompanyDetailsScreen({super.key, required this.companyId});
  @override
  ConsumerState<ClientCompanyDetailsScreen> createState() =>
      _ClientCompanyDetailsScreenState();
}

class _ClientCompanyDetailsScreenState
    extends ConsumerState<ClientCompanyDetailsScreen> {
  Map<String, dynamic>? data;
  Object? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    try {
      final result = await ref.read(
        companyPublicDetailsProvider(widget.companyId).future,
      );
      if (!mounted) return;
      ref
          .read(bookingMutationProvider.notifier)
          .startBooking(companyDisplayEquipment(result['company']));
      setState(() {
        data = result;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ProkatAppBar(
      title: const Text('Создать заказ'),
      onBack: () => Navigator.of(context).pop(),
    ),
    body: data == null
        ? Center(
            child: error == null
                ? const CircularProgressIndicator()
                : AppElevatedButton(title: 'Повторить', onTap: load),
          )
        : CreateBookingScreen(
            equipmentId: widget.companyId,
            companyId: widget.companyId,
            beforeOrderFields: Column(
              children: [
                for (final group in data!['categories'] as List)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClientCompanyCategoryScreen(
                              companyId: widget.companyId,
                              category: Map<String, dynamic>.from(
                                group['category'],
                              ),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 64,
                              child: OptimizedNetworkImage(
                                imageUrl:
                                    group['category']['image']?['imageUrl'] ??
                                    '',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ref
                                            .watch(catalogProvider)
                                            .valueOrNull
                                            ?.categoryById(
                                              group['category']['id'],
                                            )
                                            ?.label(
                                              Localizations.localeOf(context)
                                                  .languageCode,
                                            ) ??
                                        group['category']['name'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text('Всего ${group['total']}'),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}

class ClientCompanyCategoryScreen extends ConsumerStatefulWidget {
  final String companyId;
  final Map<String, dynamic> category;
  const ClientCompanyCategoryScreen({
    super.key,
    required this.companyId,
    required this.category,
  });
  @override
  ConsumerState<ClientCompanyCategoryScreen> createState() =>
      _ClientCompanyCategoryScreenState();
}

class _ClientCompanyCategoryScreenState
    extends ConsumerState<ClientCompanyCategoryScreen> {
  late Future<dynamic> data;
  @override
  void initState() {
    super.initState();
    data = ref
        .read(companyProfileApiProvider)
        .request(
          '/catalog/${widget.companyId}/equipment?categoryId=${widget.category['id']}',
        );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ProkatAppBar(
      title: Text(
        ref
                .watch(catalogProvider)
                .valueOrNull
                ?.categoryById(widget.category['id'])
                ?.label(Localizations.localeOf(context).languageCode) ??
            widget.category['name'],
      ),
      onBack: () => Navigator.of(context).pop(),
    ),
    body: FutureBuilder(
      future: data,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? AppElevatedButton(
                    title: 'Повторить',
                    onTap: () => setState(() {
                      data = ref
                          .read(companyProfileApiProvider)
                          .request(
                            '/catalog/${widget.companyId}/equipment?categoryId=${widget.category['id']}',
                          );
                    }),
                  )
                : const CircularProgressIndicator(),
          );
        }
        final result = snapshot.data as Map;
        return ListView(
          children: [
            for (final row in result['units'] as List)
              OwnerEquipmentCard(
                equipment: Equipment.fromJson(Map<String, dynamic>.from(row)),
                readOnly: true,
                showShare: false,
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClientCompanyUnitScreen(
                      companyId: widget.companyId,
                      equipmentId: row['id'],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class ClientCompanyUnitScreen extends ConsumerStatefulWidget {
  final String companyId, equipmentId;
  const ClientCompanyUnitScreen({
    super.key,
    required this.companyId,
    required this.equipmentId,
  });
  @override
  ConsumerState<ClientCompanyUnitScreen> createState() =>
      _ClientCompanyUnitScreenState();
}

class _ClientCompanyUnitScreenState
    extends ConsumerState<ClientCompanyUnitScreen> {
  late Future<dynamic> data;
  @override
  void initState() {
    super.initState();
    data = load();
  }

  Future<dynamic> load() => ref
      .read(companyProfileApiProvider)
      .request('/catalog/${widget.companyId}/equipment/${widget.equipmentId}');
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ProkatAppBar(
      title: const Text('Детали техники'),
      onBack: () => Navigator.of(context).pop(),
    ),
    body: FutureBuilder(
      future: data,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? AppElevatedButton(
                    title: 'Повторить',
                    onTap: () => setState(() => data = load()),
                  )
                : const CircularProgressIndicator(),
          );
        }
        final result = snapshot.data as Map;
        final unit = Equipment.fromJson(
          Map<String, dynamic>.from((result['units'] as List).first),
        );
        return ListView(
          children: [
            EquipmentImageHeader(imageUrls: unit.displayImageUrls),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(unit.name, style: AppFonts.headingM(context)),
                  Text(unit.model, style: AppFonts.caption(context)),
                  const SizedBox(height: 16),
                  UserInfoTile(
                    user: companyPublicUser(result['company']),
                    showPresence: true,
                  ),
                  const SizedBox(height: 16),
                  Text(unit.ownerComment ?? ''),
                  const SizedBox(height: 16),
                  for (final price in unit.prices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Text(
                          '${price.label ?? ''} ${formatPrice(price.price)} ${getPriceRate(price.priceRate, l10n: AppLocalizations.of(context)!)}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

Map<String, dynamic> companyForShare(Equipment equipment) => {
  'id': equipment.id,
  'name': equipment.owner?.companyName ?? equipment.name,
  'advertisingName': equipment.name,
  'description': equipment.ownerComment ?? '',
  'city': equipment.city ?? '',
  'isVisible': true,
  'images': [
    for (final image in equipment.images) {'imageUrl': image.imageUrl},
  ],
};
