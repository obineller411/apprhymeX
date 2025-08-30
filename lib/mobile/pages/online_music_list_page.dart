import 'package:app_rhyme/mobile/comps/chores/button.dart';
import 'package:app_rhyme/mobile/pages/muti_select_pages/muti_select_music_container_listview_page.dart';
import 'package:app_rhyme/utils/cache_helper.dart';
import 'package:app_rhyme/utils/log_toast.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:app_rhyme/mobile/comps/music_container_comp/music_container_list_item.dart';
import 'package:app_rhyme/mobile/comps/musiclist_comp/musiclist_image_card.dart';
import 'package:app_rhyme/pulldown_menus/musiclist_pulldown_menu.dart';
import 'package:app_rhyme/src/rust/api/bind/mirrors.dart';
import 'package:app_rhyme/src/rust/api/bind/type_bind.dart';
import 'package:app_rhyme/types/music_container.dart';
import 'package:app_rhyme/utils/chore.dart';
import 'package:app_rhyme/utils/colors.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_down_button/pull_down_button.dart';

class MobileOnlineMusicListPage extends StatefulWidget {
  final MusicListW musicList;
  final List<MusicAggregatorW>? firstPageMusicAggregators;

  const MobileOnlineMusicListPage(
      {super.key, required this.musicList, this.firstPageMusicAggregators});

  @override
  MobileOnlineMusicListPageState createState() =>
      MobileOnlineMusicListPageState();
}

class MobileOnlineMusicListPageState extends State<MobileOnlineMusicListPage> {
  final PagingController<int, MusicAggregatorW> _pagingController =
      PagingController(firstPageKey: 1);
  late MusicListInfo musicListInfo;
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    musicListInfo = widget.musicList.getMusiclistInfo();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchMusicAggregators(pageKey);
    });
    if (widget.firstPageMusicAggregators != null) {
      _pagingController.appendPage(
        widget.firstPageMusicAggregators!,
        2,
      );
    }
  }

  Future<void> _fetchAllMusics() async {
    setState(() {
      _isLoading = true; // Set loading to true when starting fetch
    });
    await Future.delayed(Duration.zero); // Yield control to the UI to show loading indicator
    LogToast.info("加载所有音乐", "正在加载所有音乐,请稍等",
        "[OnlineMusicListPage] MultiSelect wait to fetch all music aggregators");
    try {
      while (_pagingController.nextPageKey != null) {
        await _fetchMusicAggregators(_pagingController.nextPageKey!);
      }
      LogToast.success("加载所有音乐", '已加载所有音乐',
          "[OnlineMusicListPage] Succeed to fetch all music aggregators");
    } catch (e) {
      LogToast.error("加载所有音乐", "加载所有音乐失败: $e",
          "[OnlineMusicListPage] Failed to fetch all music aggregators: $e");
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false when fetch completes or errors
      });
    }
  }

  Future<void> _fetchMusicAggregators(int pageKey) async {
    try {
      var aggs =
          await widget.musicList.getMusicAggregators(page: pageKey, limit: 30);
      if (aggs.isEmpty) {
        _pagingController.appendLastPage([]);
      } else {
        _pagingController.appendPage(
          aggs,
          pageKey + 1,
        );
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;
    final textColor = brightness == Brightness.dark
        ? CupertinoColors.white
        : CupertinoColors.black;
    final Color dividerColor = isDarkMode
        ? const Color.fromARGB(255, 41, 41, 43)
        : const Color.fromARGB(255, 245, 245, 246);
    double screenWidth = MediaQuery.of(context).size.width;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
          padding: const EdgeInsetsDirectional.only(end: 16),
          leading: CupertinoButton(
            padding: const EdgeInsets.all(0),
            child: Icon(CupertinoIcons.back, color: activeIconRed),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          trailing: OnlineMusicListChoicMenu(
            builder: (context, showMenu) => GestureDetector(
              child: Text(
                '选项',
                style: TextStyle(color: activeIconRed).useSystemChineseFont(),
              ),
              onTapDown: (details) {
                showMenu();
              },
            ),
            musicListW: widget.musicList,
            musicAggregatorsController: _pagingController,
            fetchAllMusicAggregators: _fetchAllMusics,
          )),
      child: CustomScrollView(
        slivers: <Widget>[
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CupertinoActivityIndicator(radius: 20.0),
              ),
            )
          else ...[
            // 歌单封面
            SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.only(
                      top: screenWidth * 0.1,
                      left: screenWidth * 0.1,
                      right: screenWidth * 0.1),
                  child: SafeArea(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth * 0.7,
                      ),
                      child: MusicListImageCard(
                          musicListW: widget.musicList, online: true),
                    ),
                  )),
            ),
            // Two buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildButton(
                      context,
                      icon: CupertinoIcons.play_fill,
                      label: '播放全部',
                      onPressed: () async {
                        await _fetchAllMusics();
                        if (_pagingController.itemList != null &&
                            _pagingController.itemList!.isNotEmpty) {
                          setState(() {
                            _isLoading = true;
                          });
                          await Future.delayed(Duration.zero);
                          try {
                            globalAudioHandler.clearReplaceMusicAll(
                                _pagingController.itemList!
                                    .map((a) => MusicContainer(a))
                                    .toList());
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                    ),
                    buildButton(
                      context,
                      icon: Icons.shuffle,
                      label: '随机播放',
                      onPressed: () async {
                        await _fetchAllMusics();
                        if (_pagingController.itemList != null &&
                            _pagingController.itemList!.isNotEmpty) {
                          setState(() {
                            _isLoading = true;
                          });
                          await Future.delayed(Duration.zero);
                          try {
                            await globalAudioHandler.clearReplaceMusicAll(
                                shuffleList(_pagingController.itemList!)
                                    .map((a) => MusicContainer(a))
                                    .toList());
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: SizedBox(
                  width: screenWidth * 0.85,
                  child: Divider(
                    color: dividerColor,
                    height: 0.5,
                  ),
                ),
              ),
            ),
            PagedSliverList.separated(
              pagingController: _pagingController,
              separatorBuilder: (context, index) => Center(
                child: SizedBox(
                  width: screenWidth * 0.85,
                  child: Divider(
                    color: dividerColor,
                    height: 0.5,
                  ),
                ),
              ),
              builderDelegate: PagedChildBuilderDelegate<MusicAggregatorW>(
                  noItemsFoundIndicatorBuilder: (context) {
                    return Center(
                      child: Text(
                        '没有找到任何音乐',
                        style: TextStyle(color: textColor).useSystemChineseFont(),
                      ),
                    );
                  },
                  itemBuilder: (context, musicAggregator, index) => Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 5),
                        child: MusicContainerListItem(
                          key: ValueKey('online_${musicAggregator.hashCode}_$index'),
                          musicContainer: MusicContainer(musicAggregator),
                        ),
                      ),
                  // 优化分页列表性能
                  animateTransitions: true,
                  transitionDuration: const Duration(milliseconds: 300),
                ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 200),
              ),
            ),
          ],
          ],
      ),
    );
  }
}

@immutable
class OnlineMusicListChoicMenu extends StatelessWidget {
  const OnlineMusicListChoicMenu({
    super.key,
    required this.builder,
    required this.musicListW,
    required this.fetchAllMusicAggregators,
    required this.musicAggregatorsController,
  });
  final PagingController<int, MusicAggregatorW> musicAggregatorsController;
  final PullDownMenuButtonBuilder builder;
  final MusicListW musicListW;
  final Future<void> Function() fetchAllMusicAggregators;

  @override
  Widget build(BuildContext context) {
    MusicListInfo musicListInfo = musicListW.getMusiclistInfo();

    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuHeader(
          itemTheme: PullDownMenuItemTheme(
              textStyle: const TextStyle().useSystemChineseFont()),
          leading: imageCacheHelper(musicListInfo.artPic),
          title: musicListInfo.name,
          subtitle: musicListInfo.desc,
        ),
        const PullDownMenuDivider.large(),
        ...onlineMusicListItems(context, musicListW),
        PullDownMenuItem(
          itemTheme: PullDownMenuItemTheme(
              textStyle: const TextStyle().useSystemChineseFont()),
          onTap: fetchAllMusicAggregators,
          title: "加载所有音乐",
          icon: CupertinoIcons.music_note_2,
        ),
        PullDownMenuItem(
          itemTheme: PullDownMenuItemTheme(
              textStyle: const TextStyle().useSystemChineseFont()),
          onTap: () async {
            LogToast.info("多选操作", "正在加载所有音乐,请稍等",
                "[OnlineMusicListPage] MultiSelect wait to fetch all music aggregators");
            await fetchAllMusicAggregators();
            if (musicAggregatorsController.itemList == null) return;

            List<MusicContainer> musicContainers = musicAggregatorsController
                .itemList!
                .map((a) => MusicContainer(a))
                .toList();
            if (context.mounted) {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => MutiSelectMusicContainerListPage(
                      musicContainers: musicContainers),
                ),
              );
            }
          },
          title: "多选操作",
          icon: CupertinoIcons.selection_pin_in_out,
        )
      ],
      animationBuilder: null,
      position: PullDownMenuPosition.automatic,
      buttonBuilder: builder,
    );
  }
}
