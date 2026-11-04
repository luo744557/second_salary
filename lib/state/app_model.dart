import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/work_config.dart';
import '../services/config_repository.dart';
import '../services/desktop_window.dart';
import '../services/income_calculator.dart';

class AppModel extends ChangeNotifier with WidgetsBindingObserver {
  AppModel({ConfigRepository? repository, DateTime Function()? clock})
    : _repository = repository ?? const ConfigRepository(),
      _clock = clock ?? DateTime.now;

  final ConfigRepository _repository;
  final DateTime Function() _clock;

  WorkConfig? config;
  bool ready = false;
  bool editing = false;
  bool floating = false;
  bool maximized = false;
  DateTime now = DateTime.now();

  Timer? _align;
  Timer? _timer;
  bool _disposed = false;
  bool _observing = false;
  bool _windowBusy = false;
  bool _closing = false;

  IncomeSnapshot? get snapshot {
    final current = config;
    if (current == null) {
      return null;
    }
    return IncomeCalculator.snapshot(current, now);
  }

  Future<void> bootstrap() async {
    final loaded = await _repository.load();
    if (_disposed) {
      return;
    }
    config = loaded;
    now = _truncated(_clock());
    ready = true;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
    _scheduleTick();
    notifyListeners();
  }

  Future<void> applyConfig(WorkConfig value) async {
    config = value;
    editing = false;
    notifyListeners();
    await _repository.save(value);
  }

  void beginEdit() {
    if (config == null) {
      return;
    }
    editing = true;
    notifyListeners();
  }

  void cancelEdit() {
    editing = false;
    notifyListeners();
  }

  Future<void> persist() async {
    final current = config;
    if (current == null) {
      return;
    }
    await _repository.save(current);
  }

  Future<void> minimizeToFloat() async {
    if (floating || _windowBusy) {
      return;
    }
    _windowBusy = true;
    try {
      await DesktopWindow.instance.showFloat();
      floating = true;
    } catch (error, stack) {
      floating = false;
      debugPrint('进入悬浮窗失败: $error\n$stack');
    } finally {
      _windowBusy = false;
      notifyListeners();
    }
  }

  /// 系统最小化会把窗口收到程序坞，这里改成桌面上的悬浮窗。
  Future<void> absorbMinimize() async {
    if (floating || _windowBusy) {
      return;
    }
    _windowBusy = true;
    try {
      await DesktopWindow.instance.restoreIfMinimized();
      await DesktopWindow.instance.showFloat();
      floating = true;
    } catch (error, stack) {
      floating = false;
      debugPrint('接管最小化失败: $error\n$stack');
    } finally {
      _windowBusy = false;
      notifyListeners();
    }
  }

  Future<void> restoreFromFloat() async {
    if (!floating || _windowBusy) {
      return;
    }
    _windowBusy = true;
    try {
      await DesktopWindow.instance.showMain();
      floating = false;
      maximized = await DesktopWindow.instance.isMaximized();
    } catch (error, stack) {
      debugPrint('恢复窗口失败: $error\n$stack');
    } finally {
      _windowBusy = false;
      notifyListeners();
    }
  }

  Future<void> toggleMaximize() async {
    if (floating || _windowBusy) {
      return;
    }
    await DesktopWindow.instance.toggleMaximize();
    maximized = await DesktopWindow.instance.isMaximized();
    notifyListeners();
  }

  void setMaximized(bool value) {
    if (maximized == value) {
      return;
    }
    maximized = value;
    notifyListeners();
  }

  Future<void> shutdown() async {
    if (_closing) {
      return;
    }
    _closing = true;
    _disposed = true;
    _align?.cancel();
    _timer?.cancel();
    try {
      await DesktopWindow.instance.beginShutdown();
    } catch (error, stack) {
      debugPrint('隐藏窗口失败: $error\n$stack');
    }
    try {
      await persist();
    } catch (error, stack) {
      debugPrint('退出前保存失败: $error\n$stack');
    }
    await DesktopWindow.instance.shutdown();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _align?.cancel();
    _timer?.cancel();
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    super.dispose();
  }

  void _scheduleTick() {
    _align?.cancel();
    _timer?.cancel();
    final delay = Duration(milliseconds: 1000 - _clock().millisecond);
    _align = Timer(delay, () {
      if (_disposed) {
        return;
      }
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    });
  }

  void _tick() {
    if (_disposed) {
      return;
    }
    now = _truncated(_clock());
    notifyListeners();
  }

  DateTime _truncated(DateTime time) {
    return DateTime(
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
      time.second,
    );
  }
}

class AppScope extends InheritedNotifier<AppModel> {
  const AppScope({super.key, required AppModel model, required super.child})
    : super(notifier: model);

  static AppModel watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope 不在当前组件树中');
    return scope!.notifier!;
  }

  static AppModel read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope 不在当前组件树中');
    return scope!.notifier!;
  }
}
