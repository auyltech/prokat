import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/layout/section_root_routes.dart';

void main() {
  test('tab destinations are section roots', () {
    expect(isSectionRootPath(AppRoutes.searchList), isTrue);
    expect(isSectionRootPath(AppRoutes.clientRequests), isTrue);
    expect(isSectionRootPath(AppRoutes.clientOrders), isTrue);
    expect(isSectionRootPath(AppRoutes.clientChatList), isTrue);
    expect(isSectionRootPath(AppRoutes.clientProfile), isTrue);
    expect(isSectionRootPath(AppRoutes.ownerEquipment), isTrue);
    expect(isSectionRootPath(AppRoutes.ownerProfile), isTrue);
  });

  test('screens opened over a tab are not section roots', () {
    expect(isSectionRootPath(AppRoutes.clientSettings), isFalse);
    expect(isSectionRootPath(AppRoutes.clientDocuments), isFalse);
    expect(isSectionRootPath(AppRoutes.clientOrdersHistory), isFalse);
    expect(isSectionRootPath(AppRoutes.clientRequestsCreate), isFalse);
    expect(isSectionRootPath(AppRoutes.helpSupport), isFalse);
    expect(isSectionRootPath(AppRoutes.ownerSettings), isFalse);
    expect(isSectionRootPath(AppRoutes.ownerEquipmentCreate), isFalse);
    expect(isSectionRootPath('/owner/equipment/abc'), isFalse);
    expect(isSectionRootPath('/client/chat/direct/abc'), isFalse);
  });

  test('fallback returns the matching tab root', () {
    expect(sectionRootFor(AppRoutes.clientSettings), AppRoutes.clientProfile);
    expect(sectionRootFor(AppRoutes.clientDocuments), AppRoutes.clientProfile);
    expect(
      sectionRootFor(AppRoutes.clientOrdersHistory),
      AppRoutes.clientOrders,
    );
    expect(
      sectionRootFor(AppRoutes.clientRequestsCreate),
      AppRoutes.clientRequests,
    );
    expect(sectionRootFor(AppRoutes.searchMap), AppRoutes.searchList);
    expect(
      sectionRootFor('/client/equipment/abc/book'),
      AppRoutes.searchList,
    );
    expect(
      sectionRootFor(AppRoutes.ownerEquipmentCreate),
      AppRoutes.ownerEquipment,
    );
    expect(sectionRootFor(AppRoutes.ownerSettings), AppRoutes.ownerProfile);
    expect(sectionRootFor(AppRoutes.helpSupport), AppRoutes.main);
  });

  test('logged-in users leave guest overlays toward their profile', () {
    expect(
      backFallbackPath(
        AppRoutes.helpSupport,
        isLoggedIn: true,
        isOwner: false,
      ),
      AppRoutes.clientProfile,
    );
    expect(
      backFallbackPath(AppRoutes.supportUs, isLoggedIn: true, isOwner: true),
      AppRoutes.ownerProfile,
    );
    expect(
      backFallbackPath(AppRoutes.helpSupport, isLoggedIn: false, isOwner: false),
      AppRoutes.main,
    );
  });
}
