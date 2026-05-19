import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/router/refresh_stream.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/appstatic/screens/error_screen.dart';
import 'package:prokat/features/appstatic/screens/help_screen.dart';
import 'package:prokat/features/appstatic/screens/support_us_screen.dart';
import 'package:prokat/features/appstatic/screens/terms_conditions_screen.dart';
import 'package:prokat/features/auth/screens/register_screen.dart';
import 'package:prokat/features/bookings/screens/client_booking_details_screen.dart';
import 'package:prokat/features/bookings/screens/client_bookings_history_screen.dart';
import 'package:prokat/features/bookings/screens/create_booking_screen.dart';
import 'package:prokat/features/bookings/screens/client_bookings_screen.dart';
import 'package:prokat/features/chat/screens/client_chat_info_screen.dart';
import 'package:prokat/features/chat/screens/client_chat_list_screen.dart';
import 'package:prokat/features/chat/screens/client_chat_screen.dart';
import 'package:prokat/features/chat/screens/owner_chat_info_screen.dart';
import 'package:prokat/features/chat/screens/owner_chat_list_screen.dart';
import 'package:prokat/features/chat/screens/owner_chat_screen.dart';
import 'package:prokat/features/equipment/screens/search_equipment_screen.dart';
import 'package:prokat/features/layout/main_scaffold.dart';
import 'package:prokat/features/auth/screens/forgot_password_screen.dart';
import 'package:prokat/features/auth/screens/login_screen.dart';
import 'package:prokat/features/locations/screens/renter_addresses_screen.dart';
import 'package:prokat/features/map/screens/map_owner_pin_location_screen.dart';
import 'package:prokat/features/map/screens/map_renter_equipment_screen.dart';
import 'package:prokat/features/map/screens/map_renter_pin_address_screen.dart';
import 'package:prokat/features/locations/screens/create_address_screen.dart';
import 'package:prokat/features/owner/screens/owner_address_edit_screen.dart';
import 'package:prokat/features/owner/screens/owner_addresses_screen.dart';
import 'package:prokat/features/bookings/screens/owner_bookings_history_screen.dart';
import 'package:prokat/features/bookings/screens/owner_bookings_screen.dart';
import 'package:prokat/features/equipment/screens/owner_equipment_detail_screen.dart';
import 'package:prokat/features/equipment/screens/create_equipment_screen.dart';
import 'package:prokat/features/equipment/screens/owner_equipment_list_screen.dart';
import 'package:prokat/features/requests/screens/owner_requests_screen.dart';
import 'package:prokat/features/requests/screens/create_request_screen.dart';
import 'package:prokat/features/requests/screens/client_requests_history_screen.dart';
import 'package:prokat/features/requests/screens/client_requests_screen.dart';
import 'package:prokat/features/user/screens/owner_dashboard_screen.dart';
import 'package:prokat/features/user/screens/owner_payments_screen.dart';
import 'package:prokat/features/user/screens/owner_payments_topup_screen.dart';
import 'package:prokat/features/user/screens/owner_profile_screen.dart';
import 'package:prokat/features/user/screens/owner_registration_screen.dart';
import 'package:prokat/features/user/screens/owner_settings_screen.dart';
import 'package:prokat/features/owner/screens/register_owner_screen.dart';
import 'package:prokat/features/user/screens/user_dashboard_screen.dart';
import 'package:prokat/features/user/screens/user_profile_screen.dart';
import 'package:prokat/features/user/screens/user_settings_screen.dart';
import 'package:prokat/features/appstatic/screens/launch_screen.dart';
import 'package:prokat/features/appstatic/screens/main_screen.dart';
import 'package:prokat/features/favorites/screens/favorites_screen.dart';
import 'package:prokat/features/notifications/screens/notifications_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier<AppStartupStatus>(
    ref,
    appStartupProvider,
  );
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.launch,

    /// 🔁 REFRESH WHEN STARTUP STATE CHANGES
    refreshListenable: refreshNotifier,

    /// 🔐 AUTH GUARD
    redirect: (context, state) {
      final startupStatus = ref.read(appStartupProvider);
      final startupState = startupStatus.routeState;
      final location = state.matchedLocation;
      final fullLocation = state.uri.toString();

      // 🚀 Handle startup routing FIRST
      switch (startupState) {
        case AppStartupRouteState.loading:
          return AppRoutes.launch;

        case AppStartupRouteState.error:
          return AppRoutes.error;

        case AppStartupRouteState.otp:
          return AppRoutes.login;

        case AppStartupRouteState.guest:
          if (location == AppRoutes.launch) {
            return AppRoutes.main;
          }
          break;

        case AppStartupRouteState.owner:
          if (location == AppRoutes.launch) {
            return AppRoutes.ownerDashboard;
          }
          break;

        case AppStartupRouteState.client:
          if (location == AppRoutes.launch) {
            return AppRoutes.searchList;
          }
          break;
      }

      final isLoggedIn =
          startupState == AppStartupRouteState.client ||
          startupState == AppStartupRouteState.owner;

      final isOwner = startupState == AppStartupRouteState.owner;

      /// 🔒 ROUTES THAT REQUIRE LOGIN
      final requiresAuth = <String>[
        AppRoutes.profile,
        AppRoutes.settings,
        AppRoutes.dashboard,
        AppRoutes.favorites,
        AppRoutes.notifications,
        AppRoutes.ownerNotifications,
      ].any((path) => location == path || location.startsWith('$path/'));

      /// 🔒 BOOKING (nested route)
      final isBookingRoute = location.contains('/book');

      /// 🔒 OWNER ROUTES
      final isOwnerRoute = location.startsWith('/owner');

      /// 🔐 USER AUTH GUARD
      if (!isLoggedIn && (requiresAuth || isBookingRoute || isOwnerRoute)) {
        final from = Uri.encodeComponent(fullLocation);
        return '${AppRoutes.login}?from=$from';
      }

      /// 🏗 OWNER ROLE GUARD
      if (isOwnerRoute && !isOwner) {
        return AppRoutes.login;
      }

      /// 🚫 BLOCK AUTH SCREENS WHEN LOGGED IN
      if (isLoggedIn &&
          (location == AppRoutes.login || location == AppRoutes.register)) {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          return Uri.decodeComponent(from);
        }

        return isOwner ? AppRoutes.ownerDashboard : AppRoutes.searchList;
      }

      return null;
    },

    routes: [
      /// 🚀 PUBLIC
      GoRoute(path: AppRoutes.launch, builder: (_, _) => const LaunchScreen()),
      GoRoute(path: AppRoutes.error, builder: (_, _) => const ErrorScreen()),

      /// 🧱 MAIN APP
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          /// 👤 USER
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.login,
                builder: (_, _) => const LoginScreen(),
              ),
              GoRoute(
                path: AppRoutes.register,
                builder: (_, _) => const RegisterScreen(),
              ),
              GoRoute(
                path: AppRoutes.forgotPassword,
                builder: (_, _) => const ForgotPasswordScreen(),
              ),
              GoRoute(
                path: AppRoutes.main,
                builder: (context, state) {
                  final query = state.uri.queryParameters['query'] ?? '';
                  final category = state.uri.queryParameters['category'] ?? '';

                  final page =
                      int.tryParse(state.uri.queryParameters['page'] ?? '1') ??
                      1;
                  final limit =
                      int.tryParse(
                        state.uri.queryParameters['limit'] ?? '10',
                      ) ??
                      10;

                  final city = state.uri.queryParameters['city'] ?? '';

                  return MainScreen(
                    query: query,
                    category: category,
                    city: city,
                    page: page,
                    limit: limit,
                  );
                },
              ),
              // Static Pages
              // Help And Customer Support
              GoRoute(
                path: AppRoutes.helpSupport,
                builder: (_, _) => const HelpScreen(),
              ),
              // Support us
              GoRoute(
                path: "/support-us",
                builder: (_, _) => const SupportUsPage(),
              ),
              // Terms and conditions
              GoRoute(
                path: "/terms",
                builder: (_, _) => const TermsConditionsScreen(),
              ),
              GoRoute(
                path: AppRoutes.searchList,
                builder: (context, state) {
                  final query = state.uri.queryParameters['query'] ?? '';
                  final category = state.uri.queryParameters['category'] ?? '';

                  final page =
                      int.tryParse(state.uri.queryParameters['page'] ?? '1') ??
                      1;
                  final limit =
                      int.tryParse(
                        state.uri.queryParameters['limit'] ?? '10',
                      ) ??
                      10;

                  final city = state.uri.queryParameters['city'] ?? '';

                  return SearchEquipmentScreen(
                    query: query,
                    category: category,
                    city: city,
                    page: page,
                    limit: limit,
                  );
                },
              ),
              // Map screen which displays equipment for rent
              GoRoute(
                path: AppRoutes.searchMap,
                builder: (_, _) => const MapRenterEquipmentScreen(),
              ),
              // display equipment details in full screen
              GoRoute(
                path: '/equipment/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CreateBookingScreen(equipmentId: id);
                },
                routes: [
                  // Screen for creating a booking on an equipment
                  GoRoute(
                    path: 'book',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return CreateBookingScreen(equipmentId: id); //
                    },
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.addresses,
                builder: (context, state) {
                  return RenterAddressesScreen();
                },
                routes: [
                  // Screen for creating a booking on an equipment
                  GoRoute(
                    path: AppRoutes.pinToMap,
                    builder: (context, state) {
                      return MapRenterPinAddressScreen(); //
                    },
                  ),
                  GoRoute(
                    path: AppRoutes.createAddress,
                    builder: (context, state) {
                      final service =
                          state.uri.queryParameters['service'] ?? "";

                      return CreateAddressScreen(
                        service: service,
                      ); // Pass service=address
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/dashboard',
                builder: (context, state) {
                  return UserDashboardPage(); //
                },
              ),
              GoRoute(
                path: AppRoutes.clientRequests,
                builder: (context, state) {
                  return const ClientRequestsScreen();
                },
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) {
                      return const CreateRequestScreen();
                    },
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) {
                      return const ClientRequestsHistoryScreen();
                    },
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.clientOrders,
                builder: (_, _) => const ClientBookingsScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.clientOrdersHistory,
                    builder: (_, _) {
                      return const ClientBookingsHistoryScreen();
                    },
                  ),
                  GoRoute(
                    path: "/:id",
                    builder: (context, state) {
                      final bookingId =
                          state.uri.queryParameters['bookingId'] ?? '';

                      return ClientBookingDetailsScreen(bookingId: bookingId);
                    },
                  ),
                ],
              ),
              //
              // CLIENT CHAT
              //
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) {
                  final bookingId =
                      state.uri.queryParameters['bookingId'] ?? '';
                  final requestId =
                      state.uri.queryParameters['requestId'] ?? '';

                  return ClientChatListScreen(
                    bookingId: bookingId,
                    requestId: requestId,
                  );
                },
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final chatId = state.pathParameters['id'] ?? '';

                      return ClientChatScreen(chatId: chatId);
                    },
                    routes: [
                      GoRoute(
                        path: 'info',
                        builder: (context, state) => ClientChatInfoScreen(
                          chatId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.favorites,
                builder: (_, _) => const FavoritesScreen(),
              ),
              GoRoute(
                path: AppRoutes.notifications,
                builder: (_, _) => const NotificationsScreen(),
              ),
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const UserProfileScreen(),
              ),
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, _) => const UserSettingsScreen(),
              ),
              GoRoute(
                path: AppRoutes.becomeOwner,
                builder: (_, _) => const RegisterOwnerPage(),
              ),
            ],
          ),

          ///
          /// ******* OWNER *******
          ///
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.ownerDashboard,
                builder: (_, _) => const OwnerDashboardScreen(),
              ),
              GoRoute(
                path: AppRoutes.ownerNotifications,
                builder: (_, _) => const NotificationsScreen(),
              ),
              //
              // Owner Equipment
              //
              GoRoute(
                path: AppRoutes.ownerEquiment,
                builder: (_, _) => const OwnerEquipmentListScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.createEquipment,
                    builder: (_, _) => const CreateEquipmentScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.editEquipment,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return OwnerEquipmentDetailScreen(equipmentId: id);
                    },
                  ),
                ],
              ),
              //
              // Owner Addresses
              //
              GoRoute(
                path: AppRoutes.ownerAddresses,
                builder: (context, state) {
                  return OwnerAddressesScreen();
                },
                routes: [
                  GoRoute(
                    path: AppRoutes.pinToMap,
                    builder: (context, state) {
                      // Owner creates location for equipment, pass id to map screen
                      final equipmentId =
                          state.uri.queryParameters['equipmentId'] ?? "";
                      return MapOwnerPinLocationScreen(
                        equipmentId: equipmentId,
                      );
                    },
                  ),
                  // Enter / create address manually / form
                  GoRoute(
                    path: AppRoutes.createAddress,
                    builder: (context, state) {
                      final service =
                          state.uri.queryParameters['service'] ?? "";

                      final redirectUrl =
                          state.uri.queryParameters['redirectUrl'] ?? "";

                      return CreateAddressScreen(
                        service: service,
                        redirectUrl: redirectUrl,
                      );
                    },
                  ),
                  GoRoute(
                    path: AppRoutes.editAddress,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return OwnerAddressEditScreen(id: id);
                    },
                  ),
                ],
              ),
              //
              // Owner Requests
              //
              GoRoute(
                path: AppRoutes.ownerRequests,
                builder: (_, _) => const OwnerRequestsScreen(),
              ),
              //
              // Owner Bookings
              //
              GoRoute(
                path: AppRoutes.ownerBookings,
                builder: (_, _) => const OwnerBookingsScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) {
                      return OwnerBookingHistoryScreen();
                    },
                  ),
                ],
              ),
              //
              // Owner Profile & Settings
              //
              GoRoute(
                path: AppRoutes.ownerProfile,
                builder: (_, _) => const OwnerProfileScreen(),
              ),
              GoRoute(
                path: AppRoutes.ownerSettings,
                builder: (_, _) => const OwnerSettingsScreen(),
              ),
              //
              // Owner Registration and Payment
              //
              GoRoute(
                path: AppRoutes.ownerRegistration,
                builder: (_, _) => const OwnerRegistrationScreen(),
              ),
              GoRoute(
                path: AppRoutes.ownerPayment,
                builder: (_, _) => const OwnerPaymentsScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.topUp,
                    builder: (_, _) => const OwnerPaymentsTopupScreen(),
                  ),
                ],
              ),
              //
              // Owner Chat
              //
              GoRoute(
                path: AppRoutes.ownerChat,
                builder: (context, state) => const OwnerChatListScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.chatDetail,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return OwnerChatScreen(chatId: id); //
                    },
                    routes: [
                      GoRoute(
                        path: AppRoutes.chatInfo,
                        builder: (context, state) => OwnerChatInfoScreen(
                          chatId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
