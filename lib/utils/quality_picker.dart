import 'dart:io';

import 'package:app_rhyme/src/rust/api/bind/mirrors.dart';
import 'package:app_rhyme/types/chore.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:app_rhyme/extern_apis/netease_api.dart';

// 音乐质量信息类
class MusicQualityInfo {
  final String displayName;
  final String apiValue;
  final int level;

  MusicQualityInfo({
    required this.displayName,
    required this.apiValue,
    required this.level,
  });

  // 从JSON创建MusicQualityInfo
  factory MusicQualityInfo.fromJson(Map<String, dynamic> json) {
    return MusicQualityInfo(
      displayName: json['display_name'] ?? json['displayName'] ?? '未知音质',
      apiValue: json['api_value'] ?? json['apiValue'] ?? 'standard',
      level: json['level'] ?? 0,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'api_value': apiValue,
      'level': level,
    };
  }
}

// 音乐质量配置管理器
class QualityConfigManager {
  static List<MusicQualityInfo> _qualities = [];
  static Map<String, MusicQualityInfo> _qualityMap = {};

  // 初始化音质配置
  static Future<void> initQualities() async {
    globalTalker.info('[QualityConfigManager] 开始初始化音质配置');
    
    // 直接使用内置的网易云音乐API作为默认配置
    _useDefaultQualities();
    globalTalker.info('[QualityConfigManager] 音质配置初始化完成');
  }

  // 使用内置的默认音质配置（从网易云音乐API获取）
  static void _useDefaultQualities() {
    _qualities = getSupportedQualities().map((q) => MusicQualityInfo.fromJson(q)).toList();
    _qualityMap = {for (var q in _qualities) q.apiValue: q};
    globalTalker.info('[QualityConfigManager] 使用网易云音乐API音质配置: ${_qualities.map((q) => q.displayName).join(', ')}');
  }

  // 从API获取音质配置
  static Future<List<MusicQualityInfo>> _fetchQualitiesFromApi() async {
    try {
      globalTalker.info('[QualityConfigManager] 尝试从网易云音乐API获取音质配置');
      
      // 直接调用内置的网易云音乐API函数
      List<Map<String, dynamic>> qualitiesList = getSupportedQualities();
      globalTalker.info('[QualityConfigManager] 从API获取到 ${qualitiesList.length} 个音质配置');
      
      return qualitiesList.map((q) => MusicQualityInfo.fromJson(q)).toList();
    } catch (e) {
      globalTalker.error('[QualityConfigManager] 从API获取音质配置失败: $e');
      return [];
    }
  }

  // 获取所有音质
  static List<MusicQualityInfo> getQualities() {
    globalTalker.info('[QualityConfigManager] getQualities() 被调用，返回 ${_qualities.length} 个音质');
    return List.from(_qualities);
  }

  // 根据API值获取音质信息
  static MusicQualityInfo fromApiValue(String? apiValue) {
    if (apiValue == null || apiValue.isEmpty) {
      // 对于空值，直接返回第一个可用音质
      return _qualities.isNotEmpty
          ? _qualities.first
          : MusicQualityInfo(displayName: "未知音质", apiValue: "unknown", level: 0);
    }
    
    if (!_qualityMap.containsKey(apiValue)) {
      // 如果不存在，返回第一个可用音质
      return _qualities.isNotEmpty
          ? _qualities.first
          : MusicQualityInfo(displayName: "未知音质", apiValue: "unknown", level: 0);
    }
    
    return _qualityMap[apiValue]!;
  }
  

  // 根据显示名称获取音质信息
  static MusicQualityInfo fromDisplayName(String displayName) {
    return _qualities.firstWhere(
      (e) => e.displayName == displayName,
      orElse: () => _qualities.isNotEmpty
          ? _qualities.first
          : MusicQualityInfo(displayName: "未知音质", apiValue: "unknown", level: 0),
    );
  }

  // 检查是否有指定音质
  static bool hasQuality(String apiValue) {
    return _qualityMap.containsKey(apiValue);
  }
}


// 改进的自动音质选择函数，符合文档描述
Quality autoPickQuality(List<Quality> qualities) {
  if (Platform.isIOS || Platform.isAndroid) {
    switch (globalConnectivityStateSimple) {
      case ConnectivityStateSimple.wifi:
        // WiFi 环境下，使用用户设置的 WiFi 默认音质
        return autoPickQualityByApiValue(
            qualities, globalConfig.wifiAutoQuality);
      case ConnectivityStateSimple.mobile:
        // 移动数据网络环境下，使用用户设置的移动数据默认音质
        return autoPickQualityByApiValue(
            qualities, globalConfig.mobileAutoQuality);
      case ConnectivityStateSimple.none:
        // 无网络连接时，选择最低音质（通常是列表中的最后一个，代表最低质量）
        return qualities.last;
    }
  } else {
    // 针对桌面平台，通常只考虑一种默认音质（等同于 WiFi 环境下的设置）
    return autoPickQualityByApiValue(
        qualities, globalConfig.wifiAutoQuality);
  }
}

// 新的音质选择函数，基于API值
Quality autoPickQualityByApiValue(List<Quality> qualities, String apiValue) {
  // 检查传入的音质值是否是旧的中文音质值
  String finalApiValue = apiValue;
  
  // 如果是旧的中文音质值，则使用API支持的默认音质
  if (apiValue == "最高" || apiValue == "中等" || apiValue == "低") {
    // 获取所有可用的API音质
    var availableQualities = QualityConfigManager.getQualities();
    if (availableQualities.isNotEmpty) {
      // 使用第一个可用的API音质（通常是最低或标准音质）
      finalApiValue = availableQualities.first.apiValue;
      globalTalker.info("[autoPickQuality] 检测到旧音质值 '$apiValue'，替换为 '$finalApiValue'");
    } else {
      // 如果没有可用的音质，使用standard作为默认值
      finalApiValue = "standard";
      globalTalker.info("[autoPickQuality] 检测到旧音质值 '$apiValue'，使用默认值 'standard'");
    }
  }
  
  // 如果传入的音质值为空或无效，也使用默认值
  if (finalApiValue.isEmpty || finalApiValue == "unknown") {
    var availableQualities = QualityConfigManager.getQualities();
    if (availableQualities.isNotEmpty) {
      finalApiValue = availableQualities.first.apiValue;
      globalTalker.info("[autoPickQuality] 使用默认音质值: $finalApiValue");
    } else {
      finalApiValue = "standard";
      globalTalker.info("[autoPickQuality] 使用备用默认音质值: standard");
    }
  }
  
  // 直接创建一个Quality对象，使用处理后的音质值
  Quality userQuality = Quality(
    short: finalApiValue,
    level: qualities.first.level, // 使用第一个可用音质的level作为默认
    format: qualities.first.format, // 使用第一个可用音质的format作为默认
  );
  
  globalTalker.info("[autoPickQuality] 最终请求: $finalApiValue");
  return userQuality;
}
