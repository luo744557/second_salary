/// 休假方式。四种可选方式互斥，都不选时按双休计算。
enum WorkMode {
  /// 每周五天，周一至周五。
  doubleRest,

  /// 每周六天，周一至周六。
  singleRest,

  /// 奇数 ISO 周工作七天，偶数 ISO 周工作六天（周日休息）。
  bigSmallWeek,

  /// 按每周七天计入当月。
  biweeklyRest,

  /// 按当月全部天数计入。
  fullMonth;

  static WorkMode? parse(String? raw) {
    if (raw == null) {
      return null;
    }
    for (final mode in WorkMode.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return null;
  }

  String get label => switch (this) {
    WorkMode.doubleRest => '双休',
    WorkMode.singleRest => '单休',
    WorkMode.bigSmallWeek => '大小周',
    WorkMode.biweeklyRest => '两周休一次',
    WorkMode.fullMonth => '整月无休',
  };

  String get detail => switch (this) {
    WorkMode.doubleRest => '每周五天，周一至周五',
    WorkMode.singleRest => '每周六天，周一至周六',
    WorkMode.bigSmallWeek => '奇数周七天，偶数周六天（周日休息）',
    WorkMode.biweeklyRest => '按每周七天计入当月',
    WorkMode.fullMonth => '按当月全部天数计入',
  };
}

/// 用户确认后的工资与工时规则。
class WorkConfig {
  const WorkConfig({
    required this.salary,
    required this.lunchHours,
    required this.overtimeHours,
    required this.mode,
    this.dayStartHour,
    this.dayEndHour,
    this.showFloatPerSecond = true,
  });

  /// 标准在岗时长，午休包含在这 8 小时内，不计薪。
  static const baseHours = 8.0;

  /// 上班时间。早九。
  static const shiftStartHour = 9;

  /// 下班时间。晚五。加班加在这之后。
  static const shiftEndHour = 17;

  /// 午休开始时间。
  static const lunchStartHour = 12;

  /// 加班上限，保证 09:00 开始的班次在当天结束。
  static const maxOvertimeHours = 6;

  /// 月工资，单位元。
  final int salary;

  /// 每日午休时长，单位小时。可以是整数，也可以带最多两位小数。
  final double lunchHours;

  /// 每日加班时长，单位小时。可以是整数，也可以带最多两位小数。0 表示不加班。
  final double overtimeHours;

  /// 当天上班时间，从 0 点起算的小时。为空时按 09:00。
  final double? dayStartHour;

  /// 当天下班时间，从 0 点起算的小时。为空时按晚五 17:00，加班再往后加。
  final double? dayEndHour;

  /// 悬浮窗是否显示「每秒加多少元」。关闭后窗口会收小。
  final bool showFloatPerSecond;

  final WorkMode mode;

  /// 每日计薪工时：8 小时减去午休，再加上加班。
  double get dailyPaidHours => baseHours - lunchHours + overtimeHours;

  int get dailyPaidSeconds => (dailyPaidHours * 3600).round();

  int get lunchSeconds => (lunchHours * 3600).round();

  /// 人在岗的时钟长度：8 小时加上加班，午休发生在其中。
  int get grossShiftSeconds => ((baseHours + overtimeHours) * 3600).round();

  Map<String, Object> toJson() => {
    'salary': salary,
    'lunchHours': lunchHours,
    'overtimeHours': overtimeHours,
    'mode': mode.name,
    'dayStartHour': ?dayStartHour,
    'dayEndHour': ?dayEndHour,
    'showFloatPerSecond': showFloatPerSecond,
  };

  static WorkConfig? tryParse(Map<String, dynamic> json) {
    final salary = json['salary'];
    final lunch = json['lunchHours'];
    final overtime = json['overtimeHours'];
    final mode = WorkMode.parse(json['mode']?.toString());
    if (salary is! int || salary <= 0 || mode == null || lunch is! num) {
      return null;
    }
    if (overtime is! num) {
      return null;
    }
    final lunchHours = (lunch.toDouble() * 100).round() / 100;
    final overtimeHours = (overtime.toDouble() * 100).round() / 100;
    final startRead = _readOptionalHour(json['dayStartHour']);
    final endRead = _readOptionalHour(json['dayEndHour']);
    if (!startRead.ok || !endRead.ok) {
      return null;
    }
    final start = startRead.hours;
    final end = endRead.hours;
    if (lunchHours < 0.5 ||
        lunchHours > 2.5 ||
        overtimeHours < 0 ||
        overtimeHours > maxOvertimeHours ||
        !_sameDaySchedule(start, end, overtimeHours)) {
      return null;
    }
    return WorkConfig(
      salary: salary,
      lunchHours: lunchHours,
      overtimeHours: overtimeHours,
      mode: mode,
      dayStartHour: start,
      dayEndHour: end,
      showFloatPerSecond: json['showFloatPerSecond'] is bool
          ? json['showFloatPerSecond'] as bool
          : true,
    );
  }

  /// 缺失视为未填写。0 表示当天 00:00。
  static ({double? hours, bool ok}) _readOptionalHour(Object? raw) {
    if (raw == null) {
      return (hours: null, ok: true);
    }
    if (raw is! num) {
      return (hours: null, ok: false);
    }
    final hours = (raw.toDouble() * 100).round() / 100;
    if (hours < 0 || hours > 24) {
      return (hours: null, ok: false);
    }
    return (hours: hours, ok: true);
  }

  static bool _sameDaySchedule(
    double? start,
    double? end,
    double overtimeHours,
  ) {
    final resolvedStart = start ?? shiftStartHour.toDouble();
    final resolvedEnd = end ?? shiftEndHour + overtimeHours;
    return resolvedEnd > resolvedStart && resolvedEnd <= 24;
  }
}
