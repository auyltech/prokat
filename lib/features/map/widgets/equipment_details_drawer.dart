import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class EquipmentDetailsDrawer extends ConsumerWidget {
  final Equipment equipment; // Use your Equipment model

  const EquipmentDetailsDrawer({super.key, required this.equipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    const bgColor = Color(0xFF121417);
    const cardColor = Color(0xFF1E2125);
    const accentColor = Color(0xFF4E73DF);

    final notifier = ref.read(favoritesProvider.notifier);
    final bookingNotifier = ref.read(bookingProvider.notifier);
    final isFav = notifier.isFavorite(equipment.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              /// Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    /// 🖼 Hero Image with Soft Rounded Corners
                    if (equipment.imageUrl != null &&
                        equipment.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: OptimizedNetworkImage(
                            imageUrl: equipment.imageUrl!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            fallbackIcon:
                                Icons.precision_manufacturing_outlined,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Status Badge
                          _buildBadge(
                            l10n.available.toUpperCase(),
                            Colors.green,
                          ),

                          const SizedBox(height: 12),

                          /// Name & Model
                          Text(
                            equipment.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "${equipment.model} • ${equipment.capacity} ${equipment.capacityUnit}",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 24),

                          /// 💰 Industrial Pricing Grid
                          Text(
                            l10n.pricingRates,
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            children: equipment.prices
                                .map<Widget>((p) => _PriceTag(p: p))
                                .toList(),
                          ),

                          const SizedBox(height: 24),

                          /// 📍 Location Card
                          if (equipment.location != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: accentColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "${equipment.location?.street}, ${equipment.location?.city}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 32),

                          /// ❤️ + 📅 Industrial Action Row
                          Row(
                            children: [
                              // Favorite Button
                              _CircleIconButton(
                                icon: isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                onTap: () {
                                  notifier.toggleFavorite(equipment.id);
                                },
                              ),
                              const SizedBox(width: 16),
                              // Book equipment button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Select equipment
                                    bookingNotifier.selectEquipment(equipment);
                                    // Navigate to booking page
                                    context.push(
                                      '${AppRoutes.equipment}/${equipment.id}/${AppRoutes.book}',
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.startBooking,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final dynamic p;
  const _PriceTag({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "\$${p.price}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: " / ${p.priceRate}",
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white70),
      ),
    );
  }
}
