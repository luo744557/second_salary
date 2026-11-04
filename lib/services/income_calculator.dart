import '../models/work_config.dart';

/// 当前这一秒处于班次中的哪一段。
enum ClockPhase {
  beforeWork('未上班'),
  working('距离下班'),
  lunch('午休中'),
  offWork('已下班'),
  restDay('今日休息');

  const ClockPhase(this.label);

  final String label;
}

/// 某个时刻的收入与倒计时快照。金额全部由时间推算，不依赖定时器累加。
class IncomeSnapshot {
  const IncomeSnapshot({
    required this.now,
    required this.perSecond,
    required this.todayIncome,
    required this.weekIncome,
    required this.monthIncome,
    required this.countdown,
    required this.phase,
    required this.workDays,
    required this.shiftStart,
    required this.shiftEnd,
    required this.lunchStart,
    required this.lunchEnd,
  });

  final DateTime now;
  final double perSecond;
  final double todayIncome;
  final double weekIncome;
  final double monthIncome;
  final Duration countdown;
  final ClockPhase phase;
  final int workDays;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final DateTime lunchStart;
  final DateTime lunchEnd;

  bool get accruing => phase == ClockPhase.working;
}

class _Shift {
  const _Shift({
    required this.start,
    required this.lunchStart,
    required this.lunchEnd,
    required this.end,
  });

  final DateTime start;
  final DateTime lunchStart;
  final DateTime lunchEnd;
  final DateTime end;

  static _Shift of(DateTime day, WorkConfig config) {
    final date = DateTime(day.year, day.month, day.day);
    final start = date.add(const Duration(hours: WorkConfig.shiftStartHour));
    final lunchStart = date.add(
      const Duration(hours: WorkConfig.lunchStartHour),
    );
    return _Shift(
      start: start,
      lunchStart: lunchStart,
      lunchEnd: lunchStart.add(Duration(seconds: config.lunchSeconds)),
      end: start.add(Duration(seconds: config.grossShiftSeconds)),
    );
  }
}

/// 按当前月份的工作日和每日计薪秒数，把月工资拆成每秒收入。
class IncomeCalculator {
  const IncomeCalculator._();

  static IncomeSnapshot snapshot(WorkConfig config, DateTime now) {
    final shift = _Shift.of(now, config);
    final phase = _phase(config, now, shift);
    final today = DateTime(now.year, now.month, now.day);
    return IncomeSnapshot(
      now: now,
      perSecond: perSecondIncome(config, now),
      todayIncome: _incomeOn(config, today, now),
      weekIncome: summedIncome(config, startOfWeek(today), now),
      monthIncome: summedIncome(
        config,
        DateTime(today.year, today.month, 1),
        now,
      ),
      countdown: phase == ClockPhase.restDay || !now.isBefore(shift.end)
          ? Duration.zero
          : shift.end.difference(now),
      phase: phase,
      workDays: workDaysInMonth(now.year, now.month, config.mode),
      shiftStart: shift.start,
      shiftEnd: shift.end,
      lunchStart: shift.lunchStart,
      lunchEnd: shift.lunchEnd,
    );
  }

  static double perSecondIncome(WorkConfig config, DateTime date) {
    final seconds =
        workDaysInMonth(date.year, date.month, config.mode) *
        config.dailyPaidSeconds;
    if (seconds <= 0) {
      return 0;
    }
    return config.salary / seconds;
  }

  static int workDaysInMonth(int year, int month, WorkMode mode) {
    final days = DateTime(year, month + 1, 0).day;
    var count = 0;
    for (var day = 1; day <= days; day++) {
      if (isWorkDay(DateTime(year, month, day), mode)) {
        count++;
      }
    }
    return count;
  }

  static bool isWorkDay(DateTime date, WorkMode mode) {
    switch (mode) {
      case WorkMode.doubleRest:
        return date.weekday <= DateTime.friday;
      case WorkMode.singleRest:
        return date.weekday != DateTime.sunday;
      case WorkMode.bigSmallWeek:
        if (isoWeekNumber(date).isOdd) {
          return true;
        }
        return date.weekday != DateTime.sunday;
      case WorkMode.biweeklyRest:
      case WorkMode.fullMonth:
        return true;
    }
  }

  /// ISO 周序号。奇数周为大周（七天），偶数周为小周（六天）。
  static int isoWeekNumber(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
    final januaryFourth = DateTime.utc(thursday.year, 1, 4);
    final weekOneThursday = januaryFourth.subtract(
      Duration(days: januaryFourth.weekday - DateTime.thursday),
    );
    return 1 + thursday.difference(weekOneThursday).inDays ~/ 7;
  }

  static DateTime startOfWeek(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  /// 从 [from] 这一天到 [now] 所在日期，按各自月份的每秒收入累加。
  static double summedIncome(WorkConfig config, DateTime from, DateTime now) {
    var total = 0.0;
    var day = DateTime(from.year, from.month, from.day);
    final today = DateTime(now.year, now.month, now.day);
    while (!day.isAfter(today)) {
      total += _incomeOn(config, day, now);
      day = day.add(const Duration(days: 1));
    }
    return total;
  }

  /// [day] 这个班次在 [now] 之前已经计入的计薪秒数。
  static int paidSeconds(WorkConfig config, DateTime day, DateTime now) {
    if (!isWorkDay(day, config.mode)) {
      return 0;
    }
    final shift = _Shift.of(day, config);
    return _overlapSeconds(shift.start, shift.lunchStart, now) +
        _overlapSeconds(shift.lunchEnd, shift.end, now);
  }

  static double _incomeOn(WorkConfig config, DateTime day, DateTime now) {
    final seconds = paidSeconds(config, day, now);
    if (seconds <= 0) {
      return 0;
    }
    return seconds * perSecondIncome(config, day);
  }

  static int _overlapSeconds(DateTime start, DateTime end, DateTime now) {
    if (!now.isAfter(start) || !end.isAfter(start)) {
      return 0;
    }
    final clipped = now.isBefore(end) ? now : end;
    final seconds = clipped.difference(start).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  static ClockPhase _phase(WorkConfig config, DateTime now, _Shift shift) {
    if (!isWorkDay(now, config.mode)) {
      return ClockPhase.restDay;
    }
    if (now.isBefore(shift.start)) {
      return ClockPhase.beforeWork;
    }
    if (!now.isBefore(shift.end)) {
      return ClockPhase.offWork;
    }
    if (!now.isBefore(shift.lunchStart) && now.isBefore(shift.lunchEnd)) {
      return ClockPhase.lunch;
    }
    return ClockPhase.working;
  }
}
