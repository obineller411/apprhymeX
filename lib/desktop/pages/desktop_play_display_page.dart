import 'dart:math';
import 'dart:ui';
import 'package:app_rhyme/desktop/comps/desktop_lyric_display.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/control_button.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/music_artpic.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/music_info.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/progress_slider.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/quality_time.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:app_rhyme/utils/color_extraction.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:get/get.dart';

class DesktopPlayDisplayPage extends StatefulWidget {
  const DesktopPlayDisplayPage({super.key});

  @override
  DesktopPlayDisplayPageState createState() => DesktopPlayDisplayPageState();
}

class DesktopPlayDisplayPageState extends State<DesktopPlayDisplayPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isDismissing = false;


  @override
  void initState() {
    super.initState();


    // 设置移动模式下的透明导航条
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setMobileTransparentNavigation();
    });

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();
    _slideController.forward();
  }

  // 设置移动模式下的透明导航条
  void _setMobileTransparentNavigation() {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _isDismissing = true;
    // 立即停止所有动画
    _fadeController.stop();
    _slideController.stop();
    // 异步dispose避免阻塞UI线程
    Future.microtask(() {
      _fadeController.dispose();
      _slideController.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bool isDarkMode = true;
    const animateBackgroundColor = CupertinoColors.white;
    const backgroundColor1 = Color.fromARGB(255, 56, 56, 56);
    const backgroundColor2 = Color.fromARGB(255, 31, 31, 31);


    return Obx(() {
      final backgroundGradient = globalAudioHandler.currentBackgroundGradient.value;

      return DismissiblePage(
        isFullScreen: true,
        direction: DismissiblePageDismissDirection.down,
        backgroundColor: animateBackgroundColor,
        onDismissed: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // Background with gradient
            Container(
              decoration: BoxDecoration(
                gradient: backgroundGradient,
              ),
            ),
            // Gaussian blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
              child: Container(
                color: Colors.black.withOpacity(0.1), // Slight tint
              ),
            ),
            // Foreground content
            Column(
              children: [
                // 主要内容区域 - 两栏设计
                Expanded(
                  child: Row(
                    children: [
                      // 左侧控制区域
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 音乐封面 - 使用固定约束减少动态计算
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 400.0,
                                    maxWidth: 400.0,
                                  ),
                                  child: const MusicArtPic(
                                    padding: EdgeInsets.only(left: 40.0, right: 40.0),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // 歌曲信息
                                const MusicInfo(
                                  titleHeight: 28,
                                  artistHeight: 22,
                                  padding: EdgeInsets.only(left: 40, right: 40),
                                ),

                                const SizedBox(height: 30),

                                // 进度条
                                const ProgressSlider(
                                  padding: EdgeInsets.only(left: 20, right: 20),
                                  isDarkMode: true,
                                ),

                                const SizedBox(height: 25),

                                // 音质切换
                                QualityTime(
                                  fontHeight: 16,
                                  padding: 25,
                                  enableQualityMenu: true,
                                ),

                                const SizedBox(height: 40),

                                // 上下首和暂停按钮 - 固定尺寸
                                const ControlButton(
                                  buttonSize: 50,
                                  buttonSpacing: 50,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 右侧歌词显示 - 使用优化后的区域
                      Expanded(
                        flex: 1,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 700),
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Obx(() {
                            final musicUniqueId =
                                '${globalAudioHandler.playingMusic.value?.info.name ?? ''}-${globalAudioHandler.playingMusic.value?.info.artist.join(',') ?? ''}';
                            return DesktopLyricDisplay(
                              key: ValueKey(musicUniqueId),
                              maxHeight: 700.0,
                              isDarkMode: true,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}