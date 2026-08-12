import 'package:flutter/foundation.dart';

class Logger {
  static void log(Object message) {
    if (kDebugMode) {
      debugPrint(message.toString());
    }
  }
}
