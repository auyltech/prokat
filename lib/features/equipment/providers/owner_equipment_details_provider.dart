import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/owner_equipment_details_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ownerEquipmentDetailsProvider =
    AsyncNotifierProviderFamily<
      OwnerEquipmentDetailsNotifier,
      Equipment,
      String
    >(OwnerEquipmentDetailsNotifier.new);

/// Catalog group of the owner's equipment; `null` until the item is loaded.
///
/// Catalog lookup by `categoryId` comes first: the owner-list seed row has no
/// `category.catalogGroup`.
final ownerEquipmentCatalogGroupProvider =
    Provider.family<CatalogGroup?, String>((ref, id) {
      final equipment = ref
          .watch(ownerEquipmentDetailsProvider(id))
          .valueOrNull;
      if (equipment == null) return null;
      final catalogCategory = ref
          .watch(catalogProvider)
          .valueOrNull
          ?.categoryById(equipment.categoryId);
      return catalogCategory?.catalogGroup ??
          equipment.category?.catalogGroup ??
          CatalogGroup.machinery;
    });
