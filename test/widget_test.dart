import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show TextField;
import 'package:flutter_test/flutter_test.dart';
import 'package:second_salary/app.dart';
import 'package:second_salary/services/config_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch opens the salary form', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SecondSalaryApp());
    try {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('用户工资'), findsOneWidget);
      expect(find.text('日常午休时长'), findsOneWidget);
      expect(find.text('双休'), findsOneWidget);
      expect(find.text('单休'), findsOneWidget);
      expect(find.text('大小周'), findsOneWidget);
      expect(find.text('两周休一次'), findsOneWidget);
      expect(find.text('整月无休'), findsOneWidget);
      expect(find.text('悬浮窗每秒收入'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('rules appear after salary and lunch are filled', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SecondSalaryApp());
    try {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('本月计算规则'), findsNothing);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '8000');
      await tester.pump();
      expect(find.text('本月计算规则'), findsNothing);
      await tester.enterText(fields.at(1), '1');
      await tester.pump();
      expect(find.text('本月计算规则'), findsOneWidget);
      expect(find.textContaining('每秒收入 ='), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('saved config opens the income page', (tester) async {
    SharedPreferences.setMockInitialValues({
      configStorageKey: jsonEncode({
        'salary': 12000,
        'lunchHours': 1.0,
        'overtimeHours': 1,
        'mode': 'singleRest',
      }),
    });
    await tester.pumpWidget(const SecondSalaryApp());
    try {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('下班倒计时'), findsOneWidget);
      expect(find.text('今日收入'), findsOneWidget);
      expect(find.text('本周累计'), findsOneWidget);
      expect(find.text('本月累计'), findsOneWidget);
      expect(find.text('每秒工作收入'), findsOneWidget);
      expect(find.text('本月计算规则'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('income page fits portrait and landscape windows', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      configStorageKey: jsonEncode({
        'salary': 12000,
        'lunchHours': 1.0,
        'overtimeHours': 1,
        'mode': 'singleRest',
      }),
    });
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const SecondSalaryApp());
    try {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('下班倒计时'), findsOneWidget);
      await tester.binding.setSurfaceSize(const Size(1100, 620));
      await tester.pump();
      expect(find.text('本月累计'), findsOneWidget);
      expect(find.text('本月计算规则'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
