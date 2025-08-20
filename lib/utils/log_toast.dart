import 'dart:ui';

import 'package:app_rhyme/utils/global_vars.dart';
import 'package:flutter/cupertino.dart';

void initFlutterLogger() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    globalTalker.error("[Flutter Error] $details");
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    globalTalker.error("[PlatForm Error] Error: $error\nStackTrace: $stack");
    return true;
  };
}

class LogToast {
  static void info(String toastTitle, String toastDesc, String log,
      {bool isLong = false}) {
    globalTalker.info(log);
  }

  static void success(String toastTitle, String toastDesc, String log,
      {bool isLong = false}) {
    globalTalker.info(log);
  }

  static void warning(String toastTitle, String toastDesc, String log,
      {bool isLong = false}) {
    globalTalker.warning(log);
  }

  static void error(String toastTitle, String toastDesc, String log,
      {bool isLong = false}) {
    globalTalker.error(log);
  }
}
