import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/work_config.dart';

const configStorageKey = 'second_salary.work_config';

/// 把工资规则保存在本机，下次启动直接恢复。
class ConfigRepository {
  const ConfigRepository();

  Future<WorkConfig?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(configStorageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return WorkConfig.tryParse(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(WorkConfig config) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(configStorageKey, jsonEncode(config.toJson()));
  }
}
