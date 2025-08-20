import 'package:app_rhyme/utils/const_vars.dart';

String sourceToShort(String source) {
  switch (source) {
    case sourceWangYi:
      return 'wy';
    default:
      return source;
  }
}
