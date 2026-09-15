import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuestCityPrompt extends Notifier<int> {
  @override
  int build() => 0;

  void prompt() => state++;
}

final guestCityPromptProvider = NotifierProvider<GuestCityPrompt, int>(
  GuestCityPrompt.new,
);
