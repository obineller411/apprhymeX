import 'package:app_rhyme/desktop/comps/control_bar.dart';
import 'package:app_rhyme/desktop/comps/navigation_column.dart';
import 'package:app_rhyme/desktop/pages/local_music_list_gridview_page.dart';
import 'package:app_rhyme/dialogs/user_aggrement_dialog.dart';
import 'package:app_rhyme/utils/check_update.dart';
import 'package:app_rhyme/utils/chore.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/cupertino.dart';

late BuildContext globalDesktopPageContext;
GlobalKey globalDesktopNavigatorKey = GlobalKey();

// 顶部窗口控制按钮组件
class WindowButtonsRow extends StatelessWidget {
  const WindowButtonsRow({super.key});

  @override
  Widget build(BuildContext context) {
    Brightness brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    Color buttonColor = isDarkMode
        ? const Color.fromARGB(255, 222, 222, 222)
        : const Color.fromARGB(255, 38, 38, 38);

    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.minus,
              color: buttonColor,
              size: 16,
            ),
            onPressed: () {
              appWindow.minimize();
            },
          ),
        ),
        SizedBox(
          width: 40,
          height: 40,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.fullscreen,
              color: buttonColor,
              size: 16,
            ),
            onPressed: () {
              appWindow.maximizeOrRestore();
            },
          ),
        ),
        SizedBox(
          width: 40,
          height: 40,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.clear,
              color: buttonColor,
              size: 16,
            ),
            onPressed: () {
              appWindow.close();
            },
          ),
        ),
      ],
    );
  }
}

class DesktopHome extends StatefulWidget {
  const DesktopHome({super.key});

  @override
  _DesktopHomeState createState() => _DesktopHomeState();
}

class _DesktopHomeState extends State<DesktopHome> {
  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showUserAgreement(context);
      if (mounted) {
        await autoCheckUpdate(context);
      }
    });
  }

  @override
  void dispose() {
    BackButtonInterceptor.removeAll();
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (!mounted) return true;

    if (Navigator.of(globalDesktopPageContext).canPop()) {
      Navigator.of(globalDesktopPageContext).pop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            if (isDesktop())
              GestureDetector(
                onPanStart: (details) {
                  appWindow.startDragging();
                },
                child: Container(
                  height: 40,
                  color: MediaQuery.of(context).platformBrightness == Brightness.dark
                      ? const Color.fromARGB(255, 42, 42, 42)
                      : const Color.fromARGB(255, 247, 247, 247),
                  child: Row(
                    children: [
                      const Expanded(child: SizedBox()), // 添加 Expanded 来占据空间
                      const WindowButtonsRow(),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  const MyNavListContainer(),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Navigator(
                            key: globalDesktopNavigatorKey,
                            onGenerateRoute: (RouteSettings settings) {
                              return CupertinoPageRoute(
                                builder: (context) {
                                  globalDesktopPageContext = context;
                                  return const DesktopLocalMusicListGridPage();
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 80,
                          child: ControlBar(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
