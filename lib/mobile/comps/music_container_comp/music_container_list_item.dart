import 'package:app_rhyme/pulldown_menus/music_container_pulldown_menu.dart';
import 'package:app_rhyme/src/rust/api/bind/type_bind.dart';
import 'package:app_rhyme/types/music_container.dart';
import 'package:app_rhyme/utils/cache_helper.dart';
import 'package:app_rhyme/utils/colors.dart';
import 'package:app_rhyme/utils/global_vars.dart';
// import 'package:app_rhyme/utils/source_helper.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

// 有三种使用场景: 1. 本地歌单的歌曲 2. 在线的歌曲 3. 播放列表
// 区分:
// 1. 本地歌单的歌曲: musicListW != null && index == -1
// 2. 在线的歌曲: musicListW == null && index == -1
// 3. 播放列表的歌曲: musicListW == null && index != -1

class MusicContainerListItem extends StatefulWidget {
  final MusicContainer musicContainer;
  final MusicListW? musicListW;
  final bool? isDark;
  final GestureTapCallback? onTap;
  final bool cachePic;
  final bool showMenu;
  final int index;

  const MusicContainerListItem({
    super.key,
    required this.musicContainer,
    this.musicListW,
    this.isDark,
    this.onTap,
    this.cachePic = false,
    this.showMenu = true,
    this.index = -1,
  });

  @override
  _MusicContainerListItemState createState() => _MusicContainerListItemState();
}

class _MusicContainerListItemState extends State<MusicContainerListItem> with AutomaticKeepAliveClientMixin {
  bool? _hasCache;

  @override
  void initState() {
    super.initState();
    // 禁用延迟缓存检查，避免快速滑动时的内存泄漏
    // Future.delayed(const Duration(milliseconds: 100), _checkCache);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 禁用缓存检查，避免快速滑动时的内存泄漏
    // if (_hasCache == null) {
    //   _checkCache();
    // }
    // 获取当前主题的亮度
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = widget.isDark ?? (brightness == Brightness.dark);
    return CupertinoButton(
      key: Key('cupertino_button_${widget.musicContainer.info.id}_${widget.musicContainer.info.source}_${widget.index}'),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 14),
      onPressed: widget.onTap ??
          () {
            globalAudioHandler.addMusicPlay(widget.musicContainer);
          },
      child: Row(
        key: ValueKey("row_${widget.musicContainer.info.id}_${widget.musicContainer.info.source}_${widget.index}"),
        children: <Widget>[
          // 歌曲的封面
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: imageCacheHelper(
              widget.musicContainer.info.artPic,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              cacheNow: widget.cachePic,
            ),
          ),
          // 歌曲的信息(歌名, 歌手)
          Expanded(
            key: Key('expanded_${widget.musicContainer.info.id}_${widget.musicContainer.info.source}_${widget.index}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GestureDetector(
                key: Key('gesture_detector_${widget.musicContainer.info.id}_${widget.musicContainer.info.source}_${widget.index}'),
                onLongPress: () async {
                  // 构建要复制的文本：歌曲名称 - 歌手
                  String copyText = '${widget.musicContainer.info.name} - ${widget.musicContainer.info.artist.join(", ")}';
                  
                  // 复制到剪贴板
                  await Clipboard.setData(ClipboardData(text: copyText));
                  
                  // 显示复制成功提示
                  if (context.mounted) {
                    showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CupertinoAlertDialog(
                          title: const Text("复制成功"),
                          content: Text("已复制歌曲信息: $copyText"),
                          actions: <Widget>[
                            CupertinoDialogAction(
                              child: const Text("确定"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      key: Key('song_name_${widget.musicContainer.info.id}_${widget.musicContainer.info.source}_${widget.index}'),
                      widget.musicContainer.info.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? CupertinoColors.systemGrey5
                            : CupertinoColors.black,
                        overflow: TextOverflow.ellipsis,
                      ).useSystemChineseFont(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      key: Key('artist_name_${widget.musicContainer.info.id}_${widget.musicContainer.info.source}_${widget.index}'),
                      widget.musicContainer.info.artist.join(", "),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? CupertinoColors.systemGrey4
                            : CupertinoColors.inactiveGray,
                        overflow: TextOverflow.ellipsis,
                      ).useSystemChineseFont(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 缓存标志
          if (widget.musicListW != null && widget.index == -1)
            _hasCache == null
                ? const Padding(
                    key: Key('cache_padding_empty'),
                    padding: EdgeInsets.all(0),
                  )
                : _hasCache!
                    ? const Padding(
                        key: Key('cache_padding_downloaded'),
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(CupertinoIcons.arrow_down_circle_fill,
                            color: CupertinoColors.systemGrey2))
                    : const SizedBox.shrink(),
          // 具有误导性，暂时不显示
          // // 标志音乐信息来源的Badge
          // Badge(
          //   label: sourceToShort(widget.musicContainer.info.source),
          // ),
          // 歌曲的操作按钮
          if (widget.showMenu)
            GestureDetector(
              key: Key('menu_gesture_${widget.musicContainer.info.id}_${widget.musicContainer.info.source}_${widget.index}'),
              onTapDown: (details) {
                // 防止快速多次点击导致的冲突
                if (globalAudioUiController.isQualityMenuOpen.value) {
                  return;
                }
                Rect position = Rect.fromPoints(
                  details.globalPosition,
                  details.globalPosition,
                );
                // 为播放页的下拉菜单添加Hero动画避免策略
                showMusicContainerMenu(
                  context,
                  widget.musicContainer,
                  false,
                  position,
                  musicList: widget.musicListW,
                  index: widget.index,
                );
              },
              child: Container(
                key: ValueKey("menu_${widget.musicContainer.info.id}_${widget.musicContainer.info.source}_${widget.index}"),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDarkMode
                      ? CupertinoColors.systemGrey5.withOpacity(0.3)
                      : CupertinoColors.systemGrey6.withOpacity(0.5),
                ),
                child: Icon(
                  key: Key('menu_icon_${widget.musicContainer.info.id}_${widget.musicContainer.info.source}_${widget.index}'),
                  CupertinoIcons.ellipsis,
                  color: activeIconRed,
                  size: 20,
                ),
              ),
            )
        ],
      ),
    );
  }
}
