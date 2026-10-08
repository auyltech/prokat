import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/chat/providers/chat_sidebar_bootstrap_provider.dart';
import 'package:prokat/features/chat/models/chat_list_filter.dart';
import 'package:prokat/features/chat/utils/chat_sidebar_update_utils.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/providers/booking_provider.dart';
import 'package:prokat/features/bookings/notifiers/booking_notifier.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/chat/utils/chat_resume_sync_observer.dart';

import 'dart:async';

import 'package:prokat/features/price_negotiations/state/price_negotiation_notifier.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiations_query_notifier.dart';
import 'package:prokat/features/reviews/state/review_notifier.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/features/requests/state/request_mutation_notifier.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_controller.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_controller.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/features/reviews/state/review_service.dart';
import 'package:prokat/features/workflow/providers/workflow_providers.dart';
import 'package:prokat/features/workflow/providers/workflow_bootstrap_provider.dart';
import 'package:prokat/features/workflow/state/workflow_cache_coordinator.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/state/booking_service.dart';
import 'package:prokat/features/bookings/notifiers/booking_mutation_notifier.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_history_bookings_provider.dart';
import 'package:prokat/features/bookings/notifiers/owner_active_bookings_notifier.dart';
import 'package:prokat/features/bookings/notifiers/owner_history_bookings_notifier.dart';
import 'package:prokat/features/bookings/screens/owner_bookings_screen.dart';
import 'package:prokat/features/bookings/screens/owner_bookings_history_screen.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_service.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:prokat/features/requests/state/owner_active_requests_notifier.dart';
import 'package:prokat/features/requests/screens/owner_requests_screen.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/state/offers_service.dart';
import 'package:prokat/features/offers/state/offers_notifier.dart';
import 'package:prokat/features/offers/state/offers_query_notifier.dart';
import 'package:prokat/features/offers/screens/create_offer_screen.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/notifiers/owner_chats_notifier.dart';
import 'package:prokat/features/chat/notifiers/current_chat_notifier.dart';
import 'package:prokat/features/chat/notifiers/chat_messages_notifier.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/chat/state/post_mutation_cache_coordinator.dart';
import 'package:prokat/features/chat/screens/owner_chat_list_screen.dart';
import 'package:prokat/features/chat/screens/owner_chat_screen.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';

import 'company_scope.dart';

import 'package:flutter/material.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment/providers/equipment_dependencies.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/providers/owner_fleet_groups_provider.dart';
import 'package:prokat/features/equipment/state/equipment_mutation_notifier.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/features/equipment/state/owner_equipment_notifier.dart';
import 'package:prokat/features/equipment/state/owner_equipment_details_notifier.dart';
import 'package:prokat/features/equipment/screens/owner_equipment_detail_screen.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_detail_title.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';

import 'company_profile_api.dart';
import 'company_profile_screen.dart';
import 'company_park_screen.dart';

/// Owns a separate navigation tree and equipment cache. A company member keeps
/// their personal account role; authorization is checked by the company API.
class CompanyWorkspace extends ConsumerWidget {
  final String companyId;
  const CompanyWorkspace({super.key, required this.companyId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(companyAccessProvider);
    return access.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Профиль компании')),
        body: Center(
          child: AppElevatedButton(
            title: 'Повторить',
            onTap: () => ref.invalidate(companyAccessProvider),
          ),
        ),
      ),
      data: (data) {
        final memberships = (data['memberships'] as List).cast<Map>();
        final membership = memberships
            .where(
              (m) =>
                  m['companyId'] == companyId &&
                  m['company']['status'] == 'APPROVED',
            )
            .firstOrNull;
        if (membership == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Профиль компании')),
            body: const Center(child: Text('Нет доступа к компании')),
          );
        }
        final company = membership['company'] as Map;
        final service = EquipmentService(
          ref.read(apiClientProvider),
          companyId: companyId,
          companyCity: company['city'],
        );
        return ProviderScope(
          key: ValueKey('$companyId:${company['city']}'),
          overrides: [
            activeCompanyIdProvider.overrideWithValue(companyId),
            bookingProvider.overrideWith(BookingNotifier.new),
            companyRootNavigationProvider.overrideWithValue((path) {
              unawaited(GoRouter.of(context).push(path));
            }),
            requestMutationProvider.overrideWith(
              (ref) => RequestMutationNotifier(
                api: ref.read(requestServiceProvider),
                ref: ref,
              ),
            ),
            reviewByBookingProvider.overrideWith(
              (ref, id) => ReviewNotifier(ref.read(reviewServiceProvider), id),
            ),
            priceNegotiationsProvider.overrideWith(
              PriceNegotiationsNotifier.new,
            ),
            priceNegotiationMutationProvider.overrideWith(
              (ref) => PriceNegotiationMutationNotifier(
                ref,
                ref.read(priceNegotiationServiceProvider),
              ),
            ),
            bookingChatActionControllerProvider.overrideWith(
              (ref, id) => BookingChatActionController(ref: ref, bookingId: id),
            ),
            offerChatActionControllerProvider.overrideWith(
              OfferChatActionController.new,
            ),
            chatResolverProvider.overrideWith((ref, lookup) async {
              final response = lookup.chatId != null
                  ? await ref
                        .read(chatServiceProvider)
                        .getChatById(lookup.chatId!)
                  : await ref
                        .read(chatServiceProvider)
                        .getChatByType(lookup.type!);
              if (response.data == null) {
                throw Exception(response.message);
              }
              return response.data!;
            }),
            reviewServiceProvider.overrideWithValue(
              ReviewService(ref.read(apiClientProvider), companyId: companyId),
            ),
            chatSidebarBootstrapProvider.overrideWith((ref) {
              final socket = ref.watch(chatSocketServiceProvider);
              final remove = socket.onSidebarUpdate((update) {
                for (final filter in ChatListFilter.values) {
                  final provider = ownerChatsByFilterProvider(filter);
                  if (!ref.exists(provider)) continue;
                  final notifier = ref.read(provider.notifier);
                  final result = notifier.applySidebarUpdate(
                    update: update,
                    currentUserId: ref.read(authProvider).currentUserId,
                    isThreadOpen: socket.activeChatId == update.chatId,
                  );
                  if (result == ChatSidebarApplyStatus.notFound) {
                    unawaited(notifier.refresh());
                  }
                }
              });
              ref.onDispose(remove);
            }),
            workflowCacheCoordinatorProvider.overrideWith(
              WorkflowCacheCoordinator.new,
            ),
            workflowBootstrapProvider.overrideWith((ref) {
              final coordinator = ref.watch(workflowCacheCoordinatorProvider);
              final remove = ref
                  .watch(workflowSocketServiceProvider)
                  .onUpdate(coordinator.apply);
              final socket = ref.watch(appSocketProvider);
              final key = Object();
              void resync() {
                unawaited(coordinator.resyncAfterReconnect());
                ref.invalidate(companyBalanceProvider(companyId));
                ref.invalidate(companyDashboardProvider(companyId));
              }

              socket.addConnectListener(key, resync);
              final observer = ChatResumeSyncObserver(
                onResumeFromBackground: resync,
              );
              WidgetsBinding.instance.addObserver(observer);
              ref.onDispose(() {
                remove();
                socket.removeConnectListener(key);
                WidgetsBinding.instance.removeObserver(observer);
              });
            }),
            exitCompanyProvider.overrideWithValue(() {
              unawaited(
                ref.read(appStartupProvider.notifier).setClientMode().then((_) {
                  if (context.mounted) {
                    GoRouter.of(context).go(AppRoutes.clientProfile);
                  }
                }),
              );
            }),
            bookingServiceProvider.overrideWithValue(
              BookingService(ref.read(apiClientProvider), companyId: companyId),
            ),
            bookingMutationProvider.overrideWith(
              (ref) => BookingMutationNotifier(
                api: ref.read(bookingServiceProvider),
                ref: ref,
              ),
            ),
            ownerActiveBookingsProvider.overrideWith(
              OwnerActiveBookingsNotifier.new,
            ),
            ownerHistoryBookingsProvider.overrideWith(
              OwnerHistoryBookingsNotifier.new,
            ),
            requestServiceProvider.overrideWithValue(
              RequestService(ref.read(apiClientProvider), companyId: companyId),
            ),
            ownerActiveRequestsProvider.overrideWith(
              OwnerActiveRequestsNotifier.new,
            ),
            offersServiceProvider.overrideWithValue(
              OffersService(ref.read(apiClientProvider), companyId: companyId),
            ),
            ownerOffersProvider.overrideWith(OwnerOffersNotifier.new),
            offerMutationProvider.overrideWith(
              (ref) => OfferMutationNotifier(
                service: ref.read(offersServiceProvider),
                ref: ref,
              ),
            ),
            chatServiceProvider.overrideWithValue(
              ChatService(ref.read(apiClientProvider), companyId: companyId),
            ),
            ownerChatsByFilterProvider.overrideWith(OwnerChatsNotifier.new),
            currentChatProvider.overrideWith(CurrentChatNotifier.new),
            chatMessagesProvider.overrideWith(ChatMessagesNotifier.new),
            postMutationCacheCoordinatorProvider.overrideWith(
              PostMutationCacheCoordinator.new,
            ),
            priceNegotiationServiceProvider.overrideWithValue(
              PriceNegotiationService(
                ref.read(apiClientProvider),
                companyId: companyId,
              ),
            ),
            equipmentServiceProvider.overrideWithValue(service),
            ownerEquipmentProvider.overrideWith(OwnerEquipmentNotifier.new),
            ownerEquipmentDetailsProvider.overrideWith(
              OwnerEquipmentDetailsNotifier.new,
            ),
            equipmentMutationProvider.overrideWith(
              (ref) => EquipmentMutationNotifier(api: service, ref: ref),
            ),
            ownerFleetGroupsProvider.overrideWith(
              (ref) async => CatalogGroup.values,
            ),
            ownerEquipmentCatalogGroupProvider.overrideWith(
              (ref, id) => ref
                  .watch(ownerEquipmentDetailsProvider(id))
                  .valueOrNull
                  ?.category
                  ?.catalogGroup,
            ),
          ],
          child: _CompanyNavigation(
            companyId: companyId,
            companyName: company['name'],
          ),
        );
      },
    );
  }
}

class _CompanyNavigation extends ConsumerStatefulWidget {
  final String companyId, companyName;
  const _CompanyNavigation({
    required this.companyId,
    required this.companyName,
  });
  @override
  ConsumerState<_CompanyNavigation> createState() => _CompanyNavigationState();
}

class _CompanyNavigationState extends ConsumerState<_CompanyNavigation> {
  late final StateController<String?> notificationScope = ref.read(
    notificationCompanyScopeProvider.notifier,
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) notificationScope.state = widget.companyId;
    });
  }

  late final GoRouter router = GoRouter(
    initialLocation: '/company/profile',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final path = state.uri.path;
          final index = path.contains('/equipment')
              ? 1
              : path.contains('/requests')
              ? 2
              : path.contains('/bookings')
              ? 3
              : path.contains('/chat')
              ? 4
              : 0;
          return Scaffold(
            body: child,
            bottomNavigationBar: AppNavigationBar(
              tone: AppNavigationBarTone.company,
              currentIndex: index,
              items: const [
                AppNavigationBarItem(
                  icon: LucideIcons.user2400,
                  label: 'Профиль',
                ),
                AppNavigationBarItem(
                  icon: LucideIcons.warehouse400,
                  label: 'Парк',
                ),
                AppNavigationBarItem(
                  icon: LucideIcons.radar400,
                  label: 'Запросы',
                ),
                AppNavigationBarItem(
                  icon: LucideIcons.scrollText400,
                  label: 'Заказы',
                ),
                AppNavigationBarItem(
                  icon: LucideIcons.messageCircle400,
                  label: 'Чаты',
                ),
              ],
              onItemTap: (next) => router.go(
                [
                  '/company/profile',
                  AppRoutes.ownerEquipment,
                  AppRoutes.ownerRequests,
                  AppRoutes.ownerBookings,
                  AppRoutes.ownerChatList,
                ][next],
              ),
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/company/profile',
            builder: (_, _) => CompanyProfileScreen(
              companyId: widget.companyId,
              companyName: widget.companyName,
            ),
          ),
          GoRoute(
            path: AppRoutes.ownerEquipment,
            builder: (_, _) => CompanyParkScreen(companyId: widget.companyId),
          ),
          GoRoute(
            path: AppRoutes.ownerRequests,
            builder: (_, _) => frame('Запросы', const OwnerRequestsScreen()),
            routes: [
              GoRoute(
                path: AppRoutes.sendOffer,
                builder: (_, _) => frame(
                  'Отправить предложение',
                  const CreateOfferScreen(),
                  back: true,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.ownerBookings,
            builder: (_, _) => frame('Мои заказы', const OwnerBookingsScreen()),
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (_, _) => frame(
                  'История заказов',
                  const OwnerBookingHistoryScreen(),
                  back: true,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.ownerChatList,
            builder: (_, _) => frame('Чаты', const OwnerChatListScreen()),
            routes: [
              GoRoute(
                path: 'direct/:id',
                builder: (_, state) => frame(
                  'Переписка',
                  OwnerChatScreen(chatId: state.pathParameters['id']!),
                  back: true,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  Widget frame(String title, Widget body, {bool back = false}) => Scaffold(
    appBar: ProkatAppBar(
      title: Text(title),
      onBack: back ? () => router.pop() : null,
    ),
    body: body,
  );
  @override
  void dispose() {
    unawaited(
      Future.microtask(() {
        if (notificationScope.state == widget.companyId) {
          notificationScope.state = null;
        }
      }),
    );
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(workflowBootstrapProvider);
    ref.watch(chatSidebarBootstrapProvider);
    ref.watch(companyBalanceProvider(widget.companyId));
    return Router.withConfig(config: router);
  }
}

class CompanyEquipmentDetailsPage extends StatelessWidget {
  final String id;
  const CompanyEquipmentDetailsPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ProkatAppBar(
      title: OwnerEquipmentDetailTitle(equipmentId: id),
      onBack: () => Navigator.of(context).pop(),
      actions: const [NotificationBadge()],
    ),
    body: OwnerEquipmentDetailScreen(equipmentId: id),
  );
}
