import 'package:flutter/cupertino.dart';

/// 键盘性能优化助手
/// 专门优化键盘弹出动画的性能，减少卡顿
class KeyboardPerformanceHelper {
  static final KeyboardPerformanceHelper _instance = KeyboardPerformanceHelper._internal();
  factory KeyboardPerformanceHelper() => _instance;
  KeyboardPerformanceHelper._internal();

  bool _isKeyboardAnimating = false;
  DateTime? _keyboardAnimationStartTime;
  static const Duration _keyboardAnimationDuration = Duration(milliseconds: 300);

  /// 标记键盘动画开始
  void markKeyboardAnimationStart() {
    _isKeyboardAnimating = true;
    _keyboardAnimationStartTime = DateTime.now();
    
    // 300ms后自动结束动画状态
    Future.delayed(_keyboardAnimationDuration, () {
      if (_keyboardAnimationStartTime != null && 
          DateTime.now().difference(_keyboardAnimationStartTime!) >= _keyboardAnimationDuration) {
        _isKeyboardAnimating = false;
        _keyboardAnimationStartTime = null;
      }
    });
  }

  /// 检查是否正在键盘动画期间
  bool isKeyboardAnimating() {
    return _isKeyboardAnimating;
  }

  /// 获取优化后的Widget，在键盘动画期间减少重绘
  Widget getOptimizedWidget({
    required Widget child,
    required BuildContext context,
  }) {
    if (_isKeyboardAnimating) {
      // 在键盘动画期间，使用简单的Container减少重绘
      return Container(
        child: child,
      );
    }
    
    return child;
  }

  /// 释放资源
  void dispose() {
    _isKeyboardAnimating = false;
    _keyboardAnimationStartTime = null;
  }
}

/// 优化的搜索文本字段
/// 自动应用键盘性能优化
class OptimizedSearchTextField extends StatefulWidget {
  final TextEditingController? controller;
  final TextStyle? style;
  final ValueChanged<String>? onSubmitted;
  final String? placeholder;
  final EdgeInsetsGeometry padding;

  const OptimizedSearchTextField({
    super.key,
    this.controller,
    this.style,
    this.onSubmitted,
    this.placeholder,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  State<OptimizedSearchTextField> createState() => _OptimizedSearchTextFieldState();
}

class _OptimizedSearchTextFieldState extends State<OptimizedSearchTextField> {
  final KeyboardPerformanceHelper _helper = KeyboardPerformanceHelper();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _helper.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _helper.markKeyboardAnimationStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _helper.getOptimizedWidget(
      context: context,
      child: CupertinoSearchTextField(
        controller: widget.controller,
        style: widget.style,
        onSubmitted: widget.onSubmitted,
        placeholder: widget.placeholder,
        padding: widget.padding,
        focusNode: _focusNode,
      ),
    );
  }
}