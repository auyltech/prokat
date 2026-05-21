import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';

class VisibilityStatusSection extends ConsumerStatefulWidget {
  final bool isVisible;
  final String status;
  final String equipmentId;

  const VisibilityStatusSection({
    super.key,
    required this.isVisible,
    required this.status,
    required this.equipmentId,
  });

  @override
  ConsumerState<VisibilityStatusSection> createState() =>
      _VisibilityStatusSectionState();
}

class _VisibilityStatusSectionState
    extends ConsumerState<VisibilityStatusSection> {
  late bool _tempVisible;
  late String _tempStatus;

  Future<void> submitForReview() async {
    final res = await ref
        .read(equipmentProvider.notifier)
        .updateVisibilityStatus(
          widget.equipmentId,
          widget.isVisible,
          "CREATED",
        );

    if (res) {
      AppSnackBar.show(
        context,
        message: "Equipment submited for review",
        isSuccess: true,
      );
    } else {
      AppSnackBar.show(context, message: "Failed to submit", isError: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _tempVisible = widget.isVisible;
    _tempStatus = widget.status;
  }

  bool get _isDirty =>
      (_tempVisible != widget.isVisible) || (_tempStatus != widget.status);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.6);
    final accent = colorScheme.primary;
    final warning = theme.colorScheme.error;

    final isModerated =
        widget.status == "AVAILABLE" ||
        widget.status == "BOOKED" ||
        widget.status == "MAINTENANCE" ||
        widget.status == "DISABLED";

    final isDraft =
        widget.status == "DRAFT" ||
        widget.status == "CREATED" ||
        widget.status == "REJECTED";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionTitle(title: "Status"),

            if (_isDirty)
              FilledButton.icon(
                onPressed: () async {
                  final res = await ref
                      .read(equipmentProvider.notifier)
                      .updateVisibilityStatus(
                        widget.equipmentId,
                        widget.isVisible,
                        widget.status,
                      );

                  if (res && context.mounted) {
                    AppSnackBar.show(
                      context,
                      message: "Equipment submited for review",
                      isSuccess: true,
                    );
                  }
                },
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text("Save"),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              Icon(Icons.lock_outline_rounded, color: ghostGray, size: 18),
          ],
        ),

        SizedBox(height: 12),

        if (isModerated)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Available for rent", style: theme.textTheme.bodyMedium),

              SizedBox(height: 8),

              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _tempVisible = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _tempVisible
                            ? theme.colorScheme.primary
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _tempVisible
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        "Online",
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: _tempVisible
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _tempVisible = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _tempVisible
                            ? theme.colorScheme.surfaceBright
                            : theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _tempVisible
                              ? theme.colorScheme.outline
                              : theme.colorScheme.error,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        "Offline",
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: _tempVisible
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              Text("Operating status", style: theme.textTheme.bodyMedium),

              /// STATUS LABEL
              SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ["AVAILABLE", "BOOKED", "MAINTENANCE"].map((s) {
                    final isSelected = _tempStatus == s;
                    final isWarning = s == "MAINTENANCE";

                    final Color activeColor = isWarning ? warning : accent;

                    return GestureDetector(
                      onTap: () => setState(() => _tempStatus = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.12)
                              : colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? activeColor
                                : colorScheme.onSurface.withValues(alpha: 0.05),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          s,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: isSelected ? activeColor : ghostGray,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

        if (isDraft)
          PrimaryButton(label: "Submit for Review", onPressed: submitForReview),
      ],
    );
  }
}
