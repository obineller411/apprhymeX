import 'dart:async';
import 'dart:math';
import 'package:app_rhyme/desktop/comps/popup_comp/playlist.dart';
import 'package:app_rhyme/desktop/pages/desktop_play_display_page.dart';
import 'package:app_rhyme/desktop/utils/colors.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/bottom_button.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/control_button.dart' as mobile;
import 'package:app_rhyme/mobile/comps/play_display_comp/lyric.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/music_artpic.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/music_info.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/music_list.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/playing_music_card.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/progress_slider.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/quality_time.dart';
import 'package:app_rhyme/mobile/comps/play_display_comp/volume_slider.dart' as mobile;
import 'package:app_rhyme/utils/cache_helper.dart';
import 'package:app_rhyme/utils/chore.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:app_rhyme/utils/time_parser.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:interactive_slider/interactive_slider.dart';


class ControlBar extends StatefulWidget {
  const ControlBar({
    super.key,
  });

  @override
  ControlBarState createState() => ControlBarState();
}

class ControlBarState extends State<ControlBar> {

  @override
  Widget build(BuildContext context) {
    Brightness brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    Color backgroundColor = isDarkMode
        ? const Color.fromARGB(255, 42, 42, 42)
        : const Color.fromARGB(255, 247, 247, 247);
    Color dividerColor = getDividerColor(isDarkMode);
    bool isDesktop_ = isDesktop();
    

    final childWidget = GestureDetector(
      onPanStart: (details) {
        if (isDesktop_) {
          appWindow.startDragging();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(
              color: dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // 控制栏
            Container(
              height: 75,
              child: Row(
                children: [
                  // 左侧：封面
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const DesktopPlayDisplayPage(),
                            fullscreenDialog: true,
                            settings: const RouteSettings(name: 'desktop_play_display_page'),
                            maintainState: true,
                            allowSnapshotting: false,
                          ),
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 30, 30, 35),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Obx(() => ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: imageCacheHelper(
                              globalAudioHandler.playingMusic.value?.info.artPic),
                        )),
                      ),
                    ),
                  ),
                  
                  // 中间：歌曲信息和进度条
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 第一行：歌曲名称和歌手（垂直排列）
                        Row(
                          children: [
                            // 歌曲名称和歌手列
                            SizedBox(
                              width: 120, // 调整flex比例，进一步缩短
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 歌曲名称
                                  Obx(() => Text(
                                        globalAudioHandler.playingMusic.value?.info.name ?? "Music",
                                        style: TextStyle(
                                          color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ).useSystemChineseFont(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                  
                                  const SizedBox(height: 1),
                                  
                                  // 歌手（缩短显示）
                                  Obx(() => Text(
                                        globalAudioHandler.playingMusic.value?.info.artist.join(", ") ?? "Artist",
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? const Color.fromARGB(255, 142, 142, 142)
                                              : const Color.fromARGB(255, 129, 129, 129),
                                          fontSize: 12,
                                        ).useSystemChineseFont(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                ],
                              ),
                            ),
                            
                            // 控制按钮
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ControlButton(
                                  buttonSize: 20, // 按钮尺寸
                                  buttonSpacing: 2, //按钮间距
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // 第二行：进度条
                        Obx(() => Row(
                              children: [
                                Text(
                                  formatDuration(globalAudioUiController.position.value.inSeconds),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? const Color.fromARGB(255, 142, 142, 142)
                                        : const Color.fromARGB(255, 129, 129, 129),
                                    fontSize: 10,
                                  ).useSystemChineseFont(),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? const Color.fromARGB(255, 102, 102, 102)
                                          : const Color.fromARGB(255, 206, 206, 206),
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: (globalAudioUiController.playProgress.value.isNaN ||
                                                   globalAudioUiController.playProgress.value < 0)
                                          ? 0.0
                                          : globalAudioUiController.playProgress.value.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? const Color.fromARGB(255, 221, 221, 221)
                                              : const Color.fromARGB(255, 103, 103, 103),
                                          borderRadius: BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatDuration(globalAudioUiController.duration.value.inSeconds),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? const Color.fromARGB(255, 142, 142, 142)
                                        : const Color.fromARGB(255, 129, 129, 129),
                                    fontSize: 10,
                                  ).useSystemChineseFont(),
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                  
                  // 右侧：列表按钮
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: FunctionButtons(
                            buttonSize: 20,
                            buttonSpacing: 10,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return isDesktop_ ? WindowTitleBarBox(child: childWidget) : childWidget;
  }

}

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key, required this.isDarkMode});
  final bool isDarkMode;

  @override
  WindowButtonsState createState() => WindowButtonsState();
}

class WindowButtonsState extends State<WindowButtons> {
  @override
  Widget build(BuildContext context) {
    Brightness brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    Color buttonColor = isDarkMode
        ? const Color.fromARGB(255, 222, 222, 222)
        : const Color.fromARGB(255, 38, 38, 38);
    bool isMaximized = appWindow.isMaximized;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.minus,
              color: buttonColor,
              size: 20,
            ),
            onPressed: () {
              appWindow.minimize();
            },
          ),
        ),
        SizedBox(
          width: 40,
          height: 40,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            child: isMaximized
                ? Icon(
                    CupertinoIcons.fullscreen_exit,
                    color: buttonColor,
                    size: 20,
                  )
                : Icon(
                    CupertinoIcons.fullscreen,
                    color: buttonColor,
                    size: 20,
                  ),
            onPressed: () {
              appWindow.maximizeOrRestore();
              setState(() {
                isMaximized = appWindow.isMaximized;
              });
            },
          ),
        ),
        SizedBox(
          width: 40,
          height: 40,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.clear,
              color: buttonColor,
              size: 20,
            ),
            onPressed: () {
              appWindow.close();
            },
          ),
        ),
      ],
    );
  }
}

class PlayDisplayCard extends StatefulWidget {
  const PlayDisplayCard({super.key, required this.isDarkMode});
  final bool isDarkMode;

  @override
  PlayDisplayCardState createState() => PlayDisplayCardState();
}

class PlayDisplayCardState extends State<PlayDisplayCard> {
  final ValueNotifier<bool> _isDragging = ValueNotifier<bool>(false);
  final InteractiveSliderController _progressController =
      InteractiveSliderController(0);
  late StreamSubscription<double> listen1;

  @override
  void initState() {
    super.initState();
    listen1 = globalAudioUiController.playProgress.listen((p0) {
      if (!_isDragging.value) {
        if (!p0.isNaN) {
          try {
            _progressController.value = p0;
          } catch (e) {
            if (e.toString().contains("disposed")) {
              listen1.cancel();
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    listen1.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black;
    final Color textColor2 = widget.isDarkMode
        ? const Color.fromARGB(255, 142, 142, 142)
        : const Color.fromARGB(255, 129, 129, 129);
    final Color backgroundColor = widget.isDarkMode
        ? const Color.fromARGB(255, 57, 57, 57)
        : const Color.fromARGB(255, 249, 249, 249);
    final Color sliderBackgroundColor = widget.isDarkMode
        ? const Color.fromARGB(255, 102, 102, 102)
        : const Color.fromARGB(255, 206, 206, 206);
    final Color sliderForegroundColor = widget.isDarkMode
        ? const Color.fromARGB(255, 221, 221, 221)
        : const Color.fromARGB(255, 103, 103, 103);
    final Color borderColor = widget.isDarkMode
        ? const Color.fromARGB(255, 30, 30, 35)
        : const Color.fromARGB(255, 230, 230, 230);

    return GestureDetector(
      onTap: () {
        // 使用手机版的导航方式，完全覆盖屏幕
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => const DesktopPlayDisplayPage(),
            fullscreenDialog: true,
            settings: const RouteSettings(name: 'desktop_play_display_page'),
            maintainState: true,
            allowSnapshotting: false,
          ),
        );
      },
      onPanStart: (details) {},
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 30, 30, 35),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Obx(() => ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: imageCacheHelper(
                          globalAudioHandler.playingMusic.value?.info.artPic),
                    )),
              ),
              SizedBox(
                width: 300,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Center(
                          child: Obx(() => Text(
                                globalAudioHandler
                                        .playingMusic.value?.info.name ??
                                    "Music",
                                style: TextStyle(color: textColor, fontSize: 12)
                                    .useSystemChineseFont(),
                              )),
                        ),
                        Center(
                          child: Obx(() => Text(
                                globalAudioHandler
                                        .playingMusic.value?.info.artist
                                        .join(", ") ??
                                    "Artist",
                                style:
                                    TextStyle(color: textColor2, fontSize: 11)
                                        .useSystemChineseFont(),
                              )),
                        ),
                        const SizedBox(height: 2),
                        Expanded(child: Container()),
                      ],
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Obx(() => Text(
                                  formatDuration(globalAudioUiController
                                      .position.value.inSeconds),
                                  style:
                                      TextStyle(color: textColor2, fontSize: 11)
                                          .useSystemChineseFont(),
                                )),
                            Obx(() => Text(
                                  formatDuration(globalAudioUiController
                                      .duration.value.inSeconds),
                                  style:
                                      TextStyle(color: textColor2, fontSize: 11)
                                          .useSystemChineseFont(),
                                )),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      left: 0,
                      right: 0,
                      child: InteractiveSlider(
                        controller: _progressController,
                        backgroundColor: sliderBackgroundColor,
                        foregroundColor: sliderForegroundColor,
                        focusedMargin: const EdgeInsets.all(0),
                        unfocusedMargin: const EdgeInsets.all(0),
                        focusedHeight: 5,
                        unfocusedHeight: 3,
                        padding: const EdgeInsets.all(0),
                        isDragging: _isDragging,
                        onProgressUpdated: (value) {
                          var toSeek = globalAudioUiController.getToSeek(value);
                          globalTalker.info(
                              "[Slider] Call seek to ${formatDuration(toSeek.inSeconds)}");
                          globalAudioHandler.seek(toSeek);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ControlButton extends StatefulWidget {
  final double buttonSize;
  final double buttonSpacing;
  final bool isDarkMode;

  const ControlButton({
    super.key,
    required this.buttonSize,
    required this.buttonSpacing,
    required this.isDarkMode,
  });

  @override
  State<StatefulWidget> createState() => ControlButtonState();
}

class ControlButtonState extends State<ControlButton> {
  @override
  Widget build(BuildContext context) {
    Color buttonColor = widget.isDarkMode
        ? const Color.fromARGB(255, 222, 222, 222)
        : const Color.fromARGB(255, 38, 38, 38);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CupertinoButton(
          padding: EdgeInsets.zero, // 移除默认padding
          child: Icon(CupertinoIcons.backward_fill,
              color: buttonColor, size: widget.buttonSize),
          onPressed: () {
            globalAudioHandler.seekToPrevious();
          },
        ),
        SizedBox(width: widget.buttonSpacing), // 使用SizedBox控制间距
        Obx(() {
          if (globalAudioUiController.playerState.value.playing) {
            return CupertinoButton(
              padding: EdgeInsets.zero, // 移除默认padding
              child: Icon(CupertinoIcons.pause_solid,
                  color: buttonColor, size: widget.buttonSize),
              onPressed: () {
                globalAudioHandler.pause();
              },
            );
          } else {
            return CupertinoButton(
              padding: EdgeInsets.zero, // 移除默认padding
              child: Icon(CupertinoIcons.play_arrow_solid,
                  color: buttonColor, size: widget.buttonSize),
              onPressed: () {
                globalAudioHandler.play();
              },
            );
          }
        }),
        SizedBox(width: widget.buttonSpacing), // 使用SizedBox控制间距
        CupertinoButton(
          padding: EdgeInsets.zero, // 移除默认padding
          child: Icon(CupertinoIcons.forward_fill,
              color: buttonColor, size: widget.buttonSize),
          onPressed: () {
            globalAudioHandler.seekToNext();
          },
        ),
      ],
    );
  }
}

class FunctionButtons extends StatelessWidget {
  const FunctionButtons({
    super.key,
    required this.buttonSize,
    required this.buttonSpacing,
    required this.isDarkMode,
  });
  final double buttonSize;
  final double buttonSpacing;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    Color buttonColor = isDarkMode
        ? const Color.fromARGB(255, 222, 222, 222)
        : const Color.fromARGB(255, 38, 38, 38);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            showPlaylistPopup(context, isDarkMode);
          },
          child: Icon(
            CupertinoIcons.list_bullet,
            color: buttonColor,
            size: buttonSize,
          ),
        ),
      ],
    );
  }
}
