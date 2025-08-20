import 'dart:async';
import 'dart:io';

import 'package:app_rhyme/src/rust/api/bind/mirrors.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:app_rhyme/utils/cache_helper.dart';
import 'package:app_rhyme/utils/const_vars.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

Future<MusicInfo?> showMusicInfoDialog(BuildContext context,
    {MusicInfo? defaultMusicInfo, bool readonly = false, String? neteaseMusicId}) async {
  return showCupertinoDialog<MusicInfo>(
    context: context,
    builder: (BuildContext context) =>
        MusicInfoDialog(defaultMusicInfo: defaultMusicInfo, readonly: readonly, neteaseMusicId: neteaseMusicId),
  );
}

class MusicInfoDialog extends StatefulWidget {
  final MusicInfo? defaultMusicInfo;
  final bool readonly;
  final String? neteaseMusicId;

  const MusicInfoDialog(
      {super.key, this.defaultMusicInfo, this.readonly = false, this.neteaseMusicId});

  @override
  MusicInfoDialogState createState() => MusicInfoDialogState();
}

class MusicInfoDialogState extends State<MusicInfoDialog> {
  late TextEditingController nameController;
  late TextEditingController artistController;
  late TextEditingController albumController;
  late TextEditingController durationController;
  late ExtendedImage image;
  late String artPicPath;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.defaultMusicInfo?.name ?? '');
    artistController = TextEditingController(
        text: widget.defaultMusicInfo?.artist.join(', ') ?? '');
    albumController =
        TextEditingController(text: widget.defaultMusicInfo?.album ?? '');
    durationController = TextEditingController(
        text: widget.defaultMusicInfo?.duration?.toString() ?? '');
    if (widget.defaultMusicInfo != null) {
      image = imageCacheHelper(widget.defaultMusicInfo!.artPic);
    } else {
      image = ExtendedImage.asset(defaultArtPicPath);
    }
    artPicPath = widget.defaultMusicInfo?.artPic ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;

    String title;
    if (widget.readonly) {
      title = '音乐详情';
    } else if (widget.defaultMusicInfo != null) {
      title = "编辑音乐";
    } else {
      title = '创建音乐';
    }

    return CupertinoAlertDialog(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
        ).useSystemChineseFont(),
      ),
      content: SizedBox(
        width: 280, // 固定对话框宽度
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            GestureDetector(
              onTap: widget.readonly
                  ? null
                  : () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? imageFile =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (imageFile != null) {
                        setState(() {
                          artPicPath = imageFile.path;
                          image = ExtendedImage.file(File(artPicPath));
                          cacheFileHelper(imageFile.path, picCacheRoot);
                        });
                      }
                    },
              child: Container(
                width: 120, // 固定宽高
                height: 120, // 固定宽高
                decoration: BoxDecoration(
                  border: Border.all(
                    color: CupertinoColors.systemGrey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: image,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 240, // 固定输入框宽度
              child: CupertinoTextField(
                controller: nameController,
                placeholder: '音乐名字',
                readOnly: widget.readonly,
                style: TextStyle(
                  color:
                      isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                ),
                placeholderStyle: TextStyle(
                  color: isDarkMode
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 240, // 固定输入框宽度
              child: CupertinoTextField(
                controller: artistController,
                placeholder: '艺术家(多个用逗号分隔)',
                readOnly: widget.readonly,
                maxLines: widget.readonly ? 3 : 1, // 限制最大行数
                style: TextStyle(
                  color:
                      isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                ),
                placeholderStyle: TextStyle(
                  color: isDarkMode
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 240, // 固定输入框宽度
              child: CupertinoTextField(
                controller: albumController,
                placeholder: '专辑',
                readOnly: widget.readonly,
                maxLines: widget.readonly ? 3 : 1, // 限制最大行数
                style: TextStyle(
                  color:
                      isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                ),
                placeholderStyle: TextStyle(
                  color: isDarkMode
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.neteaseMusicId != null)
              SizedBox(
                width: 240, // 固定输入框宽度
                child: Text(
                  '网易云ID: ${widget.neteaseMusicId}',
                  style: TextStyle(
                    color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                  ).useSystemChineseFont(),
                ),
              ),
            const SizedBox(height: 12),
            ],
          ),
        ),
      actions: <CupertinoDialogAction>[
        if (!widget.readonly)
          CupertinoDialogAction(
            child: Text(
              '取消',
              style: TextStyle(
                color: isDarkMode
                    ? CupertinoColors.systemGrey2
                    : CupertinoColors.activeBlue,
              ).useSystemChineseFont(),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        if (!widget.readonly)
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.of(context).pop(MusicInfo(
                  name: nameController.text,
                  artist: artistController.text
                      .split(',')
                      .map((e) => e.trim())
                      .toList(),
                  duration: int.tryParse(durationController.text),
                  album: albumController.text,
                  artPic: artPicPath,
                  id: 0,
                  source: '',
                  qualities: [],
                ));
              }
            },
            child: Text(
              '完成',
              style: TextStyle(
                color: isDarkMode
                    ? CupertinoColors.systemGrey2
                    : CupertinoColors.activeBlue,
              ).useSystemChineseFont(),
            ),
          ),
        if (widget.readonly)
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              '关闭',
              style: TextStyle(
                color: isDarkMode
                    ? CupertinoColors.systemGrey2
                    : CupertinoColors.activeBlue,
              ).useSystemChineseFont(),
            ),
          ),
      ],
    );
  }
}
