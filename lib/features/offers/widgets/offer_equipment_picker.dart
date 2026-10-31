import 'package:flutter/material.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OfferEquipmentPicker extends StatelessWidget {
  const OfferEquipmentPicker({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final EquipmentSummaryModel? value;
  final List<EquipmentSummaryModel> options;
  final ValueChanged<EquipmentSummaryModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppDropdownField<EquipmentSummaryModel>(
      title: l10n.navEquipment,
      hint: l10n.selectEquipment,
      sheetTitle: l10n.selectEquipment,
      value: value,
      selectedLabel: value?.name,
      prefix: value == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox.square(
                dimension: 36,
                child: OptimizedNetworkImage(
                  imageUrl: value!.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
      onChanged: onChanged,
      openCustomSheet: () => AppBottomSheet.show<EquipmentSummaryModel>(
        context,
        title: l10n.selectEquipment,
        contentBuilder: (sheetContext) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .6,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = options[index];
              final p = ProkatFlowPalette.of(context);
              return Material(
                color: item.id == value?.id ? p.primarySoft : p.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: p.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(sheetContext).pop(item),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox.square(
                            dimension: 60,
                            child: OptimizedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: p.title,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                item.model ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: p.secondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                item.plateNumber ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: p.title,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.id == value?.id)
                          Icon(Icons.check_rounded, size: 20, color: p.primary),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
