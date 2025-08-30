import 'package:app_rhyme/mobile/comps/play_display_comp/lyric.dart';
import 'package:app_rhyme/types/lyric_ui.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:app_rhyme/utils/time_parser.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:get/get.dart';

class DesktopLyricDisplay extends StatefulWidget {
  final double maxHeight;
  final bool isDarkMode;
  const DesktopLyricDisplay({
    super.key,
    required this.maxHeight,
    required this.isDarkMode,
  });

  @override
  DesktopLyricDisplayState createState() => DesktopLyricDisplayState();
}

class DesktopLyricDisplayState extends State<DesktopLyricDisplay> {
  late LyricUI lyricUI;
  var lyricModel =
      LyricsModelBuilder.create().bindLyricToMain("[00:00.00]无歌词").getModel();
  bool showTranslation = false;

  int _clampPosition(int position) {
    try {
      if (position < 0 || position > 24 * 60 * 60 * 1000) {
        return 0;
      }
      return position;
    } catch (e) {
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    lyricUI = AppleMusicLyricUi();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var musicInfo = globalAudioHandler.playingMusic.value?.info;
      var lyric = musicInfo?.lyric ?? "[00:00.00]无歌词";
      var tlyric = musicInfo?.tlyric;

      var builder = LyricsModelBuilder.create().bindLyricToMain(lyric);
      if (showTranslation && tlyric != null && tlyric.isNotEmpty) {
        builder = builder.bindLyricToExt(tlyric);
      }
      var currentLyricModel = builder.getModel();

      return Column(
        children: [
          SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: const EdgeInsets.only(left: 9.5, right: 9.5),
                onPressed: () {
                  setState(() {
                    showTranslation = !showTranslation;
                  });
                },
                child: Icon(
                  showTranslation
                      ? CupertinoIcons.captions_bubble_fill
                      : CupertinoIcons.captions_bubble,
                  color: CupertinoColors.white,
                  size: 25,
                ),
              ),
            ),
          ),
          Expanded(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.4, 0.6, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: StreamBuilder<Duration>(
                stream: globalAudioUiController.position.stream,
                builder: (context, snapshot) {
                  return LyricsReader(
                    playing: globalAudioHandler.playingMusic.value != null,
                    emptyBuilder: () => Center(
                      child: Text(
                        "No lyrics",
                        style: lyricUI
                            .getOtherMainTextStyle()
                            .useSystemChineseFont(),
                      ),
                    ),
                    model: currentLyricModel,
                    position: _clampPosition(snapshot.data?.inMilliseconds ?? 0),
                    lyricUi: lyricUI,
                    size: Size(double.infinity, widget.maxHeight - 40),
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    selectLineBuilder: (progress, confirm) {
                      return Row(
                        children: [
                          IconButton(
                              onPressed: () {
                                var toSeek = Duration(milliseconds: progress);
                                globalAudioHandler.seek(toSeek).then((value) {
                                  confirm.call();
                                  if (!globalAudioHandler.isPlaying) {
                                    globalAudioHandler.play();
                                  }
                                });
                              },
                              icon: const Icon(Icons.play_arrow,
                                  color: CupertinoColors.white)),
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: CupertinoColors.white),
                              height: 1,
                              width: double.infinity,
                            ),
                          ),
                          Text(
                            formatDuration(
                                Duration(milliseconds: progress).inSeconds),
                            style: const TextStyle(color: CupertinoColors.white)
                                .useSystemChineseFont(),
                          )
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}
