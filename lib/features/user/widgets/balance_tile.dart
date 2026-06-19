import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';

class BalanceTile extends ConsumerStatefulWidget {
  const BalanceTile({super.key});

  @override
  ConsumerState<BalanceTile> createState() => _BalanceTileState();
}

class _BalanceTileState extends ConsumerState<BalanceTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final billingState = ref.watch(billingProvider);

    final onlineEquipment = ref.watch(equipmentProvider).onlineEquipmentCount;
    final burnRate = onlineEquipment == 0
        ? 0
        : billingState.getDailyCost(onlineEquipment) / 24;

    // ── Loading state ──
    if (billingState.isBalanceLoading) {
      return _cardShell(
        theme,
        child: const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // ── Error state ──
    if (billingState.errors.containsKey('balance')) {
      return _cardShell(
        theme,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Balance unavailable",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    billingState.errors['balance']!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () =>
                  ref.read(billingProvider.notifier).getOwnerBalance(),
            ),
          ],
        ),
      );
    }

    // ── Normal state ──
    return _cardShell(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: label + active badge ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Account Balance",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  letterSpacing: 0.3,
                ),
              ),
              if (onlineEquipment > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "$onlineEquipment Equipment online",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0D5F5C),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Row 2: balance number + action buttons ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                ((billingState.accountBalance?.secondsRemaining ?? 0) / 60)
                    .toStringAsFixed(0),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 36,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "min",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const Spacer(),
              _ActionButton(
                icon: Icons.history_rounded,
                filled: false,
                onTap: () => context.push(AppRoutes.ownerPayment),
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.add_rounded,
                filled: true,
                onTap: () => context.push(AppRoutes.ownerPaymentTopUp),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),

          const SizedBox(height: 12),

          // ── Row 3: burn rate + exhaustion footer ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FooterMetric(
                label: "Burn rate",
                value: "~${burnRate.toStringAsFixed(0)} min/hr",
                align: CrossAxisAlignment.start,
                valueColor: theme.colorScheme.onSurface,
              ),
              _FooterMetric(
                label: "Est. exhaustion",
                value: billingState.formattedExhaustionTime,
                align: CrossAxisAlignment.end,
                valueColor: billingState.hasActiveBurn
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ],
          ),

          // ── Active burn progress indicator (subtle, at bottom) ──
          if (billingState.hasActiveBurn) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: null,
                minHeight: 3,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardShell(ThemeData theme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

// ── Small helpers ──

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: filled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: filled
              ? null
              : Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled
              ? Colors.white
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _FooterMetric extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;
  final Color valueColor;

  const _FooterMetric({
    required this.label,
    required this.value,
    required this.align,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
