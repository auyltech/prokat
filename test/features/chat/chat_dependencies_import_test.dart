import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/chat/providers/chat_dependencies.dart'
    as dependencies;
import 'package:prokat/features/chat/providers/chat_providers.dart'
    as providers;

void main() {
  test('chat service providers have a single provider identity', () {
    expect(
      identical(
        dependencies.chatServiceProvider,
        providers.chatServiceProvider,
      ),
      isTrue,
    );
    expect(
      identical(
        dependencies.chatSocketServiceProvider,
        providers.chatSocketServiceProvider,
      ),
      isTrue,
    );
  });
}
