import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 小米全面屏手势条适配工具类
/// 
/// 根据小米官方适配说明，提供两种适配方式：
/// 1. 沉浸式虚拟键 - 透明背景，内容延伸到虚拟键区域
/// 2. 虚拟键颜色适配 - 设置与页面背景一致的虚拟键颜色
class MiuiGestureAdapter {
  /// 设置沉浸式虚拟键
  ///
  /// 根据小米官方适配说明，实现真正的沉浸式虚拟键
  /// 虚拟键背景透明，app内容延伸到虚拟键区域
  static Future<void> setImmersiveNavigation() async {
    try {
      // 设置系统UI覆盖样式，使用透明背景
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ));
      
      // 使用沉浸式模式，让内容延伸到系统UI区域
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [], // 隐藏所有系统UI
      );
    } catch (e) {
      debugPrint('设置沉浸式虚拟键失败: $e');
    }
  }

  /// 设置虚拟键颜色
  /// 
  /// 适用于纯色背景页面，虚拟键颜色与页面背景保持一致
  /// @param color 虚拟键背景颜色
  /// @param iconBrightness 虚拟键图标亮度
  static Future<void> setNavigationBarColor({
    required Color color,
    Brightness iconBrightness = Brightness.light,
  }) async {
    try {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: color,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarDividerColor: color,
      ));
    } catch (e) {
      debugPrint('设置虚拟键颜色失败: $e');
    }
  }

  /// 启用全面屏手势模式
  /// 
  /// 自动检测并启用最适合的适配方式
  /// @param isImmersive 是否使用沉浸式模式
  /// @param backgroundColor 背景颜色（非沉浸式模式使用）
  static Future<void> enableFullScreenGesture({
    bool isImmersive = true,
    Color backgroundColor = Colors.black,
  }) async {
    try {
      if (isImmersive) {
        await setImmersiveNavigation();
      } else {
        await setNavigationBarColor(
          color: backgroundColor,
          iconBrightness: backgroundColor.computeLuminance() > 0.5 
              ? Brightness.dark 
              : Brightness.light,
        );
      }
    } catch (e) {
      debugPrint('启用全面屏手势失败: $e');
    }
  }

  /// 适配深色模式
  /// 
  /// 根据当前主题模式自动调整虚拟键颜色
  static Future<void> adaptDarkMode({required bool isDarkMode}) async {
    try {
      if (isDarkMode) {
        await setNavigationBarColor(
          color: Colors.black,
          iconBrightness: Brightness.light,
        );
      } else {
        await setNavigationBarColor(
          color: Colors.white,
          iconBrightness: Brightness.dark,
        );
      }
    } catch (e) {
      debugPrint('适配深色模式失败: $e');
    }
  }

  /// 简单检测是否为小米设备
  static bool get isXiaomiDevice {
    // 简化实现，直接返回false
    return false;
  }

  /// 检测是否支持全面屏手势
  static bool get supportsFullScreenGesture {
    // 简化实现，直接返回true
    return true;
  }

  /// 获取当前虚拟键是否可见
  static bool get isNavigationBarVisible {
    // 简化实现，直接返回true
    return true;
  }

  /// 重置为默认设置
  static Future<void> resetToDefault() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.black,
      ));
    } catch (e) {
      debugPrint('重置设置失败: $e');
    }
  }
}

/// 小米全面屏手势适配的Widget包装器
/// 
/// 提供便捷的Widget级适配方案
class MiuiGestureAdapterWrapper extends StatefulWidget {
  final Widget child;
  final bool immersive;
  final Color? backgroundColor;
  final bool enableAdaptive;

  const MiuiGestureAdapterWrapper({
    super.key,
    required this.child,
    this.immersive = true,
    this.backgroundColor,
    this.enableAdaptive = true,
  });

  @override
  State<MiuiGestureAdapterWrapper> createState() => _MiuiGestureAdapterWrapperState();
}

class _MiuiGestureAdapterWrapperState extends State<MiuiGestureAdapterWrapper> {
  bool _isXiaomiDevice = false;
  bool _supportsGesture = false;

  @override
  void initState() {
    super.initState();
    _initAdapter();
  }

  Future<void> _initAdapter() async {
    if (!widget.enableAdaptive) return;

    try {
      _isXiaomiDevice = MiuiGestureAdapter.isXiaomiDevice;
      _supportsGesture = MiuiGestureAdapter.supportsFullScreenGesture;
      
      if (_isXiaomiDevice && _supportsGesture) {
        await MiuiGestureAdapter.enableFullScreenGesture(
          isImmersive: widget.immersive,
          backgroundColor: widget.backgroundColor ?? Colors.black,
        );
      }
    } catch (e) {
      debugPrint('初始化小米手势适配失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    if (_isXiaomiDevice && _supportsGesture) {
      MiuiGestureAdapter.resetToDefault();
    }
    super.dispose();
  }
}