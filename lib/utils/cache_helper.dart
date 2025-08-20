import 'dart:io';
import 'dart:developer' as developer;

import 'package:app_rhyme/src/rust/api/cache/file_cache.dart';
import 'package:app_rhyme/utils/const_vars.dart';
import 'package:app_rhyme/utils/global_vars.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';

// 将url转换为本地缓存路径
// 如果本地缓存存在，则返回本地缓存路径
// 如果本地缓存不存在，则返回原始url
// 如果cacheNow为true，则立即缓存文件, 并返回原始url
String _useFileCacheHelper(String url, String cacheRoot,
    {String? filename, bool cacheNow = false}) {
  var localSource = useCacheFile(
      file: url,
      cachePath: cacheRoot,
      filename: filename,
      exportRoot: globalConfig.exportCacheRoot);

  if (localSource != null) {
    return localSource;
  } else {
    if (cacheNow) {
      cacheFileHelper(url, cacheRoot, filename: filename);
    }
    return url;
  }
}

Future<String> cacheFileHelper(String url, String cacheRoot,
    {String? filename}) async {
  return await cacheFile(
    file: url,
    cachePath: cacheRoot,
    filename: filename,
    exportRoot: globalConfig.exportCacheRoot,
  );
}

Future<void> deleteFileCacheHelper(String url, String cacheRoot,
    {String? filename}) async {
  await deleteCacheFile(
    file: url,
    cachePath: cacheRoot,
    filename: filename,
    exportRoot: globalConfig.exportCacheRoot,
  );
}

ExtendedImage imageCacheHelper(
  String? url, {
  bool cacheNow = false,
  double? width,
  double? height,
  BoxFit? fit,
  double? scale = 1.0,
  BorderRadius? borderRadius,
}) {
  developer.log('[图片缓存] 开始加载图片: url=$url, cacheNow=$cacheNow', name: 'ImageCacheHelper');
  
  // 先判断url是否为空
  if (url == null || url.isEmpty) {
    developer.log('[图片缓存] URL为空，使用默认图片: $defaultArtPicPath', name: 'ImageCacheHelper');
    return ExtendedImage.asset(
      defaultArtPicPath,
      width: width,
      height: height,
      fit: fit,
      scale: scale,
      borderRadius: borderRadius,
    );
  }
  
  // 检查是否为资产路径
  if (url.startsWith("assets/")) {
    developer.log('[图片缓存] 检测到资产路径，直接使用ExtendedImage.asset: $url', name: 'ImageCacheHelper');
    return ExtendedImage.asset(
      url,
      width: width,
      height: height,
      fit: fit,
      scale: scale,
      borderRadius: borderRadius,
    );
  }
  
  String? uri = _useFileCacheHelper(url, picCacheRoot, cacheNow: cacheNow);
  developer.log('[图片缓存] 文件缓存处理结果: 原始url=$url, 处理后uri=$uri', name: 'ImageCacheHelper');

  if (uri.startsWith("http")) {
    developer.log('[图片缓存] 使用网络图片加载: $uri', name: 'ImageCacheHelper');
    return ExtendedImage.network(
      uri,
      width: width,
      height: height,
      fit: fit,
      scale: scale ?? 1.0,
      enableMemoryCache: true,
      // 优化内存缓存配置
      cacheRawData: true,
      // 减少重绘，提升性能
      filterQuality: FilterQuality.low,
      borderRadius: borderRadius,
      // 优化加载状态，减少转圈效果
      // 性能优化：使用const构造函数减少Widget重建
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            // 对于本地文件，不显示占位符，避免闪烁
            if (!uri.startsWith("http")) {
              return null;
            }
            // 对于网络图片，使用简化的占位符
            return _buildImagePlaceholder(width, height, borderRadius, 0.4);
          case LoadState.completed:
            // 直接返回null使用默认的completed状态，避免重复创建Widget
            return null;
          case LoadState.failed:
            return _buildImagePlaceholder(width, height, borderRadius, 0.5);
        }
      },
    );
  } else {
    developer.log('[图片缓存] 使用本地文件加载: $uri', name: 'ImageCacheHelper');
    try {
      return ExtendedImage.file(
        File(uri),
        width: width,
        height: height,
        fit: fit,
        scale: scale ?? 1.0,
        // 本地文件优化配置
        enableMemoryCache: true,
        filterQuality: FilterQuality.low,
        borderRadius: borderRadius,
        // 本地文件通常加载很快，简化加载状态
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              developer.log('[图片缓存] 本地文件加载中: $uri', name: 'ImageCacheHelper');
              return _buildImagePlaceholder(width, height, borderRadius, 0.4);
            case LoadState.completed:
              developer.log('[图片缓存] 本地文件加载完成: $uri', name: 'ImageCacheHelper');
              // 直接返回null使用默认的completed状态，避免重复创建Widget
              return null;
            case LoadState.failed:
              developer.log('[图片缓存] 本地文件加载失败: $uri', name: 'ImageCacheHelper');
              return _buildImagePlaceholder(width, height, borderRadius, 0.5);
          }
        },
      );
    } catch (e) {
      developer.log('[图片缓存] 本地文件加载异常: $uri, 错误: $e', name: 'ImageCacheHelper');
      // 如果本地文件加载失败，返回默认图片
      return ExtendedImage.asset(
        defaultArtPicPath,
        width: width,
        height: height,
        fit: fit,
        scale: scale,
        borderRadius: borderRadius,
      );
    }
  }
}


// 性能优化：图片占位符Widget，减少重复代码
Widget _buildImagePlaceholder(double? width, double? height, BorderRadius? borderRadius, double iconScale) {
  // 修复字体大小无限值错误
  double? effectiveWidth = width;
  if (effectiveWidth == null || !effectiveWidth.isFinite || effectiveWidth <= 0) {
    effectiveWidth = 40;
  }
  
  double iconSize = effectiveWidth * iconScale;
  // 确保字体大小是有限值
  if (!iconSize.isFinite || iconSize <= 0) {
    iconSize = 16;
  }
  
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: CupertinoColors.systemGrey6,
      borderRadius: borderRadius,
    ),
    child: Center(
      child: Icon(
        CupertinoIcons.music_note,
        size: iconSize,
        color: iconScale == 0.4 ? CupertinoColors.systemGrey4 : CupertinoColors.systemGrey3,
      ),
    ),
  );
}
