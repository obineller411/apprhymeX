import 'dart:async';
import 'package:app_rhyme/types/lyric_ui.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:app_rhyme/types/music_container.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:app_rhyme/utils/time_parser.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:get/get.dart';

class LyricDisplay extends StatefulWidget {
  final double maxHeight;
  final bool isDarkMode;
  const LyricDisplay(
      {super.key, required this.maxHeight, required this.isDarkMode});

  @override
  LyricDisplayState createState() => LyricDisplayState();
}

class LyricDisplayState extends State<LyricDisplay> {
  late LyricUI lyricUI;
  var lyricModel =
      LyricsModelBuilder.create().bindLyricToMain("[00:00.00]无歌词").getModel();
  late StreamSubscription<MusicContainer?> stream;
  bool showTranslation = false;

  @override
  void initState() {
    super.initState();
    lyricUI = AppleMusicLyricUi();
    updateLyricModel();
    stream = globalAudioHandler.playingMusic.listen((p0) {
      setState(() {
        updateLyricModel();
      });
    });
  }

  void updateLyricModel() {
    var musicInfo = globalAudioHandler.playingMusic.value?.info;
    var lyric = musicInfo?.lyric ?? "[00:00.00]无歌词";
    var tlyric = musicInfo?.tlyric;

    var builder = LyricsModelBuilder.create().bindLyricToMain(lyric);
    if (showTranslation && tlyric != null && tlyric.isNotEmpty) {
      builder = builder.bindLyricToExt(tlyric);
    }
    lyricModel = builder.getModel();
  }

  @override
  void dispose() {
    stream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  updateLyricModel();
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
        Obx(() => LyricsReader(
              playing: globalAudioHandler.playingMusic.value != null,
              emptyBuilder: () => Center(
                child: Text(
                  "No lyrics",
                  style: lyricUI.getOtherMainTextStyle().useSystemChineseFont(),
                ),
              ),
              model: lyricModel,
              position: globalAudioUiController.position.value.inMilliseconds,
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
                            // 这里是考虑到在暂停状态下。需要开启播放
                            if (!globalAudioHandler.isPlaying) {
                              globalAudioHandler.play();
                            }
                          });
                        },
                        icon: const Icon(Icons.play_arrow,
                            color: CupertinoColors.white)),
                    Expanded(
                      child: Container(
                        decoration:
                            const BoxDecoration(color: CupertinoColors.white),
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
            )),
      ],
    );
  }
}

