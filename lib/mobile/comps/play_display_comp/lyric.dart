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
// import 'package:flutter_lyric/lyrics_reader_model.dart'; // 移除或注释掉这行

class LyricDisplay extends StatefulWidget {
  const LyricDisplay({
    super.key,
  });

  @override
  State<LyricDisplay> createState() => _LyricDisplayState();
}

class _LyricDisplayState extends State<LyricDisplay> {
  late LyricUI lyricUI;
  final Rx<ValueKey> lyricKey = Rx(const ValueKey(null));
  final RxBool showTranslation = RxBool(false);
  final Rx currentLyricModel = Rx(LyricsModelBuilder.create().getModel()); // 移除类型参数

  @override
  void initState() {
    super.initState();
    lyricUI = AppleMusicLyricUi();
    // 监听音乐变化以更新歌词模型
    ever(globalAudioHandler.playingMusic, (MusicContainer? music) {
      _updateLyricModel(music);
    });
    // 初始设置歌词模型
    _updateLyricModel(globalAudioHandler.playingMusic.value);
  }

  void _updateLyricModel(MusicContainer? music) {
    final lyric = music?.info.lyric;
    final tlyric = music?.info.tlyric;

    if (lyricKey.value.value != lyric) {
      lyricKey.value = ValueKey(lyric);
    }

    if (lyric == null) {
      currentLyricModel.value = LyricsModelBuilder.create().getModel();
      return;
    }

    var builder = LyricsModelBuilder.create().bindLyricToMain(lyric);
    if (showTranslation.value && tlyric != null && tlyric.isNotEmpty) {
      builder = builder.bindLyricToExt(tlyric);
    }
    currentLyricModel.value = builder.getModel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Align(
            alignment: Alignment.centerRight,
            child: Obx(() => CupertinoButton(
              padding: const EdgeInsets.only(left: 9.5, right: 9.5),
              onPressed: () {
                showTranslation.value = !showTranslation.value;
                _updateLyricModel(globalAudioHandler.playingMusic.value); // 翻译切换时更新歌词模型
              },
              child: Icon(
                showTranslation.value
                    ? CupertinoIcons.captions_bubble_fill
                    : CupertinoIcons.captions_bubble,
                color: CupertinoColors.white,
                size: 25,
              ),
            )),
          ),
        ),
        Expanded(
          child: StreamBuilder<Duration>(
            stream: globalAudioUiController.position.stream,
            builder: (context, snapshot) {
              return Obx(() {
                final position = snapshot.data?.inMilliseconds ?? 0;
                final lyric = globalAudioHandler.playingMusic.value?.info.lyric;

                if (lyric == null) {
                  return Center(
                    child: Text(
                      "No lyrics",
                      style: lyricUI
                          .getOtherMainTextStyle()
                          .useSystemChineseFont(),
                    ),
                  );
                }
                
                return ShaderMask(
                  key: lyricKey.value,
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white,
                        Colors.white,
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.4, 0.6, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: LyricsReader(
                    playing: globalAudioHandler.playingMusic.value != null,
                    model: currentLyricModel.value,
                    position: position,
                    lyricUi: lyricUI,
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
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}
