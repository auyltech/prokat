import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global one-shot signal to notify the app about an unauthorized (401) event.
///
/// Increment the value to emit a new event.
final unauthorizedSignalProvider = StateProvider<int>((_) => 0);
