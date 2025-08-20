import 'dart:io';
import 'dart:developer' as developer;

import 'package:app_rhyme/mobile/pages/muti_select_pages/muti_select_local_music_list_gridview_page.dart';
import 'package:app_rhyme/mobile/pages/reorder_pages/reorder_local_music_list_grid_page.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:app_rhyme/utils/log_toast.dart';
import 'package:app_rhyme/mobile/comps/musiclist_comp/musiclist_image_card.dart';
import 'package:app_rhyme/dialogs/input_musiclist_sharelink_dialog.dart';
import 'package:app_rhyme/dialogs/musiclist_info_dialog.dart';
import 'package:app_rhyme/mobile/pages/local_music_container_listview_page.dart';
import 'package:app_rhyme/mobile/pages/online_music_list_page.dart';
import 'package:app_rhyme/src/rust/api/bind/factory_bind.dart';
import 'package:app_rhyme/src/rust/api/bind/mirrors.dart';
import 'package:app_rhyme/src/rust/api/bind/type_bind.dart';
import 'package:app_rhyme/utils/colors.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter/cupertino.dart';
import 'package:pull_down_button/pull_down_button.dart';

void Function() globalMobileMusicListGridPageRefreshFunction = () {};

class LocalMusicListGridPage extends StatefulWidget {
  const LocalMusicListGridPage({super.key});

  @override
  LocalMusicListGridPageState createState() => LocalMusicListGridPageState();
}

class LocalMusicListGridPageState extends State<LocalMusicListGridPage>
    with WidgetsBindingObserver {
  List<MusicListW> musicLists = [];

  @override
  void initState() {
    super.initState();
    globalMobileMusicListGridPageRefreshFunction = () {
      loadMusicLists();
    };
    loadMusicLists();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    globalMobileMusicListGridPageRefreshFunction = () {};
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  // Function to load music lists
  void loadMusicLists() async {
    try {
      developer.log('[歌单加载] 开始加载歌单列表', name: 'MusicListLoad');
      
      List<MusicListW> loadedLists = await SqlFactoryW.getAllMusiclists();
      developer.log('[歌单加载] 从数据库获取到 ${loadedLists.length} 个歌单', name: 'MusicListLoad');

      // 检查是否存在"我的收藏"歌单
      var favoriteMusicList =
          loadedLists.where((m) => m.getMusiclistInfo().name == "我的收藏");
      if (favoriteMusicList.isEmpty) {
        developer.log('[歌单加载] 未找到"我的收藏"歌单，开始创建', name: 'MusicListLoad');
        
        // 如果不存在，则创建
        await SqlFactoryW.createMusiclist(musicListInfos: [
          MusicListInfo(
            name: "我的收藏",
            artPic: "assets/log-0.1.0.png",
            desc: "我喜欢的音乐",
            id: PlatformInt64Util.from(0),
          )
        ]);
        developer.log('[歌单加载] "我的收藏"歌单创建成功', name: 'MusicListLoad');
        
        // 重新加载列表
        loadedLists = await SqlFactoryW.getAllMusiclists();
        developer.log('[歌单加载] 重新加载后获取到 ${loadedLists.length} 个歌单', name: 'MusicListLoad');
      } else {
        developer.log('[歌单加载] 找到"我的收藏"歌单', name: 'MusicListLoad');
      }

      // 将"我的收藏"歌单置顶
      var favorite =
          loadedLists.firstWhere((m) => m.getMusiclistInfo().name == "我的收藏");
      loadedLists.remove(favorite);
      loadedLists.insert(0, favorite);
      
      developer.log('[歌单加载] "我的收藏"歌单信息: name=${favorite.getMusiclistInfo().name}, artPic=${favorite.getMusiclistInfo().artPic}', name: 'MusicListLoad');
      developer.log('[歌单加载] 歌单列表处理完成，最终数量: ${loadedLists.length}', name: 'MusicListLoad');

      setState(() {
        musicLists = loadedLists;
      });
    } catch (e) {
      developer.log('[歌单加载] 加载歌单列表失败: $e', name: 'MusicListLoad');
      LogToast.error("加载歌单列表", "加载歌单列表失败: $e",
          "[loadMusicLists] Failed to load music lists: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;
    final Color textColor =
        isDarkMode ? CupertinoColors.white : CupertinoColors.black;
    final Color backgroundColor =
        isDarkMode ? CupertinoColors.black : CupertinoColors.white;

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: Column(children: [
        CupertinoNavigationBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 0.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '资料库',
                style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: textColor)
                    .useSystemChineseFont(),
              ),
            ),
          ),
          trailing: MusicListGridPageMenu(
            builder: (context, showMenu) => CupertinoButton(
                padding: const EdgeInsets.all(0),
                onPressed: showMenu,
                child: Text(
                  '选项',
                  style: TextStyle(color: activeIconRed).useSystemChineseFont(),
                )),
          ),
        ),
        Expanded(
            child: musicLists.isEmpty
                ? Center(
                    child: Text("没有歌单",
                        style:
                            TextStyle(color: textColor).useSystemChineseFont()))
                : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                            horizontal: Platform.isIOS ? 0.0 : 10.0),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              var musicList = musicLists[index];
                              return MusicListImageCard(
                                key: ValueKey(musicList.getMusiclistInfo().id),
                                musicListW: musicList,
                                online: false,
                                showDesc: false,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          LocalMusicContainerListPage(
                                        musicList: musicList,
                                      ),
                                    ),
                                  );
                                },
                                cachePic: globalConfig.savePicWhenAddMusicList,
                              );
                            },
                            childCount: musicLists.length,
                          ),
                        ),
                      ),
                    ],
                  ))
      ]),
    );
  }
}

@immutable
class MusicListGridPageMenu extends StatelessWidget {
  const MusicListGridPageMenu({
    super.key,
    required this.builder,
  });
  final PullDownMenuButtonBuilder builder;

  @override
  Widget build(BuildContext context) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          itemTheme: PullDownMenuItemTheme(
              textStyle: const TextStyle().useSystemChineseFont()),
          onTap: () async {
            if (context.mounted) {
              var musicListInfo = await showMusicListInfoDialog(context);
              if (musicListInfo != null) {
                try {
                  await SqlFactoryW.createMusiclist(
                      musicListInfos: [musicListInfo]);
                  globalMobileMusicListGridPageRefreshFunction();
                  LogToast.success("创建歌单", "创建歌单成功",
                      "[MusicListGridPageMenu] Successfully created music list");
                } catch (e) {
                  LogToast.error("创建歌单", "创建歌单失败: $e",
                      "[MusicListGridPageMenu] Failed to create music list: $e");
                }
              }
            }
          },
          title: '创建歌单',
          icon: CupertinoIcons.add,
        ),
        PullDownMenuItem(
          itemTheme: PullDownMenuItemTheme(
              textStyle: const TextStyle().useSystemChineseFont()),
          onTap: () async {
            var url = await showInputPlaylistShareLinkDialog(context);
            if (url != null) {
              var result =
                  await OnlineFactoryW.getMusiclistFromShare(shareUrl: url);
              var musicListW = result.$1;
              var musicAggregators = result.$2;
              if (context.mounted) {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                      builder: (context) => MobileOnlineMusicListPage(
                            musicList: musicListW,
                            firstPageMusicAggregators: musicAggregators,
                          )),
                );
              }
            }
          },
          title: '打开歌单链接',
          icon: CupertinoIcons.link,
        ),
        PullDownMenuItem(
          itemTheme: PullDownMenuItemTheme(
              textStyle: const TextStyle().useSystemChineseFont()),
          onTap: () async {
            var result = await SqlFactoryW.getAllMusiclists();
            var musicLists = result;
            if (context.mounted) {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => ReorderLocalMusicListGridPage(
                    musicLists: musicLists,
                  ),
                ),
              );
            }
          },
          title: '手动排序',
          icon: CupertinoIcons.list_number,
        ),
        PullDownMenuItem(
          itemTheme: PullDownMenuItemTheme(
              textStyle: const TextStyle().useSystemChineseFont()),
          onTap: () async {
            var result = await SqlFactoryW.getAllMusiclists();
            var musicLists = result;
            if (context.mounted) {
              Navigator.of(context).push(
                CupertinoPageRoute(
                    builder: (context) => MutiSelectLocalMusicListGridPage(
                        musicLists: musicLists)),
              );
            }
          },
          title: '多选操作',
          icon: CupertinoIcons.selection_pin_in_out,
        )
      ],
      animationBuilder: null,
      position: PullDownMenuPosition.automatic,
      buttonBuilder: builder,
    );
  }
}
