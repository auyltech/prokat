import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuestLandingScroll {
  Future<void> Function()? _scrollToHero;

  void attach(Future<void> Function() scrollToHero) {
    _scrollToHero = scrollToHero;
  }

  void detach() {
    _scrollToHero = null;
  }

  Future<void> scrollToHero() async {
    final scrollToHero = _scrollToHero;
    if (scrollToHero == null) return;
    await scrollToHero();
  }
}

final guestLandingScrollProvider = Provider<GuestLandingScroll>((ref) {
  final scroll = GuestLandingScroll();
  ref.onDispose(scroll.detach);
  return scroll;
});
