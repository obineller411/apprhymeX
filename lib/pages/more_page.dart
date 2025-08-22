import 'dart:async';
import 'dart:io';

import 'package:app_rhyme/dialogs/confirm_dialog.dart';
import 'package:app_rhyme/dialogs/quality_select_dialog.dart';
import 'package:app_rhyme/dialogs/wait_dialog.dart';
import 'package:app_rhyme/utils/api_status_checker.dart';
import 'package:app_rhyme/src/rust/api/bind/factory_bind.dart';
import 'package:app_rhyme/src/rust/api/cache/fs_util.dart';
import 'package:app_rhyme/utils/cache_helper.dart';
import 'package:app_rhyme/utils/check_update.dart';
import 'package:app_rhyme/utils/chore.dart';
import 'package:app_rhyme/utils/colors.dart';
import 'package:app_rhyme/utils/const_vars.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:app_rhyme/utils/log_toast.dart';
import 'package:app_rhyme/utils/quality_picker.dart';
import 'package:app_rhyme/utils/refresh.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  MorePageState createState() => MorePageState();
}

class MorePageState extends State<MorePage> with WidgetsBindingObserver {
  final RxBool _forceDesktopMode = false.obs;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 初始化桌面模式设置
    _initDesktopModeSetting();
  }
  
  // 初始化桌面模式设置
  void _initDesktopModeSetting() {
    final storedMode = GetStorage().read('forceDesktopMode');
    if (storedMode != null) {
      _forceDesktopMode.value = storedMode;
    }
  }
  
  refresh() {
    setState(() {});
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final textColor = brightness == Brightness.dark
        ? CupertinoColors.white
        : CupertinoColors.black;
    final iconColor = brightness == Brightness.dark
        ? CupertinoColors.white
        : CupertinoColors.black;
    final backgroundColor = brightness == Brightness.dark
        ? CupertinoColors.systemGrey6
        : CupertinoColors.systemGroupedBackground;
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: backgroundColor,
        leading: Padding(
          padding: const EdgeInsets.only(left: 0.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '设置',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: textColor,
              ).useSystemChineseFont(),
            ),
          ),
        ),
      ),
      child: ListView(
        children: [
          CupertinoFormSection.insetGrouped(
            header: Text('应用信息',
                style: TextStyle(color: textColor).useSystemChineseFont()),
            children: [
              CupertinoFormRow(
                  prefix: SizedBox(
                      height: 60,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: imageCacheHelper(""),
                      )),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          'AppRhymeX',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20.0,
                          ).useSystemChineseFont(),
                        ),
                      ))),
              CupertinoFormRow(
                  prefix: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Text(
                        '版本号',
                        style:
                            TextStyle(color: textColor).useSystemChineseFont(),
                      )),
                  child: Container(
                      padding: const EdgeInsets.only(right: 10),
                      alignment: Alignment.centerRight,
                      height: 40,
                      child: Text(
                        globalPackageInfo.version,
                        style:
                            TextStyle(color: textColor).useSystemChineseFont(),
                      ))),
              CupertinoFormRow(
                prefix: Text(
                  '检查更新',
                  style: TextStyle(color: textColor).useSystemChineseFont(),
                ),
                child: CupertinoButton(
                  onPressed: () async {
                    await checkVersionUpdate(context, true);
                  },
                  child: Icon(CupertinoIcons.cloud, color: iconColor),
                ),
              ),
              CupertinoFormRow(
                prefix: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      '自动检查更新',
                      style: TextStyle(color: textColor).useSystemChineseFont(),
                    )),
                child: CupertinoSwitch(
                    value: globalConfig.versionAutoUpdate,
                    onChanged: (value) {
                      if (value != globalConfig.versionAutoUpdate) {
                        globalConfig.versionAutoUpdate = value;
                        globalConfig.save();
                        setState(() {});
                      }
                    }),
              ),
              CupertinoFormRow(
                prefix: Text(
                  '项目链接',
                  style: TextStyle(color: textColor).useSystemChineseFont(),
                ),
                child: CupertinoButton(
                  onPressed: openProjectLink,
                  child: Text(
                    'github.com/obineller411/apprhymeX',
                    style: TextStyle(color: textColor).useSystemChineseFont(),
                  ),
                ),
              ),
              CupertinoFormRow(
                prefix: Text(
                  '关于软件',
                  style: TextStyle(color: textColor).useSystemChineseFont(),
                ),
                child: CupertinoButton(
                  onPressed: () => showAboutSoftwareDialog(context),
                  child: Icon(
                    CupertinoIcons.info_circle,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          CupertinoFormSection.insetGrouped(
            header: Text("音频设置",
                style: TextStyle(color: textColor).useSystemChineseFont()),
            children: [
              CupertinoFormRow(
                  prefix: Text("清空待播清单",
                      style:
                          TextStyle(color: textColor).useSystemChineseFont()),
                  child: CupertinoButton(
                      child: Icon(
                        CupertinoIcons.clear,
                        color: activeIconRed,
                      ),
                      onPressed: () {
                        globalAudioHandler.clear();
                      }))
            ],
          ),
          _buildExternApiSection(textColor, iconColor),
          _buildDefaultQualitySelectSection(context, () {
            setState(() {});
          }, textColor),
          // IOS系统无法直接访问文件系统，且已开启在文件中显示应用数据，所以不显示此选项
          if (!Platform.isIOS)
            _buildExportCacheRoot(context, refresh, textColor, iconColor),
          CupertinoFormSection.insetGrouped(
            header: Text('储存设置',
                style: TextStyle(color: textColor).useSystemChineseFont()),
            children: [
              CupertinoFormRow(
                prefix: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      '保存歌曲时缓存歌曲封面',
                      style: TextStyle(color: textColor).useSystemChineseFont(),
                    )),
                child: CupertinoSwitch(
                    value: globalConfig.savePicWhenAddMusicList,
                    onChanged: (value) {
                      if (value != globalConfig.savePicWhenAddMusicList) {
                        globalConfig.savePicWhenAddMusicList = value;
                        globalConfig.save();
                        setState(() {});
                      }
                    }),
              ),
              CupertinoFormRow(
                prefix: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      '保存歌单时缓存歌曲歌词',
                      style: TextStyle(color: textColor).useSystemChineseFont(),
                    )),
                child: CupertinoSwitch(
                    value: globalConfig.saveLyricWhenAddMusicList,
                    onChanged: (value) {
                      if (value != globalConfig.saveLyricWhenAddMusicList) {
                        globalConfig.saveLyricWhenAddMusicList = value;
                        globalConfig.save();
                        setState(() {});
                      }
                    }),
              ),
              CupertinoFormRow(
                  prefix: Text("清除冗余歌曲数据",
                      style:
                          TextStyle(color: textColor).useSystemChineseFont()),
                  child: CupertinoButton(
                      onPressed: () async {
                        try {
                          await SqlFactoryW.cleanUnusedMusicData();
                          await SqlFactoryW.cleanUnusedMusiclist();
                          refreshMusicListGridViewPage();
                          LogToast.success("储存清理", "清理无用歌曲数据成功",
                              "[MorePage] Cleaned unused music data");
                        } catch (e) {
                          LogToast.error("储存清理", "清理无用歌曲数据失败: $e",
                              "[MorePage] Failed to clean unused music data: $e");
                        }
                      },
                      child: const Icon(
                        CupertinoIcons.bin_xmark,
                        color: CupertinoColors.systemRed,
                      ))),
            ],
          ),
          CupertinoFormSection.insetGrouped(
            header: Text('其他',
                style: TextStyle(color: textColor).useSystemChineseFont()),
            children: [
              CupertinoFormRow(
                  prefix: Text("运行日志",
                      style:
                          TextStyle(color: textColor).useSystemChineseFont()),
                  child: CupertinoButton(
                      child: const Icon(
                        CupertinoIcons.book,
                        color: CupertinoColors.activeGreen,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(CupertinoPageRoute(
                          builder: (context) =>
                              TalkerScreen(talker: globalTalker),
                        ));
                      })),
              Obx(() => CupertinoFormRow(
                prefix: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    '桌面模式',
                    style: TextStyle(color: textColor).useSystemChineseFont(),
                  ),
                ),
                child: CupertinoSwitch(
                  value: _forceDesktopMode.value,
                  onChanged: (value) async {
                    if (value != _forceDesktopMode.value) {
                      // 显示确认对话框
                      bool? confirm = await showCupertinoDialog<bool>(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: Text(
                            '切换桌面模式',
                            style: TextStyle().useSystemChineseFont(),
                          ),
                          content: Text(
                            value
                                ? '开启桌面模式需要重启应用才能生效，是否继续？'
                                : '关闭桌面模式需要重启应用才能生效，是否继续？',
                            style: TextStyle().useSystemChineseFont(),
                          ),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: Text(
                                '取消',
                                style: TextStyle().useSystemChineseFont(),
                              ),
                            ),
                            CupertinoDialogAction(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: Text(
                                '确定',
                                style: TextStyle().useSystemChineseFont(),
                              ),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        _forceDesktopMode.value = value;
                        GetStorage().write('forceDesktopMode', value);
                        
                        // 延迟退出应用
                        await Future.delayed(const Duration(milliseconds: 500));
                        await exitApp();
                      }
                    }
                  },
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  CupertinoFormSection _buildExternApiSection(
      Color textColor, Color iconColor) {
    List<Widget> children = [];
    
    // 内置音乐源状态
    children.add(CupertinoFormRow(
        prefix: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              '音源状态',
              style: TextStyle(color: textColor).useSystemChineseFont(),
            )),
        child: Container(
            padding: const EdgeInsets.only(right: 10),
            alignment: Alignment.centerRight,
            height: 50,
            child: Text(
              ApiStatusChecker.getStatusDisplayText(),
              style: TextStyle(
                color: ApiStatusChecker.isApiAvailable 
                    ? CupertinoColors.activeGreen 
                    : activeIconRed
              ).useSystemChineseFont(),
            ))));
    
    // 内置音乐源信息
    children.add(CupertinoFormRow(
        prefix: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              '音源类型',
              style: TextStyle(color: textColor).useSystemChineseFont(),
            )),
        child: Container(
            padding: const EdgeInsets.only(right: 10),
            alignment: Alignment.centerRight,
            height: 50,
            child: Text(
              "内置网易云音乐API",
              style: TextStyle(color: textColor).useSystemChineseFont(),
            ))));
    
    
    // 手动检查按钮
    children.add(CupertinoFormRow(
        prefix: Text('手动检查',
            style: TextStyle(color: textColor).useSystemChineseFont()),
        child: CupertinoButton(
          onPressed: () async {
            await ApiStatusChecker.checkApiStatusManually();
            setState(() {});
          },
          child: Icon(CupertinoIcons.refresh, color: iconColor),
        ),
      ),
    );
    
    return CupertinoFormSection.insetGrouped(
        header: Text("内置音乐源",
            style: TextStyle(color: textColor).useSystemChineseFont()),
        children: children);
  }
  

  CupertinoFormSection _buildDefaultQualitySelectSection(
    BuildContext context, void Function() refresh, Color textColor) {
  List<Widget> children = [];

  if (Platform.isAndroid || Platform.isIOS) {
    // Wifi下默认播放音质
    children.add(CupertinoFormRow(
        prefix: Text("Wifi下默认播放音质",
            style: TextStyle(color: textColor).useSystemChineseFont()),
        child: CupertinoButton(
            onPressed: () async {
              MusicQualityInfo? selectedQuality =
                  await showQualitySelectDialog(context);
              if (selectedQuality != null) {
                globalConfig.wifiAutoQuality = selectedQuality.apiValue;
                await globalConfig.save();
              }
              refresh();
            },
            child: Text(
                QualityConfigManager.fromApiValue(globalConfig.wifiAutoQuality).displayName,
                style: TextStyle(color: textColor)))));
    
    // 数据网络下默认播放音质
    children.add(CupertinoFormRow(
        prefix: Text("数据网络下默认播放音质",
            style: TextStyle(color: textColor).useSystemChineseFont()),
        child: CupertinoButton(
            onPressed: () async {
              MusicQualityInfo? selectedQuality =
                  await showQualitySelectDialog(context);
              if (selectedQuality != null) {
                globalConfig.mobileAutoQuality = selectedQuality.apiValue;
                await globalConfig.save();
              }
              refresh();
            },
            child: Text(
                QualityConfigManager.fromApiValue(globalConfig.mobileAutoQuality).displayName,
                style: TextStyle(color: textColor).useSystemChineseFont()))));
  } else {
    // 桌面端默认播放音质
    children.add(CupertinoFormRow(
        prefix: Text("默认播放音质",
            style: TextStyle(color: textColor).useSystemChineseFont()),
        child: CupertinoButton(
            onPressed: () async {
              MusicQualityInfo? selectedQuality =
                  await showQualitySelectDialog(context);
              if (selectedQuality != null) {
                globalConfig.wifiAutoQuality = selectedQuality.apiValue;
                await globalConfig.save();
              }
              refresh();
            },
            child: Text(
                QualityConfigManager.fromApiValue(globalConfig.wifiAutoQuality).displayName,
                style: TextStyle(color: textColor).useSystemChineseFont()))));
  }
  
  return CupertinoFormSection.insetGrouped(
    header:
        Text('默认播放音质', style: TextStyle(color: textColor).useSystemChineseFont()),
    children: children,
  );
}

// 保留旧的函数用于向后兼容
// ignore: unused_element
@Deprecated('请使用 _buildDefaultQualitySelectSection 替代此函数')
CupertinoFormSection _buildQualitySelectSection(
    BuildContext context, void Function() refresh, Color textColor) {
  List<Widget> children = [];

  if (Platform.isAndroid || Platform.isIOS) {
    children.add(CupertinoFormRow(
        prefix: Text("Wifi下音质选择",
            style: TextStyle(color: textColor).useSystemChineseFont()),
        child: CupertinoButton(
            onPressed: () async {
              MusicQualityInfo? selectedQuality =
                  await showQualitySelectDialog(context);
              if (selectedQuality != null) {
                globalConfig.wifiAutoQuality = selectedQuality.apiValue;
                await globalConfig.save();
              }
              refresh();
            },
            child: Text(
                QualityConfigManager.fromApiValue(globalConfig.wifiAutoQuality).displayName,
                style: TextStyle(color: textColor)))));
    children.add(CupertinoFormRow(
        prefix: Text("数据网络下音质选择",
            style: TextStyle(color: textColor).useSystemChineseFont()),
        child: CupertinoButton(
            onPressed: () async {
              MusicQualityInfo? selectedQuality =
                  await showQualitySelectDialog(context);
              if (selectedQuality != null) {
                globalConfig.mobileAutoQuality = selectedQuality.apiValue;
                await globalConfig.save();
              }
              refresh();
            },
            child: Text(
                QualityConfigManager.fromApiValue(globalConfig.mobileAutoQuality).displayName,
                style: TextStyle(color: textColor).useSystemChineseFont()))));
  } else {
    children.add(CupertinoFormRow(
        prefix: Text("音质选择",
            style: TextStyle(color: textColor).useSystemChineseFont()),
        child: CupertinoButton(
            onPressed: () async {
              MusicQualityInfo? selectedQuality =
                  await showQualitySelectDialog(context);
              if (selectedQuality != null) {
                globalConfig.wifiAutoQuality = selectedQuality.apiValue;
                await globalConfig.save();
              }
              refresh();
            },
            child: Text(
                QualityConfigManager.fromApiValue(globalConfig.wifiAutoQuality).displayName,
                style: TextStyle(color: textColor).useSystemChineseFont()))));
  }
  return CupertinoFormSection.insetGrouped(
    header:
        Text('音质选择', style: TextStyle(color: textColor).useSystemChineseFont()),
    children: children,
  );
}

CupertinoFormSection _buildExportCacheRoot(BuildContext context,
    void Function() refresh, Color textColor, Color iconColor) {
  Future<void> exportCacheRoot(bool copy) async {
    var path = await pickDirectory();
    if (path == null) return;
    if (globalConfig.exportCacheRoot != null &&
        globalConfig.exportCacheRoot == path) {
      LogToast.info("数据设定", "与原文件夹相同, 无需操作",
          "[exportCacheRoot] Same as original folder, no need to operate");
      return;
    }
    try {
      try {
        if (context.mounted) {
          await showWaitDialog(context, "正在处理中,稍后将自动退出应用以应用更改");
        }
        await globalAudioHandler.clear();
        await SqlFactoryW.shutdown();
        late String originRootPath;
        if (globalConfig.exportCacheRoot != null &&
            globalConfig.exportCacheRoot!.isNotEmpty) {
          originRootPath = globalConfig.exportCacheRoot!;
        } else {
          originRootPath = "$globalDocumentPath/AppRhymeX";
        }
        if (copy) {
          await copyDirectory(
              src: "$originRootPath/$picCacheRoot", dst: "$path/$picCacheRoot");
          await copyDirectory(
              src: "$originRootPath/$musicCacheRoot",
              dst: "$path/$musicCacheRoot");
          await copyFile(
              from: "$originRootPath/MusicData.db", to: "$path/MusicData.db");
        }

        globalConfig.lastExportCacheRoot = globalConfig.exportCacheRoot;
        globalConfig.exportCacheRoot = path;
        globalConfig.save();
        if (context.mounted) {
          context.findAncestorStateOfType<MorePageState>()?.refresh();
        }
        await SqlFactoryW.initFromPath(filepath: "$path/MusicData.db");
      } finally {
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
      try {
        if (context.mounted) {
          await showWaitDialog(context,
              "应用将在3秒后退出\n下次打开时将删除旧文件夹下数据, 并应用新文件夹下数据\n如未正常退出, 请关闭应用后重新打开");
        }
        await Future.delayed(const Duration(seconds: 3));
      } finally {
        if (context.mounted) {
          Navigator.pop(context);
        }
        await exitApp();
      }
    } catch (e) {
      LogToast.error("数据设定", "数据设定失败: $e", "[exportCacheRoot] $e");
    }
  }

  List<CupertinoFormRow> children = [];
  if (globalConfig.exportCacheRoot == null) {
    children.add(CupertinoFormRow(
        prefix: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              '当前数据状态',
              style: TextStyle(color: textColor).useSystemChineseFont(),
            )),
        child: Container(
            padding: const EdgeInsets.only(right: 10),
            alignment: Alignment.centerRight,
            height: 50,
            child: Text(
              "应用内部数据",
              style: TextStyle(color: textColor).useSystemChineseFont(),
            ))));
  } else {
    children.add(CupertinoFormRow(
        prefix: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              '当前数据文件夹',
              style: TextStyle(color: textColor).useSystemChineseFont(),
            )),
        child: Container(
            padding: const EdgeInsets.only(right: 10),
            alignment: Alignment.centerRight,
            height: 50,
            child: Text(
              globalConfig.exportCacheRoot!,
              style: TextStyle(color: textColor).useSystemChineseFont(),
            ))));
  }
  children.add(
    CupertinoFormRow(
      prefix: Text(
        '迁移数据文件夹',
        style: TextStyle(color: textColor).useSystemChineseFont(),
      ),
      child: CupertinoButton(
        onPressed: () async {
          var confirm = await showConfirmationDialog(
              context,
              "注意!\n"
              "迁移数据将会将当前使用文件夹下的数据迁移到新的文件夹下\n"
              "请确保新的文件夹下没有AppRhymeX的数据, 否则会导致该文件夹中数据完全丢失!!!\n"
              "如果你想直接使用指定文件夹下的数据, 请使用'使用数据'功能\n"
              "操作后应用将会自动退出, 请重新打开应用以应用更改\n"
              "是否继续?");
          if (confirm != null && confirm) {
            await exportCacheRoot(true);
          }
        },
        child: Icon(CupertinoIcons.folder, color: iconColor),
      ),
    ),
  );
  children.add(
    CupertinoFormRow(
      prefix: Text(
        '使用数据文件夹',
        style: TextStyle(color: textColor).useSystemChineseFont(),
      ),
      child: CupertinoButton(
        onPressed: () async {
          var confirm = await showConfirmationDialog(
              context,
              "注意!\n"
              "使用数据将会直接使用指定文件夹下的数据, 请确保指定下有正确的数据\n"
              "这将会导致当前使用的文件夹下的数据完全丢失!!!\n"
              "如果你想迁移数据, 请使用'迁移数据'功能\n"
              "操作后应用将会自动退出, 请重新打开应用以应用更改\n"
              "是否继续?");
          if (confirm != null && confirm) {
            await exportCacheRoot(false);
          }
        },
        child: Icon(CupertinoIcons.folder, color: iconColor),
      ),
    ),
  );
  return CupertinoFormSection.insetGrouped(
    header:
        Text('数据设定', style: TextStyle(color: textColor).useSystemChineseFont()),
    children: children,
  );
}

void showAboutSoftwareDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(
        '关于软件',
        style: TextStyle().useSystemChineseFont(),
      ),
      content: SizedBox(
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(
                'AppRhymeX - 音乐播放器',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ).useSystemChineseFont(),
              ),
              const SizedBox(height: 10),
              Text(
                '版本: ${globalPackageInfo.version}',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 20),
              Text(
                '项目信息',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ).useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '本项目是基于 canxin121/app_rhyme 的修改版本',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '原项目: github.com/canxin121/app_rhyme',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '当前版本: github.com/obineller411/apprhymeX',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 20),
              Text(
                '许可证',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ).useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '本项目采用 Apache License 2.0 和 MIT 许可证双重许可',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 20),
              Text(
                '免责声明',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ).useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '1. 本软件仅供学习和个人使用，请勿用于商业用途',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '2. 本软件使用的第三方API（如网易云音乐API）均来自网络，请遵守相关服务条款',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '3. 本软件不对任何第三方服务的内容或可用性负责',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '4. 使用本软件的风险由用户自行承担',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '5. 本软件尊重版权，请在使用时遵守相关法律法规',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 20),
              Text(
                '技术栈',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ).useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '• Flutter (Dart)',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '• Rust',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '• GetX',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '• Cupertino 风格 UI',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 20),
              Text(
                '特别鸣谢',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ).useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '• 原项目作者: canxin121',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '• Flutter 团队',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '• Rust 团队',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 8),
              Text(
                '• 开源社区贡献者',
                style: TextStyle().useSystemChineseFont(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            '确定',
            style: TextStyle().useSystemChineseFont(),
          ),
        ),
      ],
    ),
  );
}
}
