import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:app_rhyme/utils/global_vars.dart';

/// 网络稳定性助手
/// 专门优化后台播放时的网络请求稳定性，处理超时和错误恢复
class NetworkStabilityHelper {
  static final NetworkStabilityHelper _instance = NetworkStabilityHelper._internal();
  factory NetworkStabilityHelper() => _instance;
  NetworkStabilityHelper._internal();

  // 网络状态监控
  bool _isNetworkStable = true;
  DateTime? _lastNetworkError;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;
  static const Duration _networkRecoveryDelay = Duration(seconds: 5);

  // 请求重试配置
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  static const Duration _requestTimeout = Duration(seconds: 30);

  /// 检查网络是否稳定
  bool get isNetworkStable => _isNetworkStable && _consecutiveFailures < _maxConsecutiveFailures;

  /// 标记网络成功
  void markNetworkSuccess() {
    _consecutiveFailures = 0;
    _isNetworkStable = true;
    _lastNetworkError = null;
  }

  /// 标记网络失败
  void markNetworkFailure() {
    _consecutiveFailures++;
    _lastNetworkError = DateTime.now();
    _isNetworkStable = false;
    
    // 如果失败次数过多，延迟恢复
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      _scheduleNetworkRecovery();
    }
  }

  /// 安排网络恢复
  void _scheduleNetworkRecovery() {
    Future.delayed(_networkRecoveryDelay, () {
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        _consecutiveFailures = _maxConsecutiveFailures - 1; // 减少失败次数，允许重试
        _isNetworkStable = true;
        globalTalker.info('[NetworkStabilityHelper] 网络状态已恢复，允许重试');
      }
    });
  }

  /// 带重试机制的HTTP请求
  Future<http.Response> sendRequestWithRetry(
    String method,
    Map<String, String> headers,
    String url,
    String body,
  ) async {
    if (!isNetworkStable) {
      throw Exception('网络不稳定，暂停请求');
    }

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final client = http.Client();
        final request = http.Request(method, Uri.parse(url));
        request.headers.addAll(headers);
        request.body = body;
        
        final response = await client.send(request).timeout(_requestTimeout);
        final responseBody = await response.stream.bytesToString();
        
        markNetworkSuccess();
        return http.Response(responseBody, response.statusCode);
      } catch (e) {
        globalTalker.warning('[NetworkStabilityHelper] 请求失败 (尝试 $attempt/$_maxRetries): $e');
        
        if (attempt == _maxRetries) {
          markNetworkFailure();
          rethrow;
        }
        
        // 等待后重试
        await Future.delayed(_retryDelay * attempt);
      }
    }
    
    throw Exception('所有重试都失败了');
  }

  /// 带重试机制的JSON请求
  Future<Map<String, dynamic>> sendJsonRequestWithRetry(
    String method,
    Map<String, String> headers,
    String url,
    String body,
  ) async {
    final response = await sendRequestWithRetry(method, headers, url, body);
    
    try {
      final data = response.body as Map<String, dynamic>;
      return data;
    } catch (e) {
      globalTalker.error('[NetworkStabilityHelper] JSON解析失败: $e');
      markNetworkFailure();
      rethrow;
    }
  }

  /// 智能延迟策略 - 优化以支持高频率API请求
  Duration getSmartDelay() {
    // Android平台后台播放特殊处理
    if (Platform.isAndroid) {
      final backgroundHelper = BackgroundPlaybackHelper();
      if (backgroundHelper.isInBackground) {
        // 后台播放时增加延迟，避免网络请求过于频繁
        if (_consecutiveFailures == 0) return const Duration(milliseconds: 500);
        if (_consecutiveFailures == 1) return const Duration(milliseconds: 1000);
        if (_consecutiveFailures == 2) return const Duration(milliseconds: 2000);
        return const Duration(milliseconds: 3000);
      }
    }
    
    // 前台播放或非Android平台
    if (_consecutiveFailures == 0) return Duration.zero;
    if (_consecutiveFailures == 1) return const Duration(milliseconds: 100);
    if (_consecutiveFailures == 2) return const Duration(milliseconds: 300);
    return const Duration(milliseconds: 500);
  }

  /// 重置网络状态
  void reset() {
    _consecutiveFailures = 0;
    _isNetworkStable = true;
    _lastNetworkError = null;
  }

  /// 获取网络状态信息
  Map<String, dynamic> getNetworkStatus() {
    return {
      'isStable': _isNetworkStable,
      'consecutiveFailures': _consecutiveFailures,
      'lastError': _lastNetworkError?.toIso8601String(),
    };
  }
}

/// 音频播放错误恢复助手
/// 专门处理音频播放过程中的错误恢复
class AudioPlaybackRecoveryHelper {
  static final AudioPlaybackRecoveryHelper _instance = AudioPlaybackRecoveryHelper._internal();
  factory AudioPlaybackRecoveryHelper() => _instance;
  AudioPlaybackRecoveryHelper._internal();

  // 错误恢复配置
  static const int _maxPlaybackErrors = 3;
  
  // 播放错误计数
  final Map<String, int> _playbackErrorCounts = {};
  final Map<String, DateTime> _lastPlaybackErrors = {};

  /// 记录播放错误
  void recordPlaybackError(String musicId) {
    _playbackErrorCounts[musicId] = (_playbackErrorCounts[musicId] ?? 0) + 1;
    _lastPlaybackErrors[musicId] = DateTime.now();
    
    globalTalker.warning('[AudioPlaybackRecoveryHelper] 记录播放错误: $musicId, 错误次数: ${_playbackErrorCounts[musicId]}');
  }

  /// 检查是否应该跳过该音乐
  bool shouldSkipMusic(String musicId) {
    final errorCount = _playbackErrorCounts[musicId] ?? 0;
    if (errorCount >= _maxPlaybackErrors) {
      globalTalker.info('[AudioPlaybackRecoveryHelper] 音乐 $musicId 错误次数过多，跳过播放');
      return true;
    }
    return false;
  }

  /// 重置音乐错误计数
  void resetMusicError(String musicId) {
    _playbackErrorCounts.remove(musicId);
    _lastPlaybackErrors.remove(musicId);
  }

  /// 清理过期的错误记录
  void cleanupOldErrors() {
    final now = DateTime.now();
    final expiredTime = now.subtract(const Duration(hours: 1));
    
    _playbackErrorCounts.removeWhere((musicId, _) {
      final lastError = _lastPlaybackErrors[musicId];
      return lastError == null || lastError.isBefore(expiredTime);
    });
    
    _lastPlaybackErrors.removeWhere((musicId, lastError) {
      return lastError.isBefore(expiredTime);
    });
  }

  /// 获取错误恢复延迟 - 优化以支持高频率API请求
  Duration getErrorRecoveryDelay(String musicId) {
    final errorCount = _playbackErrorCounts[musicId] ?? 0;
    if (errorCount == 0) return Duration.zero;
    if (errorCount == 1) return const Duration(milliseconds: 100);
    if (errorCount == 2) return const Duration(milliseconds: 300);
    return const Duration(milliseconds: 500);
  }

  /// 获取播放错误统计
  Map<String, dynamic> getErrorStats() {
    return {
      'totalErrorCounts': _playbackErrorCounts.length,
      'musicErrors': Map.from(_playbackErrorCounts),
    };
  }
}

/// 后台播放优化助手
/// 专门优化应用在后台时的播放性能
class BackgroundPlaybackHelper {
  static final BackgroundPlaybackHelper _instance = BackgroundPlaybackHelper._internal();
  factory BackgroundPlaybackHelper() => _instance;
  BackgroundPlaybackHelper._internal();

  bool _isInBackground = false;
  DateTime? _backgroundStartTime;
  Timer? _backgroundOptimizationTimer;

  // 后台播放配置
  static const Duration _backgroundOptimizationInterval = Duration(minutes: 1);

  /// 标记进入后台
  void markDidEnterBackground() {
    _isInBackground = true;
    _backgroundStartTime = DateTime.now();
    
    // 启动后台优化定时器
    _backgroundOptimizationTimer = Timer.periodic(
      _backgroundOptimizationInterval,
      _optimizeBackgroundPlayback,
    );
    
    globalTalker.info('[BackgroundPlaybackHelper] 应用进入后台，启动优化模式');
  }

  /// 标记进入前台
  void markDidEnterForeground() {
    _isInBackground = false;
    _backgroundStartTime = null;
    
    // 停止后台优化定时器
    _backgroundOptimizationTimer?.cancel();
    _backgroundOptimizationTimer = null;
    
    globalTalker.info('[BackgroundPlaybackHelper] 应用进入前台，恢复正常模式');
  }

  /// 后台播放优化
  void _optimizeBackgroundPlayback(Timer timer) {
    if (!_isInBackground) return;
    
    // Android平台特殊优化
    if (Platform.isAndroid) {
      globalTalker.info('[BackgroundPlaybackHelper] Android后台播放优化执行');
      
      // 清理网络错误记录，重置网络状态
      NetworkStabilityHelper().reset();
      
      // 清理播放错误记录，但保留最近的错误记录
      AudioPlaybackRecoveryHelper().cleanupOldErrors();
      
      // 预热网络连接
      _warmUpNetworkConnection();
    } else {
      // 其他平台的标准优化
      NetworkStabilityHelper().reset();
      AudioPlaybackRecoveryHelper().cleanupOldErrors();
      globalTalker.info('[BackgroundPlaybackHelper] 执行后台播放优化');
    }
  }
  
  /// 预热网络连接 - Android平台专用
  void _warmUpNetworkConnection() {
    // 发送一个轻量级的网络请求来保持网络连接活跃
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        final client = http.Client();
        final request = http.Request('GET', Uri.parse('https://www.baidu.com'));
        request.headers.addAll({'User-Agent': 'AppRhymeX/1.0'});
        
        // 设置较短的超时时间
        final response = await client.send(request).timeout(const Duration(seconds: 5));
        await response.stream.drain();
        client.close();
        
        globalTalker.info('[BackgroundPlaybackHelper] 网络连接预热成功');
      } catch (e) {
        globalTalker.warning('[BackgroundPlaybackHelper] 网络连接预热失败: $e');
      }
    });
  }

  /// 检查是否在后台
  bool get isInBackground => _isInBackground;

  /// 获取后台时长
  Duration? get backgroundDuration {
    if (_backgroundStartTime == null) return null;
    return DateTime.now().difference(_backgroundStartTime!);
  }

  /// 获取后台播放状态
  Map<String, dynamic> getBackgroundStatus() {
    return {
      'isInBackground': _isInBackground,
      'backgroundDuration': backgroundDuration?.inSeconds,
      'optimizationActive': _backgroundOptimizationTimer?.isActive,
    };
  }

  void dispose() {
    _backgroundOptimizationTimer?.cancel();
    _backgroundOptimizationTimer = null;
  }
}

/// Android平台后台播放监控器
/// 专门监控和优化Android平台的后台播放性能
class AndroidBackgroundPlaybackMonitor {
  static final AndroidBackgroundPlaybackMonitor _instance = AndroidBackgroundPlaybackMonitor._internal();
  factory AndroidBackgroundPlaybackMonitor() => _instance;
  AndroidBackgroundPlaybackMonitor._internal();

  Timer? _monitorTimer;
  bool _isMonitoring = false;
  
  // 监控配置
  static const Duration _monitorInterval = Duration(seconds: 30);
  static const int _maxConsecutiveErrors = 3;
  
  int _consecutiveErrors = 0;
  DateTime? _lastErrorTime;
  
  /// 启动后台播放监控
  void startMonitoring() {
    if (!Platform.isAndroid) return;
    
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitorTimer = Timer.periodic(_monitorInterval, _checkPlaybackHealth);
    
    globalTalker.info('[AndroidBackgroundPlaybackMonitor] 启动后台播放监控');
  }
  
  /// 停止后台播放监控
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;
    
    globalTalker.info('[AndroidBackgroundPlaybackMonitor] 停止后台播放监控');
  }
  
  /// 检查播放健康状态
  void _checkPlaybackHealth(Timer timer) {
    if (!_isMonitoring) return;
    
    final backgroundHelper = BackgroundPlaybackHelper();
    if (!backgroundHelper.isInBackground) return;
    
    // 检查是否有连续的错误
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      globalTalker.warning('[AndroidBackgroundPlaybackMonitor] 检测到连续播放错误，执行恢复操作');
      _performRecoveryActions();
    }
  }
  
  /// 记录播放错误
  void recordPlaybackError() {
    _consecutiveErrors++;
    _lastErrorTime = DateTime.now();
    
    globalTalker.warning('[AndroidBackgroundPlaybackMonitor] 记录播放错误，连续错误次数: $_consecutiveErrors');
    
    // 如果错误次数过多，立即执行恢复操作
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      _performRecoveryActions();
    }
  }
  
  /// 记录播放成功
  void recordPlaybackSuccess() {
    _consecutiveErrors = 0;
    _lastErrorTime = null;
  }
  
  /// 执行恢复操作
  void _performRecoveryActions() {
    globalTalker.info('[AndroidBackgroundPlaybackMonitor] 执行播放恢复操作');
    
    // 重置网络状态
    NetworkStabilityHelper().reset();
    
    // 清理播放错误记录
    AudioPlaybackRecoveryHelper().cleanupOldErrors();
    
    // 重置错误计数
    _consecutiveErrors = 0;
    _lastErrorTime = null;
    
    // 预热网络连接
    final backgroundHelper = BackgroundPlaybackHelper();
    backgroundHelper.markDidEnterBackground(); // 触发网络预热
  }
  
  /// 获取监控状态
  Map<String, dynamic> getMonitoringStatus() {
    return {
      'isMonitoring': _isMonitoring,
      'consecutiveErrors': _consecutiveErrors,
      'lastErrorTime': _lastErrorTime?.toIso8601String(),
      'isAndroid': Platform.isAndroid,
    };
  }
}