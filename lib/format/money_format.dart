import 'package:flutter/material.dart';

TextStyle incomeNumberStyle({
  required double fontSize,
  required Color color,
  List<Shadow>? shadows,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
    shadows: shadows,
  );
}

String formatYuan(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buffer = StringBuffer(negative ? '-¥' : '¥');
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    if (index > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }
  buffer
    ..write('.')
    ..write(parts[1]);
  return buffer.toString();
}

String formatPerSecond(double value) {
  final sign = value < 0 ? '-' : '+';
  return '$sign${value.abs().toStringAsFixed(6)}';
}

String formatClock(Duration duration) {
  final total = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String formatHours(double hours) => '${formatHourValue(hours)} 小时';

/// 整数不带小数，其余去掉末尾的 0，例如 1、1.5、1.25。
String formatHourValue(double hours) {
  final rounded = (hours * 100).round() / 100;
  if (rounded == rounded.roundToDouble()) {
    return rounded.toInt().toString();
  }
  return rounded.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

String formatDateTime(DateTime time) {
  const weeks = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  final second = time.second.toString().padLeft(2, '0');
  return '${time.year}年${time.month}月${time.day}日 '
      '${weeks[time.weekday - 1]} $hour:$minute:$second';
}

String formatClockTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
