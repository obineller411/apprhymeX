import 'dart:developer';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/services.dart';

class ColorExtractor {
  static const Color defaultStartColor = Color(0xFF212121); // Gray 900
  static const Color defaultEndColor = Color(0xFF383838);   // Gray 600

  static LinearGradient defaultGradient = const LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [defaultStartColor, defaultEndColor],
  );

  /// Adjusts color to be more vibrant if it's too desaturated.
  static Color _adjustColor(Color color) {
    final hslColor = HSLColor.fromColor(color);
    // If the color is too gray (low saturation), give it a boost.
    if (hslColor.saturation < 0.15) {
      return hslColor
          .withSaturation((hslColor.saturation + 0.3).clamp(0.0, 1.0))
          .withLightness((hslColor.lightness + 0.1).clamp(0.0, 1.0))
          .toColor();
    }
    // If the color is too dark, lighten it up a bit for a better UI experience.
    if (hslColor.lightness < 0.2) {
      return hslColor
          .withLightness((hslColor.lightness + 0.2).clamp(0.0, 1.0))
          .toColor();
    }
    return color;
  }

  /// Extract dominant colors from an image URL or file path
  static Future<LinearGradient> extractThemeGradient(String? imageUrl) async {
    try {
      if (imageUrl == null || imageUrl.isEmpty) {
        log('[ColorExtractor] [extractThemeGradient] URL is null or empty, using default gradient');
        return defaultGradient;
      }

      log('[ColorExtractor] [extractThemeGradient] Starting color extraction for: $imageUrl');

      // Load the image
      final ImageProvider imageProvider;
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        log('[ColorExtractor] [extractThemeGradient] Loading as NetworkImage: $imageUrl');
        imageProvider = NetworkImage(imageUrl);
      } else {
        final file = File(imageUrl);
        if (await file.exists()) {
          log('[ColorExtractor] [extractThemeGradient] Loading as FileImage (file exists): $imageUrl');
          imageProvider = FileImage(file);
        } else if (imageUrl.startsWith('assets/')) {
          log('[ColorExtractor] [extractThemeGradient] Loading as AssetImage: $imageUrl');
          imageProvider = AssetImage(imageUrl);
        } else {
          log('[ColorExtractor] [extractThemeGradient] Assuming NetworkImage (fallback, or malformed local path): $imageUrl');
          imageProvider = NetworkImage(imageUrl);
        }
      }

      log('[ColorExtractor] [extractThemeGradient] Before PaletteGenerator.fromImageProvider for: $imageUrl');
      print('[ColorExtractor] [extractThemeGradient] Before PaletteGenerator.fromImageProvider for: $imageUrl');
      // Generate palette
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100), // Further reduced size for performance
        // region: Rect.zero, // Removed problematic region parameter
      );
      log('[ColorExtractor] [extractThemeGradient] After PaletteGenerator.fromImageProvider for: $imageUrl');
      print('[ColorExtractor] [extractThemeGradient] After PaletteGenerator.fromImageProvider for: $imageUrl');

      log('[ColorExtractor] [extractThemeGradient] Palette generation completed for: $imageUrl');
      print('[ColorExtractor] [extractThemeGradient] Palette generation completed for: $imageUrl');

      // Check if we have any colors
      if (paletteGenerator.paletteColors.isEmpty) {
        log('[ColorExtractor] [extractThemeGradient] No colors found in palette for: $imageUrl, using default gradient');
        print('[ColorExtractor] [extractThemeGradient] No colors found in palette for: $imageUrl, using default gradient');
        return defaultGradient;
      }

      Color selectedStartColor = defaultStartColor;
      Color selectedEndColor = defaultEndColor;

      // Helper to get the color, prioritizing non-null and vibrant/muted
      Color? getColor(PaletteColor? paletteColor) => paletteColor?.color;

      // Prioritize light and dark muted/vibrant colors for a softer gradient
      Color? color1 = getColor(paletteGenerator.lightVibrantColor) ??
                       getColor(paletteGenerator.vibrantColor) ??
                       getColor(paletteGenerator.lightMutedColor) ??
                       getColor(paletteGenerator.mutedColor);


      Color? color2 = getColor(paletteGenerator.darkVibrantColor) ??
                       getColor(paletteGenerator.darkMutedColor);

      if (color1 != null && color2 != null) {
        selectedStartColor = _adjustColor(color1);
        selectedEndColor = _adjustColor(color2);
        log('[ColorExtractor] [extractThemeGradient] Found two distinct colors from muted/vibrant palette for: $imageUrl');
        print('[ColorExtractor] [extractThemeGradient] Found two distinct colors from muted/vibrant palette for: $imageUrl');
      } else if (color1 != null) {
        selectedStartColor = _adjustColor(color1);
        // Derive a second color if only one strong color is found
        selectedEndColor = HSLColor.fromColor(selectedStartColor)
            .withLightness((HSLColor.fromColor(selectedStartColor).lightness * 0.7).clamp(0.0, 1.0))
            .toColor();
        log('[ColorExtractor] [extractThemeGradient] Found one strong color, deriving second for: $imageUrl');
        print('[ColorExtractor] [extractThemeGradient] Found one strong color, deriving second for: $imageUrl');
      } else if (color2 != null) {
        selectedStartColor = _adjustColor(color2);
        selectedEndColor = HSLColor.fromColor(selectedStartColor)
            .withLightness((HSLColor.fromColor(selectedStartColor).lightness * 1.3).clamp(0.0, 1.0))
            .toColor();
        log('[ColorExtractor] [extractThemeGradient] Found one strong color (dark/vibrant), deriving second for: $imageUrl');
        print('[ColorExtractor] [extractThemeGradient] Found one strong color (dark/vibrant), deriving second for: $imageUrl');
      } else if (paletteGenerator.dominantColor != null) {
        selectedStartColor = _adjustColor(paletteGenerator.dominantColor!.color);
        // Derive a second color based on dominant color
        selectedEndColor = HSLColor.fromColor(selectedStartColor)
            .withLightness((HSLColor.fromColor(selectedStartColor).lightness * 0.7).clamp(0.0, 1.0))
            .toColor();
        log('[ColorExtractor] [extractThemeGradient] Using dominant color and deriving second for: $imageUrl');
        print('[ColorExtractor] [extractThemeGradient] Using dominant color and deriving second for: $imageUrl');
      } else if (paletteGenerator.paletteColors.isNotEmpty) {
        selectedStartColor = _adjustColor(paletteGenerator.paletteColors.first.color);
        if (paletteGenerator.paletteColors.length > 1) {
          selectedEndColor = _adjustColor(paletteGenerator.paletteColors[1].color);
        } else {
          selectedEndColor = HSLColor.fromColor(selectedStartColor)
              .withLightness((HSLColor.fromColor(selectedStartColor).lightness * 0.7).clamp(0.0, 1.0))
              .toColor();
        }
        log('[ColorExtractor] [extractThemeGradient] Using first two palette colors or deriving second for: $imageUrl');
        print('[ColorExtractor] [extractThemeGradient] Using first two palette colors or deriving second for: $imageUrl');
      } else {
        log('[ColorExtractor] [extractThemeGradient] No suitable colors found, using default gradient for: $imageUrl');
        print('[ColorExtractor] [extractThemeGradient] No suitable colors found, using default gradient for: $imageUrl');
        return defaultGradient;
      }

      log('[ColorExtractor] [extractThemeGradient] Final gradient colors for: $imageUrl: $selectedStartColor, $selectedEndColor');
      print('[ColorExtractor] [extractThemeGradient] Final gradient colors for: $imageUrl: $selectedStartColor, $selectedEndColor');

      return LinearGradient(
        begin: Alignment.topLeft, // Changed to topLeft for a different gradient direction
        end: Alignment.bottomRight, // Changed to bottomRight
        colors: [selectedStartColor, selectedEndColor],
      );

    } catch (e, stackTrace) {
      log('[ColorExtractor] [extractThemeGradient] Error extracting colors for $imageUrl: $e\n$stackTrace');
      print('[ColorExtractor] [extractThemeGradient] Error extracting colors for $imageUrl: $e\n$stackTrace');
      return defaultGradient;
    }
  }
  /// Static cached results to avoid re-processing the same image
  static Map<String, LinearGradient> _gradientCache = {};

  /// Extract and cache gradient for better performance
  static Future<LinearGradient> extractAndCacheGradient(String? imageUrl, {String? cacheKey}) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      print('[ColorExtractor] [extractAndCacheGradient] imageUrl is null or empty, returning default gradient.');
      return defaultGradient;
    }

    // Use custom cache key or default to image URL
    final key = cacheKey ?? imageUrl;

    // Check cache first
    if (_gradientCache.containsKey(key)) {
      log('[ColorExtractor] [extractAndCacheGradient] Using cached gradient for: $key');
      print('[ColorExtractor] [extractAndCacheGradient] Using cached gradient for: $key');
      return _gradientCache[key]!;
    }

    // Extract and cache
    final gradient = await extractThemeGradient(imageUrl);
    _gradientCache[key] = gradient;

    log('[ColorExtractor] [extractAndCacheGradient] Cached gradient for: $key');
    print('[ColorExtractor] [extractAndCacheGradient] Cached gradient for: $key');
    return gradient;
  }

  /// Synchronously get cached gradient
  static LinearGradient? getCachedGradient(String? cacheKey) {
    if (cacheKey == null || cacheKey.isEmpty) {
      return null;
    }
    return _gradientCache[cacheKey];
  }

  /// Clear cache when needed (e.g., when memory is low)
  static void clearCache() {
    _gradientCache.clear();
    log('[ColorExtractor] Cache cleared');
    print('[ColorExtractor] Cache cleared');
  }
}
