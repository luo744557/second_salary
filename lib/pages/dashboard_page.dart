import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../format/money_format.dart';
import '../models/work_config.dart';
import '../services/income_calculator.dart';
import '../state/app_model.dart';
import '../widgets/per_second_fx.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final config = model.config;
    final snapshot = model.snapshot;
    if (config == null || snapshot == null) {
      return const SizedBox.shrink();
    }
    final token = context.tTheme;
    final countdown = _CountdownCard(snapshot: snapshot);
    final rate = _RateCard(snapshot: snapshot);
    final stats = _StatsColumn(snapshot: snapshot);
    final rules = _RuleCard(config: config, snapshot: snapshot);

    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth >= 860;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            landscape ? 28 : 16,
            8,
            landscape ? 28 : 16,
            28,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(timeLabel: formatDateTime(snapshot.now)),
                  const SizedBox(height: 16),
                  if (landscape)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              const _CornerGif(),
                              const SizedBox(height: 16),
                              countdown,
                              const SizedBox(height: 16),
                              rate,
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              stats,
                              const SizedBox(height: 16),
                              rules,
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    countdown,
                    const SizedBox(height: 12),
                    rate,
                    const SizedBox(height: 12),
                    stats,
                    const SizedBox(height: 12),
                    rules,
                  ],
                  const SizedBox(height: 8),
                  TText(
                    '拖动窗口边缘可以改变大小。窗口变宽后左右分栏，变窄后改为上下排列。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: token.textColorPlaceholder,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.timeLabel});

  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.read(context);
    final token = context.tTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TText(
              '秒薪',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: token.textColorPrimary,
              ),
            ),
            const SizedBox(height: 4),
            TText(timeLabel, style: TextStyle(color: token.textColorSecondary)),
          ],
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TButton(
              size: TButtonSize.small,
              variant: TButtonVariant.outline,
              colorPreset: TButtonColorPreset.primary,
              icon: const Icon(TIcons.edit),
              onPressed: model.beginEdit,
              child: const Text('修改规则'),
            ),
            const SizedBox(width: 8),
            TButton(
              size: TButtonSize.small,
              colorPreset: TButtonColorPreset.primary,
              icon: const Icon(TIcons.pin),
              onPressed: model.minimizeToFloat,
              child: const Text('悬浮'),
            ),
          ],
        );
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), actions],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            actions,
          ],
        );
      },
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.snapshot});

  final IncomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final token = context.tTheme;
    final resting = snapshot.phase == ClockPhase.restDay;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(TIcons.time, color: token.brandColor, size: 20),
              TText('下班倒计时', style: TextStyle(color: token.textColorSecondary)),
              _PhaseChip(phase: snapshot.phase),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TText(
              resting ? '休息' : formatClock(snapshot.countdown),
              style: TextStyle(
                fontSize: 56,
                height: 1,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: token.textColorPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TText(
            resting
                ? '今天不计入工时，收入暂停累计。'
                : '下班 ${formatClockTime(snapshot.shiftEnd)} · 午休 ${formatClockTime(snapshot.lunchStart)}-${formatClockTime(snapshot.lunchEnd)}',
            style: TextStyle(color: token.textColorSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.snapshot});

  final IncomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final token = context.tTheme;
    return _Panel(
      color: token.brandColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TText('每秒工作收入', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          PerSecondFx(
            text: '${formatPerSecond(snapshot.perSecond)} 元',
            burstText: formatPerSecond(snapshot.perSecond),
            active: snapshot.accruing,
            tick: snapshot.now.millisecondsSinceEpoch ~/ 1000,
            color: Colors.white,
            accent: const Color(0xFFFFE08A),
          ),
          const SizedBox(height: 4),
          TText(
            snapshot.accruing ? '又赚了一秒' : '当前不在计薪时段，每秒加 0 元',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StatsColumn extends StatelessWidget {
  const _StatsColumn({required this.snapshot});

  final IncomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MoneyRow(
          title: '今日收入',
          subtitle: '勤勤恳恳小钱钱',
          value: formatYuan(snapshot.todayIncome),
        ),
        const SizedBox(height: 12),
        _MoneyRow(
          title: '本周累计',
          subtitle: '周一至今天',
          value: formatYuan(snapshot.weekIncome),
        ),
        const SizedBox(height: 12),
        _MoneyRow(
          title: '本月累计',
          subtitle: '${snapshot.now.month} 月 1 日至今',
          value: formatYuan(snapshot.monthIncome),
        ),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    final token = context.tTheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TText(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: token.textColorPrimary,
            ),
          ),
          const SizedBox(height: 4),
          TText(
            subtitle,
            style: TextStyle(fontSize: 12, color: token.textColorSecondary),
          ),
          const SizedBox(height: 8),
          TText(
            value,
            style: incomeNumberStyle(fontSize: 30, color: token.brandColor),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.config, required this.snapshot});

  final WorkConfig config;
  final IncomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final token = context.tTheme;
    final monthlySeconds = snapshot.workDays * config.dailyPaidSeconds;
    final lines = [
      '每日计薪 ${formatHours(config.dailyPaidHours)} = 8 - 午休 ${formatHourValue(config.lunchHours)} + 加班 ${config.overtimeHours}',
      '${config.mode.label}：${config.mode.detail}',
      '${snapshot.now.year}年${snapshot.now.month}月共 ${snapshot.workDays} 个计薪日',
      '每秒收入 = ${config.salary} 元 ÷ ($monthlySeconds 秒)',
    ];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TText(
            '本月计算规则',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: token.textColorPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: TText(
                line,
                style: TextStyle(height: 1.45, color: token.textColorSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

class _CornerGif extends StatelessWidget {
  const _CornerGif();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.88,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/mouse_desk.gif',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.phase});

  final ClockPhase phase;

  @override
  Widget build(BuildContext context) {
    final token = context.tTheme;
    final color = switch (phase) {
      ClockPhase.working => token.successColor,
      ClockPhase.lunch => token.warningColor,
      ClockPhase.beforeWork => token.brandColor,
      ClockPhase.offWork || ClockPhase.restDay => token.textColorSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: TText(
        phase.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? context.tTheme.bgColorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
