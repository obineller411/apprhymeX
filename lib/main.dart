import 'dart:developer' as developer;
import 'dart:io';

import 'package:app_rhyme/desktop/home.dart';
import 'package:app_rhyme/mobile/home.dart';
import 'package:app_rhyme/utils/chore.dart';
import 'package:app_rhyme/src/rust/api/types/config.dart';
import 'package:app_rhyme/utils/mobile_device.dart';
import 'package:app_rhyme/utils/miui_gesture_adapter.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:app_rhyme/audioControl/audio_controller.dart';
import 'package:app_rhyme/src/rust/frb_generated.dart';
import 'package:app_rhyme/src/rust/api/bind/factory_bind.dart';
import 'package:app_rhyme/utils/bypass_netimg_error.dart';
import 'package:app_rhyme/utils/desktop_device.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:app_rhyme/utils/network_stability_helper.dart';
import 'package:app_rhyme/utils/quality_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await initGlobalVars();
  await initBypassNetImgError();
  // initFlutterLogger();

  // 初始化数据库
  await initDatabase();
  
  await initGlobalAudioHandler();
  await initGlobalAudioUiController();
  
  // 初始化音质配置 - 等待所有全局变量初始化完成后再初始化音质配置
  globalTalker.info('[Main] 开始初始化音质配置');
  await QualityConfigManager.initQualities();
  globalTalker.info('[Main] 音质配置初始化完成');
  
  // 初始化默认音质配置
  await _initDefaultQualityConfig();
  
  runApp(const MyApp());
  await initDesktopWindowSetting();
}

// 初始化默认音质配置
Future<void> _initDefaultQualityConfig() async {
  try {
    globalTalker.info('[Main] 开始初始化默认音质配置');
    
    // 获取当前配置
    final config = await Config.load();
    
    // 获取可用的音质选项
    final qualities = QualityConfigManager.getQualities();
    
    // 如果音质配置为空，则设置默认值
    if (config.wifiAutoQuality.isEmpty && qualities.isNotEmpty) {
      // 选择最高音质作为WiFi默认值
      config.wifiAutoQuality = qualities.first.apiValue;
      globalTalker.info('[Main] 设置WiFi默认音质为: ${qualities.first.displayName}');
    }
    
    // 如果配置中仍然有旧的中文音质值，将其重置为API支持的值
    if (config.wifiAutoQuality == "最高" || config.wifiAutoQuality == "中等" || config.wifiAutoQuality == "低") {
      config.wifiAutoQuality = qualities.first.apiValue;
      globalTalker.info('[Main] 重置WiFi默认音质为: ${qualities.first.displayName}');
    }
    
    if (config.mobileAutoQuality == "最高" || config.mobileAutoQuality == "中等" || config.mobileAutoQuality == "低") {
      config.mobileAutoQuality = qualities.first.apiValue;
      globalTalker.info('[Main] 重置移动网络默认音质为: ${qualities.first.displayName}');
    }
    
    // 不再自动设置默认音质配置，保持用户手动选择
    
    // 保存配置
    await config.save();
    globalTalker.info('[Main] 默认音质配置初始化完成');
    
  } catch (e) {
    globalTalker.error('[Main] 初始化默认音质配置失败: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isWidthGreaterThanHeight = false;
  @override
  void initState() {
    super.initState();
    // 添加应用生命周期监听器
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initMobileDevice(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _isWidthGreaterThanHeight = isWidthGreaterThanHeight(context);
        return CupertinoApp(
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          theme: CupertinoThemeData(
            applyThemeToAll: true,
            textTheme: CupertinoTextThemeData(
              textStyle: const TextStyle(color: CupertinoColors.black)
                  .useSystemChineseFont(),
            ),
          ),
          home: MiuiGestureAdapterWrapper(
            immersive: false,
            backgroundColor: Colors.white,
            enableAdaptive: true,
            child: _isWidthGreaterThanHeight
                ? const DesktopHome()
                : const MobileHome(),
          ),
          // home:const MobileHome()
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // 应用进入后台
        BackgroundPlaybackHelper().markDidEnterBackground();
        break;
      case AppLifecycleState.resumed:
        // 应用回到前台
        BackgroundPlaybackHelper().markDidEnterForeground();
        break;
      case AppLifecycleState.detached:
        // 应用被终止
        BackgroundPlaybackHelper().dispose();
        break;
      case AppLifecycleState.inactive:
        // 应用处于非活动状态
        break;
      case AppLifecycleState.hidden:
        // 应用被隐藏
        break;
    }
  }

  @override
  void dispose() {
    // 移除应用生命周期监听器
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

// 初始化数据库
Future<void> initDatabase() async {
  try {
    developer.log('[数据库初始化] 开始初始化数据库', name: 'DatabaseInit');
    
    // 获取应用文档目录
    final directory = await getApplicationDocumentsDirectory();
    String dbPath;
    
    // 检查是否有自定义导出路径
    if (globalConfig.exportCacheRoot != null && globalConfig.exportCacheRoot!.isNotEmpty) {
      dbPath = "${globalConfig.exportCacheRoot}/MusicData.db";
    } else {
      // 创建 AppRhymeX 目录
      final appDir = Directory("${directory.path}/AppRhymeX");
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
        developer.log('[数据库初始化] 创建目录: ${appDir.path}', name: 'DatabaseInit');
      }
      dbPath = "${directory.path}/AppRhymeX/MusicData.db";
    }
    
    developer.log('[数据库初始化] 数据库路径: $dbPath', name: 'DatabaseInit');
    
    // 初始化数据库
    await SqlFactoryW.initFromPath(filepath: dbPath);
    developer.log('[数据库初始化] 数据库初始化成功', name: 'DatabaseInit');
  } catch (e) {
    developer.log('[数据库初始化] 数据库初始化失败: $e', name: 'DatabaseInit');
    
    // 如果初始化失败，使用默认路径
    try {
      final directory = await getApplicationDocumentsDirectory();
      // 创建 AppRhymeX 目录
      final appDir = Directory("${directory.path}/AppRhymeX");
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
        developer.log('[数据库初始化] 创建目录: ${appDir.path}', name: 'DatabaseInit');
      }
      await SqlFactoryW.initFromPath(filepath: "${directory.path}/AppRhymeX/MusicData.db");
      developer.log('[数据库初始化] 使用默认路径初始化成功', name: 'DatabaseInit');
    } catch (e2) {
      // 如果还是失败，抛出异常
      developer.log('[数据库初始化] 默认路径初始化失败: $e2', name: 'DatabaseInit');
      throw Exception("数据库初始化失败: $e2");
    }
  }
}
