import 'dart:io';
import 'package:flutter/foundation.dart';

const String runMode = "remote";

class Env {
  static String get baseUrl {
    if (kReleaseMode) {
      return "https://prokatbackend.onrender.com";
    }

    if (runMode == "remote") {
      return "https://prokatbackend.onrender.com";
    }

    if (kIsWeb) {
      return "http://localhost:4000";
    }

    if (Platform.isAndroid) {
      return "http://10.0.2.2:4000";
    }

    return "http://localhost:4000";
  }
}
