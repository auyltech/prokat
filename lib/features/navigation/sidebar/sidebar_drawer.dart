import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/providers/category_provider.dart';
import 'package:prokat/features/navigation/sidebar/sidebar_tile.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'sidebar_header.dart';

class SidebarDrawer extends ConsumerWidget {
  const SidebarDrawer({super.key});

  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('septic')) return Icons.local_shipping_rounded;
    if (n.contains('truck')) return Icons.fire_truck_rounded;
    if (n.contains('excavator')) return Icons.precision_manufacturing_rounded;
    return Icons.construction_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bgColor = Color(0xFF121417);
    final l10n = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);
    final categoriesState = ref.watch(categoriesProvider);

    final isLoggedIn = authState.isAuthenticated;
    final user = authState.session?.user;
    final isOwner = user?.role == "OWNER" || user?.role == "ADMIN";

    return Drawer(
      backgroundColor: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SidebarHeader(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 10),

                _ActiveServiceTile(
                  title:
                      categoriesState.selectedCategory?.name ??
                      l10n.selectService,
                  icon: categoriesState.selectedCategory?.name != null
                      ? _getCategoryIcon(
                          categoriesState.selectedCategory?.name ?? "",
                        )
                      : Icons.local_shipping_rounded,
                  onTap: () => _showCategoriesSheet(context, ref),
                ),

                SidebarTile(
                  icon: Icons.home,
                  label: l10n.navDashboard,
                  route: "/dashboard",
                ),
                SidebarTile(
                  icon: Icons.map_rounded,
                  label: l10n.navMap,
                  route: AppRoutes.searchMap,
                ),
                SidebarTile(
                  icon: Icons.ads_click,
                  label: l10n.navMyRequests,
                  route: AppRoutes.clientRequests,
                ),
                SidebarTile(
                  icon: Icons.favorite_border,
                  label: l10n.navFavorites,
                  route: AppRoutes.favorites,
                ),
                SidebarTile(
                  icon: Icons.calendar_month_outlined,
                  label: l10n.navMyOrders,
                  route: AppRoutes.clientOrders,
                ),

                if (isOwner) ...[
                  const SizedBox(height: 32),

                  SidebarTile(
                    icon: Icons.construction,
                    label: l10n.navEquipment,
                    route: AppRoutes.ownerEquiment,
                  ),
                  SidebarTile(
                    icon: Icons.book_online_outlined,
                    label: l10n.navBookings,
                    route: AppRoutes.ownerBookings,
                  ),
                  SidebarTile(
                    icon: Icons.message_outlined,
                    label: l10n.navRequests,
                    route: AppRoutes.ownerRequests,
                  ),
                ],
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(3),
              border: Border(
                top: BorderSide(color: Colors.white.withAlpha(10)),
              ),
            ),
            child: isLoggedIn
                ? Column(
                    children: [
                      SidebarTile(
                        icon: Icons.person_outline,
                        label: l10n.navProfile,
                        route: "/profile",
                      ),
                      SidebarTile(
                        icon: Icons.settings_outlined,
                        label: l10n.navSettings,
                        route: "/settings",
                      ),
                      const SizedBox(height: 10),
                    ],
                  )
                : Column(
                    children: [
                      SidebarTile(
                        icon: Icons.person_outline,
                        label: l10n.navLogin,
                        route: "/login",
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

void _showCategoriesSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121417),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Consumer(
      builder: (ctx, sheetRef, _) {
        final categoriesState = sheetRef.watch(categoriesProvider);
        const accentColor = Color(0xFF4E73DF);

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                AppLocalizations.of(ctx)!.selectService,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: categoriesState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: accentColor,
                          strokeWidth: 2,
                        ),
                      )
                    : categoriesState.categories.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(ctx)!.noCategories,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: categoriesState.categories.length,
                        itemBuilder: (context, index) {
                          final category = categoriesState.categories[index];
                          return _SheetCategoryCard(
                            category: category,
                            isSelected:
                                categoriesState.selectedCategory?.id ==
                                category.id,
                            onTap: () {
                              sheetRef
                                  .read(categoriesProvider.notifier)
                                  .selectCategory(category);
                              sheetRef
                                  .read(userProfileProvider.notifier)
                                  .selectCategory(category.id);
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ActiveServiceTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActiveServiceTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent.withAlpha(20), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withAlpha(30)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white54,
          size: 18,
        ),
      ),
    );
  }
}

class _SheetCategoryCard extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetCategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('septic')) return Icons.local_shipping_rounded;
    if (n.contains('truck')) return Icons.fire_truck_rounded;
    if (n.contains('excavator')) return Icons.precision_manufacturing_rounded;
    return Icons.construction_rounded;
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF1E2125);
    const accentColor = Color(0xFF4E73DF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(category.name), color: accentColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              category.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
