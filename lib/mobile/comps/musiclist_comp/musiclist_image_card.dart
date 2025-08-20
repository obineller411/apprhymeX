import 'package:app_rhyme/mobile/comps/chores/badge.dart';
import 'package:app_rhyme/pulldown_menus/musiclist_pulldown_menu.dart';
import 'package:app_rhyme/src/rust/api/bind/mirrors.dart';
import 'package:app_rhyme/src/rust/api/bind/type_bind.dart';
import 'package:app_rhyme/utils/colors.dart';
import 'package:app_rhyme/utils/source_helper.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:app_rhyme/utils/cache_helper.dart';

class MusicListImageCard extends StatelessWidget {
  final MusicListW musicListW;
  final bool online;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final bool cachePic;
  final bool showDesc;
  const MusicListImageCard(
      {super.key,
      required this.musicListW,
      required this.online,
      this.onTap,
      this.onLongPress,
      this.cachePic = false,
      this.showDesc = true});

  @override
  Widget build(BuildContext context) {
    MusicListInfo musicListInfo = musicListW.getMusiclistInfo();
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;
    final Color textCOlor =
        isDarkMode ? CupertinoColors.white : CupertinoColors.black;
    Widget cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: imageCacheHelper(
                  musicListInfo.artPic,
                  cacheNow: cachePic,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 3,
              left: 3,
              child: Badge(
                label: sourceToShort(musicListW.source()),
                isDarkMode: isDarkMode,
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTapDown: (details) {
                  Rect position = Rect.fromLTWH(details.globalPosition.dx,
                      details.globalPosition.dy, 0, 0);
                  showMusicListMenu(context, musicListW, online, position);
                },
                child: Icon(
                  CupertinoIcons.ellipsis_circle,
                  color: isDarkMode ? CupertinoColors.white : activeIconRed,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: Center(
            child: Text(
              musicListInfo.name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textCOlor, fontSize: 16)
                  .useSystemChineseFont(),
              maxLines: 2,
            ),
          ),
        ),
        if (showDesc) const SizedBox(height: 4),
        if (showDesc)
          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                musicListInfo.desc,
                style: TextStyle(
                  color: isDarkMode
                      ? CupertinoColors.systemGrey4
                      : CupertinoColors.systemGrey,
                  fontSize: 12,
                ).useSystemChineseFont(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return onTap != null
              ? GestureDetector(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  child: cardContent,
                )
              : cardContent;
        },
      ),
    );
  }
}
