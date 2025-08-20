import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';

class Badge extends StatelessWidget {
  final String label;
  final VoidCallback? onClick;
  final bool isDarkMode;

  const Badge({
    super.key,
    required this.label,
    this.onClick,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // 性能优化：使用const构造函数和预先计算的样式
    final backgroundColor =
        isDarkMode ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.56);
    final textColor = isDarkMode ? Colors.black : Colors.white;

    // 使用GestureDetector的behavior属性优化点击区域
    return GestureDetector(
      key: const Key('badge_gesture_detector'),
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: Container(
        key: const Key('badge_container'),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          key: Key('badge_text_${label.hashCode}'),
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ).useSystemChineseFont().copyWith(color: textColor),
        ),
      ),
    );
  }
}
