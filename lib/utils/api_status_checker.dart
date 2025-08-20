import 'dart:async';
import 'dart:convert';
import 'package:app_rhyme/extern_apis/netease_api.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// 内置API状态检查器
class ApiStatusChecker {
  static Timer? _statusCheckTimer;
  static bool _isApiAvailable = false;
  static DateTime _lastCheckTime = DateTime.now();
  static String _lastStatusMessage = "未检测";
  
  // 获取API状态
  static bool get isApiAvailable => _isApiAvailable;
  
  // 获取最后检查时间
  static DateTime get lastCheckTime => _lastCheckTime;
  
  // 获取状态消息
  static String get statusMessage => _lastStatusMessage;
  
  // 初始化API状态检查器
  static void init() {
    globalTalker.info('[ApiStatusChecker] 初始化API状态检查器');
    
    // 立即执行第一次检查
    _checkApiStatus();
    
    // 监听网络状态变化，网络恢复时重新检查
    globalConnectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.mobile)) {
        // 网络恢复，延迟5秒后检查API状态
        Future.delayed(const Duration(seconds: 5), _checkApiStatus);
      }
    });
  }
  
  // 启动定时API状态检查
  static void startPeriodicCheck() {
    globalTalker.info('[ApiStatusChecker] 启动定时API状态检查');
    
    // 停止现有的定时器（如果有）
    _statusCheckTimer?.cancel();
    
    // 启动新的定时检查，每小时一次
    _statusCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkApiStatus();
    });
  }
  
  // 停止API状态检查
  static void dispose() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
    globalTalker.info('[ApiStatusChecker] API状态检查器已停止');
  }
  
  // 手动检查API状态
  static Future<void> checkApiStatusManually() async {
    globalTalker.info('[ApiStatusChecker] 手动检查API状态');
    await _checkApiStatus();
  }
  
  // 检查API状态
  static Future<void> _checkApiStatus() async {
    try {
      globalTalker.info('[ApiStatusChecker] 开始检查内置API状态');
      
      // 检查网络连接
      var connectivityResult = await globalConnectivity.checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.wifi) && 
          !connectivityResult.contains(ConnectivityResult.mobile)) {
        _updateApiStatus(false, "网络不可用");
        return;
      }
      
      // 测试网易云音乐API
      bool isAvailable = await _testNeteaseApi();
      _updateApiStatus(isAvailable, isAvailable ? "正常" : "连接失败");
      
    } catch (e) {
      globalTalker.error('[ApiStatusChecker] 检查API状态时发生错误: $e');
      _updateApiStatus(false, "检测失败");
    }
  }
  
  // 测试网易云音乐API
  static Future<bool> _testNeteaseApi() async {
    try {
      // 使用一个简单的测试歌曲ID来测试API
      const testSongId = "475479888"; // 一个常用的测试歌曲ID
      
      // 构建测试数据
      final testData = {
        'id': testSongId,
        'quality': 'standard'
      };
      
      // 调用API获取歌曲信息
      var result = await getMusicPlayInfo("WangYi", json.encode(testData));
      
      // 检查结果
      if (result != null && result.uri.isNotEmpty) {
        globalTalker.info('[ApiStatusChecker] 网易云音乐API测试成功');
        return true;
      } else {
        globalTalker.warning('[ApiStatusChecker] 网易云音乐API测试失败: 返回结果为空');
        return false;
      }
    } catch (e) {
      globalTalker.error('[ApiStatusChecker] 网易云音乐API测试失败: $e');
      return false;
    }
  }
  
  // 更新API状态
  static void _updateApiStatus(bool isAvailable, String message) {
    bool statusChanged = (_isApiAvailable != isAvailable);
    
    _isApiAvailable = isAvailable;
    _lastCheckTime = DateTime.now();
    _lastStatusMessage = message;
    
    if (statusChanged) {
      globalTalker.info('[ApiStatusChecker] API状态已变更: $message');
    } else {
      globalTalker.info('[ApiStatusChecker] API状态检查完成: $message');
    }
  }
  
  // 获取状态显示文本
  static String getStatusDisplayText() {
    return _lastStatusMessage;
  }
  
  // 格式化持续时间
  static String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return "${duration.inSeconds}秒";
    } else if (duration.inHours < 1) {
      return "${duration.inMinutes}分钟";
    } else {
      return "${duration.inHours}小时";
    }
  }
}