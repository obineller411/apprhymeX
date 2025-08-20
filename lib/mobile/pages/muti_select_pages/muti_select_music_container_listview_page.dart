import 'package:app_rhyme/src/rust/api/bind/factory_bind.dart';
import 'package:app_rhyme/src/rust/api/bind/mirrors.dart';

import 'package:app_rhyme/utils/cache_helper.dart';
import 'package:app_rhyme/utils/log_toast.dart';
import 'package:app_rhyme/utils/music_api_helper.dart';
import 'package:app_rhyme/utils/refresh.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:app_rhyme/mobile/comps/music_container_comp/music_container_list_item.dart';
import 'package:app_rhyme/src/rust/api/bind/type_bind.dart';
import 'package:app_rhyme/types/music_container.dart';
import 'package:app_rhyme/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:pull_down_button/pull_down_button.dart';

class MutiSelectMusicContainerListPage extends StatefulWidget {
  final List<MusicContainer> musicContainers;
  final MusicListW? musicList;

  const MutiSelectMusicContainerListPage({
    super.key,
    this.musicList,
    required this.musicContainers,
  });

  @override
  MutiSelectMusicContainerListPageState createState() =>
      MutiSelectMusicContainerListPageState();
}

class MutiSelectMusicContainerListPageState
    extends State<MutiSelectMusicContainerListPage>
    with WidgetsBindingObserver {
  DragSelectGridViewController controller = DragSelectGridViewController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  void handleDeleteSelected() {
    setState(() {
      widget.musicContainers.removeWhere((element) => controller
          .value.selectedIndexes
          .contains(widget.musicContainers.indexOf(element)));
      controller.clear();
    });
  }

  void handleRefresh() {
    setState(() {});
  }

  void handleSelectAll() {
    Set<int> selectAllSet =
        Set.from(List.generate(widget.musicContainers.length, (i) => i));
    setState(() {
      controller.clear();
      controller.dispose();
      controller = DragSelectGridViewController(Selection(selectAllSet));
      controller.addListener(
        () => setState(() {}),
      );
    });
  }

  void handleCancelSelectAll() {
    setState(() {
      controller.clear();
    });
  }

  void handleReverseSelect() {
    Set<int> selectAllSet = Set.from(List.generate(
        widget.musicContainers.length, (i) => i,
        growable: false));
    selectAllSet.removeAll(controller.value.selectedIndexes);
    setState(() {
      controller.clear();
      controller.dispose();
      controller = DragSelectGridViewController(Selection(selectAllSet));
      controller.addListener(
        () => setState(() {}),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;
    final Color backgroundColor =
        isDarkMode ? CupertinoColors.black : CupertinoColors.white;
    final Color dividerColor = isDarkMode
        ? const Color.fromARGB(255, 41, 41, 43)
        : const Color.fromARGB(255, 245, 245, 246);
    double screenWidth = MediaQuery.of(context).size.width;

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: Column(children: [
        CupertinoNavigationBar(
          padding: const EdgeInsetsDirectional.only(end: 16),
          backgroundColor: backgroundColor,
          leading: CupertinoButton(
            padding: const EdgeInsets.all(0),
            child: Icon(CupertinoIcons.back, color: activeIconRed),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          trailing: MutiSelectLocalMusicContainerListChoiceMenu(
            delSelected: handleDeleteSelected,
            refresh: handleRefresh,
            builder: (context, showMenu) => CupertinoButton(
              padding: const EdgeInsets.all(0),
              onPressed: showMenu,
              child: Text(
                '选项',
                style: TextStyle(color: activeIconRed).useSystemChineseFont(),
              ),
            ),
            musicListW: widget.musicList,
            musicContainers: controller.value.selectedIndexes
                .map((index) => widget.musicContainers[index])
                .toList(),
            cancelSelectAll: handleCancelSelectAll,
            selectAll: handleSelectAll,
            reverseSelect: handleReverseSelect,
          ),
        ),
        Expanded(
            child: widget.musicContainers.isEmpty
                ? Center(
                    child: Text(
                      "没有音乐",
                      style: TextStyle(
                              color: isDarkMode
                                  ? CupertinoColors.white
                                  : CupertinoColors.black)
                          .useSystemChineseFont(),
                    ),
                  )
                : Align(
                    key: ValueKey(controller.hashCode),
                    alignment: Alignment.topCenter,
                    child: DragSelectGridView(
                      gridController: controller,
                      padding: const EdgeInsets.only(
                          bottom: 100, top: 10, left: 10, right: 10),
                      itemCount: widget.musicContainers.length,
                      triggerSelectionOnTap: true,
                      itemBuilder: (context, index, selected) {
                        final musicContainer = widget.musicContainers[index];
                        return Column(
                          children: [
                            Row(
                              key: ValueKey(
                                  "${selected}_${musicContainer.info.id}"),
                              children: [
                                Expanded(
                                  child: MusicContainerListItem(
                                    showMenu: false,
                                    musicContainer: musicContainer,
                                    musicListW: widget.musicList,
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? CupertinoIcons.check_mark_circled
                                      : CupertinoIcons.circle,
                                  color: selected
                                      ? CupertinoColors.systemGreen
                                      : CupertinoColors.systemGrey4,
                                ),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.only(top: 10)),
                            SizedBox(
                              width: screenWidth * 0.85,
                              child: Divider(
                                color: dividerColor,
                                height: 0.5,
                              ),
                            )
                          ],
                        );
                      },
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 0,
                        childAspectRatio: 6,
                      ),
                    ),
                  ))
      ]),
    );
  }
}

@immutable
class MutiSelectLocalMusicContainerListChoiceMenu extends StatelessWidget {
  const MutiSelectLocalMusicContainerListChoiceMenu({
    super.key,
    required this.builder,
    required this.musicListW,
    required this.musicContainers,
    required this.refresh,
    required this.cancelSelectAll,
    required this.selectAll,
    required this.delSelected,
    required this.reverseSelect,
  });

  final PullDownMenuButtonBuilder builder;
  final MusicListW? musicListW;
  final List<MusicContainer> musicContainers;
  final void Function() refresh;
  final void Function() cancelSelectAll;
  final void Function() selectAll;
  final void Function() delSelected;
  final void Function() reverseSelect;

  Future<void> handleCacheSelected() async {
    for (var musicContainer in musicContainers) {
      await cacheMusic(musicContainer);
      refresh();
    }
    LogToast.success("缓存选中音乐", "缓存选中音乐成功",
        "[MutiSelectLocalMusicContainerListChoiceMenu] Successfully cached selected music");
  }

  Future<void> handleDeleteCacheSelected() async {
    for (var musicContainer in musicContainers) {
      await delMusicCache(musicContainer, showToast: false);
      refresh();
    }
    LogToast.success("删除选中音乐缓存", "删除选中音乐缓存成功",
        "[MutiSelectLocalMusicContainerListChoiceMenu] Successfully deleted selected music caches");
  }

  Future<void> handleDeleteFromList() async {
    if (musicListW != null) {
      MusicListInfo musicListInfo = musicListW!.getMusiclistInfo();
      SqlFactoryW.delMusics(
        musicListName: musicListInfo.name,
        ids: Int64List.fromList(musicContainers.map((e) => e.info.id).toList()),
      );
      refreshMusicContainerListViewPage();
      delSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<PullDownMenuEntry> menuItems = [
      if (musicListW != null) ...[
        PullDownMenuHeader(
          itemTheme: PullDownMenuItemTheme(
              textStyle: const TextStyle().useSystemChineseFont()),
          leading: imageCacheHelper(musicListW!.getMusiclistInfo().artPic),
          title: musicListW!.getMusiclistInfo().name,
          subtitle: musicListW!.getMusiclistInfo().desc,
        ),
        const PullDownMenuDivider.large(),
        PullDownMenuItem(
          itemTheme: PullDownMenuItemTheme(
              textStyle: const TextStyle().useSystemChineseFont()),
          onTap: handleCacheSelected,
          title: '缓存选中音乐',
          icon: CupertinoIcons.cloud_download,
        ),
        PullDownMenuItem(
          itemTheme: PullDownMenuItemTheme(
              textStyle: const TextStyle().useSystemChineseFont()),
          onTap: handleDeleteCacheSelected,
          title: '删除音乐缓存',
          icon: CupertinoIcons.delete,
        ),
        PullDownMenuItem(
          itemTheme: PullDownMenuItemTheme(
              textStyle: const TextStyle().useSystemChineseFont()),
          onTap: handleDeleteFromList,
          title: '从歌单删除',
          icon: CupertinoIcons.trash,
        ),
      ],
      PullDownMenuItem(
        itemTheme: PullDownMenuItemTheme(
            textStyle: const TextStyle().useSystemChineseFont()),
        onTap: () async {
          await addMusicsToMusicList(context, musicContainers);
        },
        title: '添加到歌单',
        icon: CupertinoIcons.add,
      ),
      PullDownMenuItem(
        itemTheme: PullDownMenuItemTheme(
            textStyle: const TextStyle().useSystemChineseFont()),
        onTap: () async {
          await createNewMusicListFromMusics(context, musicContainers);
        },
        title: '创建新歌单',
        icon: CupertinoIcons.add_circled,
      ),
      PullDownMenuItem(
        itemTheme: PullDownMenuItemTheme(
            textStyle: const TextStyle().useSystemChineseFont()),
        onTap: selectAll,
        title: '全部选中',
        icon: CupertinoIcons.checkmark_seal_fill,
      ),
      PullDownMenuItem(
        itemTheme: PullDownMenuItemTheme(
            textStyle: const TextStyle().useSystemChineseFont()),
        onTap: cancelSelectAll,
        title: '取消选中',
        icon: CupertinoIcons.xmark,
      ),
      PullDownMenuItem(
        itemTheme: PullDownMenuItemTheme(
            textStyle: const TextStyle().useSystemChineseFont()),
        onTap: reverseSelect,
        title: '反选',
        icon: CupertinoIcons.arrow_swap,
      ),
    ];

    return PullDownButton(
      itemBuilder: (context) => menuItems,
      animationBuilder: null,
      position: PullDownMenuPosition.automatic,
      buttonBuilder: builder,
    );
  }
}
