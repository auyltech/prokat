import 'dart:io';
import 'package:flutter/foundation.dart';

enum RunMode { remote, local }

const RunMode runMode = RunMode.remote;

class Env {
  static String get baseUrl {
    if (kReleaseMode) {
      return "https://prokatbackend.onrender.com";
    }

    if (runMode == RunMode.local) {
      if (kIsWeb) {
        return "http://localhost:4000";
      }
      if (Platform.isAndroid) {
        return "http://10.0.2.2:4000";
      }
      if (Platform.isIOS || Platform.isMacOS) {
        return "http://localhost:4000";
      }
    }

    // Default fallback for physical devices or remote selection
    return "https://prokatbackend.onrender.com";
  }

  /// Converts the HTTP base URL into a WebSocket counterpart and enforces TLS on remote connections.
  static String get websocketUrl {
    final base = baseUrl;
    if (base.startsWith("https://")) {
      return base.replaceFirst("https://", "wss://");
    } else if (base.startsWith("http://")) {
      return base.replaceFirst("http://", "ws://");
    }
    return base;
  }
}
