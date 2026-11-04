import 'dart:io';

import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:window_manager/window_manager.dart';

import '../format/money_format.dart';
import '../services/income_calculator.dart';
import '../state/app_model.dart';
import 'per_second_fx.dart';

class FloatPanel extends StatelessWidget {
  const FloatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final snapshot = model.snapshot;
    final token = context.tTheme;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }
    final adding = snapshot.accruing ? snapshot.perSecond : 0.0;
    final showPerSecond = model.config?.showFloatPerSecond ?? true;

    return Material(
      color: token.bgColorContainer,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          showPerSecond ? 14 : 12,
          showPerSecond ? (Platform.isMacOS ? 36 : 12) : 10,
          showPerSecond ? 14 : 12,
          showPerSecond ? 12 : 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showPerSecond)
              DragToMoveArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TText(
                      '每秒加',
                      style: TextStyle(
                        fontSize: 12,
                        color: token.textColorSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    PerSecondFx(
                      text: formatPerSecond(adding),
                      burstText: formatPerSecond(snapshot.perSecond),
                      active: snapshot.accruing,
                      tick: snapshot.now.millisecondsSinceEpoch ~/ 1000,
                      color: snapshot.accruing
                          ? token.successColor
                          : token.textColorPlaceholder,
                      accent: const Color(0xFFFFC53D),
                      fontSize: 32,
                      compact: true,
                    ),
                    TText(
                      '元',
                      style: TextStyle(
                        fontSize: 12,
                        color: token.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            if (showPerSecond) const Spacer(),
            DragToMoveArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TText(
                    _countdownText(snapshot),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: token.textColorSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      TText(
                        '今日 ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: token.textColorPrimary,
                        ),
                      ),
                      Flexible(
                        child: TText(
                          formatYuan(snapshot.todayIncome),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: incomeNumberStyle(
                            fontSize: 18,
                            color: token.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  TText(
                    snapshot.accruing
                        ? '计薪中 · 费率 ${formatPerSecond(snapshot.perSecond)}'
                        : snapshot.phase.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: token.textColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: showPerSecond ? 10 : 8),
            if (showPerSecond)
              Row(
                children: [
                  Expanded(
                    child: TButton(
                      size: TButtonSize.small,
                      colorPreset: TButtonColorPreset.primary,
                      onPressed: model.restoreFromFloat,
                      child: const Text('展开'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TButton(
                      size: TButtonSize.small,
                      variant: TButtonVariant.outline,
                      colorPreset: TButtonColorPreset.danger,
                      onPressed: model.shutdown,
                      child: const Text('退出'),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TButton(
                    size: TButtonSize.extraSmall,
                    colorPreset: TButtonColorPreset.primary,
                    onPressed: model.restoreFromFloat,
                    child: const Text('展开'),
                  ),
                  const SizedBox(height: 6),
                  TButton(
                    size: TButtonSize.extraSmall,
                    variant: TButtonVariant.outline,
                    colorPreset: TButtonColorPreset.danger,
                    onPressed: model.shutdown,
                    child: const Text('退出'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

String _countdownText(IncomeSnapshot snapshot) {
  if (snapshot.phase == ClockPhase.restDay) {
    return '今日休息';
  }
  return '${snapshot.phase.label} ${formatClock(snapshot.countdown)}';
}
