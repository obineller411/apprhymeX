import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

Future<void> initDesktopWindowSetting() async {
  // 初始化桌面窗口设置，仅在桌面平台运行
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    doWhenWindowReady(() {
      appWindow
        ..size = const Size(900, 600)
        ..minSize = const Size(800, 500)
        ..alignment = Alignment.center
        ..show();
    });
  }
}
