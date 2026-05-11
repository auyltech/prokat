import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/widgets/client_bookings_section.dart';
import 'package:prokat/features/bookings/widgets/client_requests_section.dart';
import 'package:prokat/features/categories/providers/category_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/user/widgets/user_dashboard_header.dart';

class UserDashboardPage extends ConsumerStatefulWidget {
  const UserDashboardPage({super.key});

  @override
  ConsumerState<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends ConsumerState<UserDashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(equipmentProvider.notifier).getRenterEquipment();
      ref.read(categoriesProvider.notifier).getCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
            UserDashboardHeader(),

            // 1. Static components wrapped in SliverToBoxAdapter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClientBookingsSection(),

                  const SizedBox(height: 12),

                  ClientRequestsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
