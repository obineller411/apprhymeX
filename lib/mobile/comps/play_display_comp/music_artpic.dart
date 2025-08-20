import 'dart:io';
import 'package:app_rhyme/utils/cache_helper.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class MusicArtPic extends StatefulWidget {
  final EdgeInsets padding;
  const MusicArtPic({
    super.key,
    required this.padding,
  });

  @override
  State<StatefulWidget> createState() => MusicArtPicState();
}

class MusicArtPicState extends State<MusicArtPic> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Obx(() => Container(
            padding: widget.padding,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.0),
                boxShadow: [
                  BoxShadow(
                    color: Platform.isIOS
                        ? CupertinoColors.black.withValues(alpha: 0.2)
                        : CupertinoColors.black.withValues(alpha: 0.4),
                    spreadRadius: Platform.isIOS ? 3 : 8,
                    blurRadius: Platform.isIOS ? 3 : 8,
                  )
                ],
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: imageCacheHelper(
                  globalAudioHandler.playingMusic.value?.info.artPic,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover),
              ),
            ))));
  }
}
