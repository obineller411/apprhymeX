import 'dart:async';
import 'dart:convert';
import 'package:app_rhyme/src/rust/api/bind/mirrors.dart';
import 'package:app_rhyme/src/rust/api/types/playinfo.dart';
import 'package:app_rhyme/types/extern_api.dart'; // 导入 HttpHelper
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:app_rhyme/utils/log_toast.dart';

// 获取网易云音乐支持的音质配置
List<Map<String, dynamic>> getSupportedQualities() {
  return [
    {
      "display_name": "标准音质",
      "api_value": "standard",
      "level": 0
    },
    {
      "display_name": "极高音质",
      "api_value": "exhigh",
      "level": 1
    },
    {
      "display_name": "无损音质",
      "api_value": "lossless",
      "level": 2
    },
    {
      "display_name": "Hi-Res音质",
      "api_value": "hires",
      "level": 3
    },
    {
      "display_name": "高清环绕声",
      "api_value": "jyeffect",
      "level": 4
    },
    {
      "display_name": "沉浸环绕声",
      "api_value": "sky",
      "level": 5
    },
    {
      "display_name": "超清母带",
      "api_value": "jymaster",
      "level": 6
    }
  ];
}

Timer? _debounce;

Future<PlayInfo?> getMusicPlayInfo(String source, String extra) async {
  if (source != "WangYi") {
    return null;
  }
  
  final completer = Completer<PlayInfo?>();

  if (_debounce?.isActive ?? false) {
    _debounce!.cancel();
  }

  _debounce = Timer(const Duration(milliseconds: 300), () async {
    globalTalker.info("[NeteaseApi] Debounced request with extra: $extra");
    const apiUrl = "https://api.kxzjoker.cn/api/163_music";

    try {
      final Map<String, dynamic> extraData = json.decode(extra);
      final String? url = extraData['url'] as String?;
      
      // 安全地处理id字段，支持int和String类型
      int? id;
      if (extraData['id'] != null) {
        if (extraData['id'] is int) {
          id = extraData['id'] as int;
        } else if (extraData['id'] is String) {
          id = int.tryParse(extraData['id'].toString());
        }
      }
      
      final String level = extraData['quality'] as String? ?? 'standard';
      globalTalker.info("[NeteaseApi] Parsed extra data - url: '$url', id: '$id', level: '$level'");

      String? payload;
      if (url != null && url.isNotEmpty) {
        payload = 'url=${Uri.encodeComponent(url)}&level=$level&type=json';
      } else if (id != null) {
        payload = 'ids=$id&level=$level&type=json';
      }

      if (payload == null) {
        LogToast.error("网易云音乐解析失败", "URL和ID均为空", "[NeteaseApi] URL and ID are both empty");
        completer.complete(null);
        return;
      }

      final Map<String, String> headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      globalTalker.info("[NeteaseApi] Sending POST request to $apiUrl with payload: $payload");

      // 使用原始HTTP请求，避免网络稳定性助手的JSON解析问题
      final httpHelper = HttpHelper();
      final response = await httpHelper.sendRequest('POST', headers, apiUrl, payload);
      
      // 添加调试日志检查响应内容
      if (response.isEmpty) {
        LogToast.error("网易云音乐解析失败", "API返回空响应", "[NeteaseApi] Empty response received");
        completer.complete(null);
        return;
      }
      
      globalTalker.info("[NeteaseApi] Raw response length: ${response.length}");
      
      final Map<String, dynamic> data = json.decode(response);
    
      // 创建简化版本用于日志输出（去除歌词信息）
      final Map<String, dynamic> simplifiedResponse = {
        'status': data['status'],
        'name': data['name'],
        'pic': data['pic'],
        'ar_name': data['ar_name'],
        'al_name': data['al_name'],
        'level': data['level'],
        'size': data['size'],
        'url': data['url'],
        'lyric': '[歌词内容已隐藏]',
        'tlyric': '[翻译歌词已隐藏]',
      };
      
      globalTalker.info("[NeteaseApi] Received response: $simplifiedResponse");

      if (data['status'] == 200) {
        final String? musicUrl = data['url'] as String?;
        final String? qualityShort = data['level'] as String?;
        final String? format = musicUrl?.split('.').last.split('?').first;
        final String? size = data['size']?.toString();
        final String? lyric = data['lyric'] as String?;
        final String? tlyric = data['tlyric'] as String?;

        if (musicUrl == null || qualityShort == null) {
          LogToast.error("网易云音乐解析失败", "API返回数据不完整 (URL或音质缺失)",
              "[NeteaseApi] API returned incomplete data (URL or quality missing)");
          completer.complete(null);
          return;
        }

        // 安全地处理bitrate字段，避免类型转换错误
        int? bitrate;
        if (data['br'] != null) {
          if (data['br'] is int) {
            bitrate = data['br'] as int;
          } else if (data['br'] is String) {
            bitrate = int.tryParse(data['br'].toString());
          }
        }
        
        final Quality quality = Quality(
          short: qualityShort,
          level: qualityShort,
          bitrate: bitrate,
          format: format,
          size: size,
        );

        completer.complete(PlayInfo(
            uri: musicUrl, quality: quality, lyric: lyric, tlyric: tlyric));
      } else {
        LogToast.error("网易云音乐解析失败", "API返回错误: ${data['status']}",
            "[NeteaseApi] API returned error: ${data['status']}");
        completer.complete(null);
      }
    } catch (e) {
      LogToast.error(
          "网易云音乐解析异常", "解析过程中发生错误: $e", "[NeteaseApi] Error during parsing: $e");
      completer.complete(null);
    }
  });

  return completer.future;
}
