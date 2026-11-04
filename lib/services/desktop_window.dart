import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

/// 主窗口与桌面悬浮窗之间的切换。
class DesktopWindow {
  DesktopWindow._();

  static final DesktopWindow instance = DesktopWindow._();

  static const mainMinimum = Size(400, 560);
  static const floatSize = Size(248, 304);

  Rect? restoreBounds;
  bool restoreMaximized = false;
  Offset? floatPosition;

  Future<void> prepare() async {
    await windowManager.ensureInitialized();
    final options = WindowOptions(
      size: const Size(1080, 760),
      minimumSize: mainMinimum,
      center: true,
      backgroundColor: const Color(0xFFF3F3F3),
      title: '秒薪',
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: !Platform.isLinux,
    );
    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setPreventClose(true);
      await windowManager.setResizable(true);
      await windowManager.setMinimumSize(mainMinimum);
      await windowManager.setTitle('秒薪');
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Future<void> showFloat() async {
    if (await windowManager.isMaximized()) {
      restoreMaximized = true;
      await windowManager.unmaximize();
    } else {
      restoreMaximized = false;
    }
    restoreBounds = await windowManager.getBounds();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setResizable(false);
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setMinimumSize(const Size(230, 280));
    final anchor = floatPosition ?? await _defaultFloatPosition();
    await windowManager.setBounds(
      Rect.fromLTWH(anchor.dx, anchor.dy, floatSize.width, floatSize.height),
    );
  }

  Future<void> showMain() async {
    final current = await windowManager.getBounds();
    floatPosition = current.topLeft;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setResizable(true);
    await windowManager.setMinimumSize(mainMinimum);
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: !Platform.isLinux,
    );
    final bounds = restoreBounds;
    if (bounds != null) {
      await windowManager.setBounds(bounds);
    }
    if (restoreMaximized) {
      await windowManager.maximize();
    }
    await windowManager.focus();
  }

  Future<void> restoreIfMinimized() => windowManager.restore();

  Future<void> toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<bool> isMaximized() => windowManager.isMaximized();

  Future<void> shutdown() async {
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  Future<Offset> _defaultFloatPosition() async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      final origin = display.visiblePosition ?? Offset.zero;
      final size = display.visibleSize ?? display.size;
      return Offset(
        origin.dx + size.width - floatSize.width - 28,
        origin.dy + size.height - floatSize.height - 80,
      );
    } catch (_) {
      return const Offset(80, 120);
    }
  }
}
