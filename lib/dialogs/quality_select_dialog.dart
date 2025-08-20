import 'package:app_rhyme/utils/quality_picker.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/cupertino.dart';

// 音质选择对话框，基于动态音质配置
Future<MusicQualityInfo?> showQualitySelectDialog(BuildContext context) async {
  final Brightness brightness = MediaQuery.of(context).platformBrightness;
  final bool isDarkMode = brightness == Brightness.dark;

  return await showCupertinoModalPopup<MusicQualityInfo>(
    context: context,
    builder: (BuildContext context) {
      final qualities = QualityConfigManager.getQualities();
      
      return CupertinoActionSheet(
        title: Text(
          '选择音质',
          style: TextStyle(
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ).useSystemChineseFont(),
        ),
        actions: <Widget>[
          // 为每个可用的音质创建一个选项
          for (final quality in qualities)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context, quality);
              },
              child: Text(
                quality.displayName,
                style: TextStyle(
                  color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                ).useSystemChineseFont(),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context, null); // null when cancelled
          },
          child: Text(
            '取消',
            style: TextStyle(
              color: isDarkMode
                  ? CupertinoColors.systemGrey2
                  : CupertinoColors.activeBlue,
            ).useSystemChineseFont(),
          ),
        ),
      );
    },
  );
}

