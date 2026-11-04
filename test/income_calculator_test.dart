import 'package:flutter_test/flutter_test.dart';
import 'package:second_salary/models/work_config.dart';
import 'package:second_salary/services/income_calculator.dart';

void main() {
  const standard = WorkConfig(
    salary: 21000,
    lunchHours: 1,
    overtimeHours: 0,
    mode: WorkMode.doubleRest,
  );

  test('November 2026 double rest has 21 weekdays', () {
    expect(IncomeCalculator.workDaysInMonth(2026, 11, WorkMode.doubleRest), 21);
    expect(IncomeCalculator.isoWeekNumber(DateTime(2026, 11, 1)), 44);
    expect(IncomeCalculator.isoWeekNumber(DateTime(2026, 11, 2)), 45);
  });

  test('rest rules follow the selected weekly pattern', () {
    final sunday = DateTime(2026, 11, 1);
    final saturday = DateTime(2026, 11, 7);
    final bigSunday = DateTime(2026, 11, 8);

    expect(IncomeCalculator.isWorkDay(saturday, WorkMode.doubleRest), isFalse);
    expect(IncomeCalculator.isWorkDay(saturday, WorkMode.singleRest), isTrue);
    expect(IncomeCalculator.isWorkDay(sunday, WorkMode.singleRest), isFalse);
    expect(IncomeCalculator.isWorkDay(sunday, WorkMode.bigSmallWeek), isFalse);
    expect(
      IncomeCalculator.isWorkDay(bigSunday, WorkMode.bigSmallWeek),
      isTrue,
    );
    expect(IncomeCalculator.workDaysInMonth(2026, 11, WorkMode.singleRest), 25);
    expect(
      IncomeCalculator.workDaysInMonth(2026, 11, WorkMode.bigSmallWeek),
      27,
    );
    expect(IncomeCalculator.workDaysInMonth(2026, 11, WorkMode.fullMonth), 30);
    expect(
      IncomeCalculator.workDaysInMonth(2026, 11, WorkMode.biweeklyRest),
      30,
    );
  });

  test('per-second income uses this month work seconds', () {
    final rate = IncomeCalculator.perSecondIncome(
      standard,
      DateTime(2026, 11, 2),
    );
    expect(rate, closeTo(21000 / (21 * 7 * 3600), 1e-12));
    final fullMonth = WorkConfig(
      salary: 21000,
      lunchHours: 1,
      overtimeHours: 0,
      mode: WorkMode.fullMonth,
    );
    expect(
      IncomeCalculator.perSecondIncome(fullMonth, DateTime(2026, 11, 2)) < rate,
      isTrue,
    );
  });

  test('paid seconds skip lunch and stop at the shift end', () {
    final day = DateTime(2026, 11, 2);
    expect(
      IncomeCalculator.paidSeconds(standard, day, DateTime(2026, 11, 2, 8)),
      0,
    );
    expect(
      IncomeCalculator.paidSeconds(standard, day, DateTime(2026, 11, 2, 10)),
      3600,
    );
    expect(
      IncomeCalculator.paidSeconds(
        standard,
        day,
        DateTime(2026, 11, 2, 12, 30),
      ),
      3 * 3600,
    );
    expect(
      IncomeCalculator.paidSeconds(
        standard,
        day,
        DateTime(2026, 11, 2, 13, 30),
      ),
      (3 * 3600) + 1800,
    );
    expect(
      IncomeCalculator.paidSeconds(standard, day, DateTime(2026, 11, 2, 18)),
      standard.dailyPaidSeconds,
    );

    final overtime = WorkConfig(
      salary: 21000,
      lunchHours: 1.25,
      overtimeHours: 2,
      mode: WorkMode.doubleRest,
    );
    expect(
      IncomeCalculator.paidSeconds(overtime, day, DateTime(2026, 11, 2, 23)),
      overtime.dailyPaidSeconds,
    );
    final snapshot = IncomeCalculator.snapshot(
      overtime,
      DateTime(2026, 11, 2, 18),
    );
    expect(snapshot.shiftEnd, DateTime(2026, 11, 2, 19));
    expect(snapshot.phase, ClockPhase.working);
    expect(snapshot.lunchEnd, DateTime(2026, 11, 2, 13, 15));
  });

  test('countdown and income follow the workday phase', () {
    final working = IncomeCalculator.snapshot(
      standard,
      DateTime(2026, 11, 4, 10),
    );
    expect(working.phase, ClockPhase.working);
    expect(working.countdown, const Duration(hours: 7));
    final rate = 21000 / (21 * 7 * 3600);
    expect(working.todayIncome, closeTo(3600 * rate, 1e-6));
    expect(working.weekIncome, closeTo(15 * 3600 * rate, 1e-6));
    expect(working.monthIncome, closeTo(working.weekIncome, 1e-6));

    final lunch = IncomeCalculator.snapshot(
      standard,
      DateTime(2026, 11, 4, 12, 30),
    );
    expect(lunch.phase, ClockPhase.lunch);
    expect(lunch.accruing, isFalse);

    final done = IncomeCalculator.snapshot(standard, DateTime(2026, 11, 4, 18));
    expect(done.phase, ClockPhase.offWork);
    expect(done.countdown, Duration.zero);
    expect(done.todayIncome, closeTo(7 * 3600 * rate, 1e-6));

    final rest = IncomeCalculator.snapshot(standard, DateTime(2026, 11, 7, 11));
    expect(rest.phase, ClockPhase.restDay);
    expect(rest.todayIncome, 0);
  });

  test('a week crossing months uses each month rate', () {
    final now = DateTime(2026, 11, 1, 12);
    final octoberRate = IncomeCalculator.perSecondIncome(
      standard,
      DateTime(2026, 10, 26),
    );
    final income = IncomeCalculator.summedIncome(
      standard,
      IncomeCalculator.startOfWeek(now),
      now,
    );
    expect(income, closeTo(5 * 7 * 3600 * octoberRate, 1e-4));
  });

  test('custom times change only today schedule and income', () {
    const custom = WorkConfig(
      salary: 21000,
      lunchHours: 1,
      overtimeHours: 0,
      mode: WorkMode.doubleRest,
      dayStartHour: 10,
      dayEndHour: 19,
    );
    final now = DateTime(2026, 11, 4, 14);
    final snapshot = IncomeCalculator.snapshot(custom, now);
    expect(snapshot.shiftStart, DateTime(2026, 11, 4, 10));
    expect(snapshot.shiftEnd, DateTime(2026, 11, 4, 19));
    expect(snapshot.countdown, const Duration(hours: 5));
    expect(snapshot.todayScheduledPaidSeconds, 8 * 3600);
    final rate = 21000 / (21 * 7 * 3600);
    expect(snapshot.todayIncome, closeTo(3 * 3600 * rate, 1e-6));
    expect(
      IncomeCalculator.paidSeconds(custom, DateTime(2026, 11, 3), now),
      7 * 3600,
    );

    const morningOnly = WorkConfig(
      salary: 21000,
      lunchHours: 1,
      overtimeHours: 0,
      mode: WorkMode.doubleRest,
      dayStartHour: 10,
    );
    final defaultEvening = IncomeCalculator.snapshot(
      morningOnly,
      DateTime(2026, 11, 4, 11),
    );
    expect(defaultEvening.shiftStart, DateTime(2026, 11, 4, 10));
    expect(defaultEvening.shiftEnd, DateTime(2026, 11, 4, 17));
  });

  test('saved config rejects values outside the form rules', () {
    expect(
      WorkConfig.tryParse({
        'salary': 8000,
        'lunchHours': 1.5,
        'overtimeHours': 2,
        'mode': 'singleRest',
      })?.mode,
      WorkMode.singleRest,
    );
    expect(
      WorkConfig.tryParse({
        'salary': 0,
        'lunchHours': 1,
        'overtimeHours': 0,
        'mode': 'doubleRest',
      }),
      isNull,
    );
    expect(
      WorkConfig.tryParse({
        'salary': 8000,
        'lunchHours': 3,
        'overtimeHours': 0,
        'mode': 'doubleRest',
      }),
      isNull,
    );
    expect(
      WorkConfig.tryParse({
        'salary': 8000,
        'lunchHours': 1,
        'overtimeHours': 1.5,
        'mode': 'doubleRest',
      })?.overtimeHours,
      1.5,
    );
    expect(
      WorkConfig.tryParse({
        'salary': 8000,
        'lunchHours': 1,
        'overtimeHours': 6.5,
        'mode': 'doubleRest',
      }),
      isNull,
    );
    expect(
      WorkConfig.tryParse({
        'salary': 8000,
        'lunchHours': 1,
        'overtimeHours': 0,
        'mode': 'doubleRest',
        'dayStartHour': 0,
        'dayEndHour': 18.5,
      })?.dayEndHour,
      18.5,
    );
    expect(
      WorkConfig.tryParse({
        'salary': 8000,
        'lunchHours': 1,
        'overtimeHours': 0,
        'mode': 'doubleRest',
        'dayStartHour': 0,
        'dayEndHour': 18.5,
      })?.dayStartHour,
      0,
    );
    expect(
      WorkConfig.tryParse({
        'salary': 8000,
        'lunchHours': 1,
        'overtimeHours': 0,
        'mode': 'doubleRest',
        'dayStartHour': 18,
        'dayEndHour': 9,
      }),
      isNull,
    );
  });
}
