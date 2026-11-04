import 'dart:io';

import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:window_manager/window_manager.dart';

import '../pages/dashboard_page.dart';
import '../pages/setup_page.dart';
import '../state/app_model.dart';
import 'float_panel.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    if (!mounted) {
      return;
    }
    AppScope.read(context).shutdown();
  }

  @override
  void onWindowMinimize() {
    if (!mounted) {
      return;
    }
    AppScope.read(context).absorbMinimize();
  }

  @override
  void onWindowMaximize() {
    if (!mounted) {
      return;
    }
    AppScope.read(context).setMaximized(true);
  }

  @override
  void onWindowUnmaximize() {
    if (!mounted) {
      return;
    }
    AppScope.read(context).setMaximized(false);
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final token = context.tTheme;
    if (model.floating) {
      return const FloatPanel();
    }

    return Material(
      color: token.bgColorPage,
      child: Column(
        children: [
          if (Platform.isMacOS) const SizedBox(height: 36),
          if (Platform.isLinux) const _LinuxCaption(),
          Expanded(child: _body(model)),
        ],
      ),
    );
  }

  Widget _body(AppModel model) {
    if (!model.ready) {
      return const Center(child: TText('正在读取本地记录'));
    }
    if (model.config == null || model.editing) {
      return const SetupPage();
    }
    return const DashboardPage();
  }
}

class _LinuxCaption extends StatelessWidget {
  const _LinuxCaption();

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final token = context.tTheme;
    return Container(
      height: 48,
      color: token.bgColorContainer,
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TText(
                    '秒薪',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: token.textColorPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _CaptionButton(
            icon: TIcons.minus,
            tooltip: '最小化到悬浮窗',
            onPressed: model.minimizeToFloat,
          ),
          _CaptionButton(
            icon: model.maximized ? TIcons.fullscreen_exit : TIcons.rectangle,
            tooltip: model.maximized ? '还原' : '最大化',
            onPressed: model.toggleMaximize,
          ),
          _CaptionButton(
            icon: TIcons.close,
            tooltip: '退出',
            danger: true,
            onPressed: model.shutdown,
          ),
        ],
      ),
    );
  }
}

class _CaptionButton extends StatelessWidget {
  const _CaptionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final token = context.tTheme;
    return SizedBox(
      width: 46,
      height: 48,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          hoverColor: danger
              ? token.errorColor.withValues(alpha: 0.12)
              : token.bgColorSecondaryContainer,
          child: Icon(
            icon,
            size: 16,
            color: danger ? token.errorColor : token.textColorPrimary,
          ),
        ),
      ),
    );
  }
}
