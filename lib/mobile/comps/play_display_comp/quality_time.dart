import 'package:app_rhyme/src/rust/api/bind/mirrors.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:app_rhyme/mobile/comps/chores/badge.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:app_rhyme/utils/time_parser.dart';
import 'package:app_rhyme/utils/quality_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:pull_down_button/pull_down_button.dart';

class QualityTime extends StatefulWidget {
  final double padding;
  final double fontHeight;
  final bool enableQualityMenu;
  const QualityTime({super.key, this.padding = 20.0, required this.fontHeight, this.enableQualityMenu = true});

  @override
  State<StatefulWidget> createState() => QualityTimeState();
}

class QualityTimeState extends State<QualityTime> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: widget.padding, right: widget.padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() {
            return SizedBox(
                width: 60,
                child: Text(
                  formatDuration(
                      globalAudioUiController.position.value.inSeconds),
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: CupertinoColors.systemGrey6,
                    fontWeight: FontWeight.w300,
                    fontSize: widget.fontHeight,
                  ).useSystemChineseFont(),
                ),
              );
          }),
          // 音质信息按钮
          widget.enableQualityMenu
          ? GestureDetector(
              key: const ValueKey("quality_button"),
              onTapDown: (details) async {
                // 防止快速多次点击导致的冲突
                if (globalAudioUiController.isQualityMenuOpen.value) {
                  return;
                }
                List<Quality>? qualityOptions =
                    globalAudioHandler.playingMusic.value?.info.qualities;
                if (qualityOptions != null && qualityOptions.isNotEmpty) {
                  globalAudioUiController.isQualityMenuOpen.value = true;
                  await showPullDownMenu(
                      context: context,
                      items: qualitySelectPullDown(context, qualityOptions,
                          (selectQuality) async {
                        await globalAudioHandler
                            .replacePlayingMusic(selectQuality);
                      }),
                      position: details.globalPosition & Size.zero);
                  globalAudioUiController.isQualityMenuOpen.value = false;
                }
              },
              child: Obx(() {
                final currentQuality = globalAudioHandler.playingMusic.value?.currentQuality.value;
                final heroTag = "quality_badge_${currentQuality?.short ?? 'default'}";
                return Hero(
                  tag: heroTag,
                  child: Badge(
                    isDarkMode: true,
                    label: _getQualityDisplayName(currentQuality),
                  ),
                );
              }),
            )
          : Obx(() {
              final currentQuality = globalAudioHandler.playingMusic.value?.currentQuality.value;
              return Badge(
                isDarkMode: true,
                label: _getQualityDisplayName(currentQuality),
              );
            }),
          Obx(() {
            return SizedBox(
                width: 60,
                child: Text(
                  formatDuration(
                      globalAudioUiController.duration.value.inSeconds),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: CupertinoColors.systemGrey6,
                    fontWeight: FontWeight.w300,
                    fontSize: widget.fontHeight,
                  ).useSystemChineseFont(),
                ),
              );
          }),
        ],
      ),
    );
  }

  // 获取音质的友好显示名称
  String _getQualityDisplayName(Quality? quality) {
    if (quality == null) {
      return "Quality";
    }
    
    // 优先使用 short 名称，这是后端返回的音质名称
    if (quality.short.isNotEmpty && quality.short != "标准") {
      return quality.short;
    }
    
    // 尝试使用 QualityConfigManager 获取显示名称
    try {
      final musicQuality = QualityConfigManager.fromApiValue(quality.level);
      return musicQuality.displayName;
    } catch (e) {
      // 如果无法匹配，则使用原始的 short 名称
      return quality.short;
    }
  }
}

List<PullDownMenuEntry> qualitySelectPullDown(
        BuildContext context,
        List<Quality> qualitys,
        Future<void> Function(Quality selectQuality) onSelect) {
      // 获取当前播放的音质
      final currentQuality = globalAudioHandler.playingMusic.value?.currentQuality.value;
      
      // 动态从API获取音质选项
      final qualities = QualityConfigManager.getQualities();
      
      return [
        PullDownMenuTitle(
            title: Text(
          "切换音质",
          style: const TextStyle(color: CupertinoColors.black).useSystemChineseFont(),
        )),
        ...qualities.map(
          (qualityInfo) {
            final String qualityShort = qualityInfo.apiValue;
            final String displayName = qualityInfo.displayName;
            
            // 检查是否为当前播放的音质
            final bool isCurrentQuality = currentQuality?.level.toString() == qualityShort;
            
            return PullDownMenuItem(
                itemTheme: PullDownMenuItemTheme(
                  textStyle: TextStyle(
                    color: isCurrentQuality
                        ? CupertinoColors.activeBlue
                        : const Color(0xFF000000),
                  ).useSystemChineseFont(),
                ),
                title: isCurrentQuality
                    ? "$displayName ✓"
                    : displayName,
                onTap: () async {
                  // 找到对应的Quality对象
                  try {
                    final Quality targetQuality = qualitys.firstWhere((q) => q.level == qualityShort);
                    await onSelect(targetQuality);
                  } catch (e) {
                    // 如果找不到对应的Quality对象，创建一个新的Quality对象
                    final Quality newQuality = Quality(
                      short: qualityShort,
                      level: qualityShort,
                      // 其他必需的属性设为默认值
                    );
                    await onSelect(newQuality);
                  }
                });
          },
        )
      ];
    }
