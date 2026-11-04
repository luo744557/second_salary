import 'package:flutter/services.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../format/money_format.dart';
import '../models/work_config.dart';
import '../services/income_calculator.dart';
import '../state/app_model.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _formKey = GlobalKey<TFormState>();
  late final TextEditingController _salaryController;
  late final TextEditingController _lunchController;
  late final TextEditingController _overtimeController;

  String _salary = '';
  String _lunch = '';
  String _overtime = '';
  String _dayStart = '';
  String _dayEnd = '';
  WorkMode _mode = WorkMode.doubleRest;

  @override
  void initState() {
    super.initState();
    final config = AppScope.read(context).config;
    _salary = config?.salary.toString() ?? '';
    _lunch = config == null ? '' : formatHourValue(config.lunchHours);
    _overtime = config != null && config.overtimeHours > 0
        ? formatHourValue(config.overtimeHours)
        : '';
    _dayStart = _clockText(config?.dayStartHour);
    _dayEnd = _clockText(config?.dayEndHour);
    _mode = config?.mode ?? WorkMode.doubleRest;
    _salaryController = TextEditingController(text: _salary);
    _lunchController = TextEditingController(text: _lunch);
    _overtimeController = TextEditingController(text: _overtime);
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _lunchController.dispose();
    _overtimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final theme = Theme.of(context);
    final token = context.tTheme;

    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values,
          const TFormThemeData(
            layout: TFormLayout.vertical,
            showColon: false,
            itemSpacing: 8,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(wide ? 32 : 20, 8, wide ? 32 : 20, 28),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _intro(token)),
                          const SizedBox(width: 28),
                          Expanded(flex: 2, child: _formCard(model, token)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _intro(token),
                          const SizedBox(height: 16),
                          _formCard(model, token),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _intro(TThemeData token) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TText(
          '先记下这个月怎么上班',
          style: TextStyle(
            fontSize: 28,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: token.textColorPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TText(
          '月工资会按当前月份的实际计薪秒数拆开。默认早九晚五，09:00 上班、17:00 下班，午休从 12:00 开始并且不计薪，加班加在 17:00 之后。',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: token.textColorSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _preview(token),
      ],
    );
  }

  Widget _preview(TThemeData token) {
    final config = _draftConfig();
    final now = DateTime.now();
    final preview = config == null
        ? null
        : IncomeCalculator.snapshot(config, now);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: token.bgColorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: config == null
          ? TText(
              '填完工资和午休时长后，这里会预览本月计薪日和每秒收入。',
              style: TextStyle(color: token.textColorSecondary, height: 1.5),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TText(
                  '本月预览',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: token.textColorPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TText(
                  '${config.mode.label} · ${now.year}年${now.month}月 '
                  '${IncomeCalculator.workDaysInMonth(now.year, now.month, config.mode)} 个计薪日',
                  style: TextStyle(
                    color: token.textColorSecondary,
                    height: 1.5,
                  ),
                ),
                TText(
                  '今日 ${formatClockTime(preview!.shiftStart)}-${formatClockTime(preview.shiftEnd)}，计薪 ${formatHours(preview.todayScheduledPaidSeconds / 3600)}',
                  style: TextStyle(
                    color: token.textColorSecondary,
                    height: 1.5,
                  ),
                ),
                TText(
                  '每日计薪 ${formatHours(config.dailyPaidHours)}，每秒 ${formatPerSecond(IncomeCalculator.perSecondIncome(config, now))} 元',
                  style: TextStyle(
                    color: token.brandColor,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _formCard(AppModel model, TThemeData token) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
      decoration: BoxDecoration(
        color: token.bgColorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TForm(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _salaryField(),
            _lunchField(),
            _overtimeField(),
            _dayStartField(),
            _dayEndField(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TText(
                    '休假方式',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: token.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TText(
                    '选择一种。',
                    style: TextStyle(
                      fontSize: 12,
                      color: token.textColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final mode in WorkMode.values)
                    _RestModeCard(
                      mode: mode,
                      selected: _mode == mode,
                      onTap: () => setState(() => _mode = mode),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  if (model.config != null) ...[
                    Expanded(
                      child: TButton(
                        variant: TButtonVariant.outline,
                        colorPreset: TButtonColorPreset.primary,
                        size: TButtonSize.large,
                        onPressed: model.cancelEdit,
                        child: const Text('返回'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: TButton(
                      colorPreset: TButtonColorPreset.primary,
                      size: TButtonSize.large,
                      onPressed: () => _submit(model),
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _salaryField() {
    return TFormField<String>(
      name: 'salary',
      value: _salary,
      required: true,
      requiredMessage: '请输入用户工资',
      onChanged: (value) => setState(() => _salary = value),
      validator: _validateSalary,
      builder: (context, value, onChanged, errorText) {
        return _RuleField(
          label: '用户工资',
          help: '税前月工资，正整数',
          unit: '元',
          required: true,
          controller: _salaryController,
          hintText: '例如 15000',
          inputType: TextInputType.number,
          inputAction: TextInputAction.next,
          inputFormatters: const [_PositiveIntFormatter()],
          errorText: errorText,
          onChanged: onChanged,
        );
      },
    );
  }

  Widget _lunchField() {
    return TFormField<String>(
      name: 'lunch',
      value: _lunch,
      required: true,
      requiredMessage: '请输入日常午休时长',
      onChanged: (value) => setState(() => _lunch = value),
      validator: _validateLunch,
      builder: (context, value, onChanged, errorText) {
        return _RuleField(
          label: '日常午休时长',
          help: '0.50 到 2.50，可填整数，小数最多两位',
          unit: '小时',
          required: true,
          controller: _lunchController,
          hintText: '例如 1 或 1.5',
          inputType: const TextInputType.numberWithOptions(decimal: true),
          inputAction: TextInputAction.next,
          inputFormatters: const [_LunchFormatter()],
          errorText: errorText,
          onChanged: onChanged,
        );
      },
    );
  }

  Widget _overtimeField() {
    return TFormField<String>(
      name: 'overtime',
      value: _overtime,
      onChanged: (value) => setState(() => _overtime = value),
      validator: _validateOvertime,
      builder: (context, value, onChanged, errorText) {
        return _RuleField(
          label: '日常加班时长',
          help: '选填。可填正整数，小数最多两位，不超过 6。填 0 视为不填',
          blankIfZero: true,
          unit: '小时',
          controller: _overtimeController,
          hintText: '例如 1 或 1.5',
          inputType: const TextInputType.numberWithOptions(decimal: true),
          inputAction: TextInputAction.next,
          inputFormatters: const [_OvertimeFormatter()],
          errorText: errorText,
          onChanged: onChanged,
        );
      },
    );
  }

  Widget _dayStartField() {
    return TFormField<String>(
      name: 'dayStart',
      value: _dayStart,
      onChanged: (value) => setState(() => _dayStart = value),
      validator: (value) => _validateDayPoint(value, isEnd: false),
      builder: (context, value, onChanged, errorText) {
        return _TimePointField(
          label: '当天上班时间',
          help: '选填。点按选择时间。不选时按 09:00。',
          value: _dayStart,
          placeholder: '默认 09:00',
          errorText: errorText,
          onPick: () => _pickClock(isEnd: false, onChanged: onChanged),
          onClear: _dayStart.isEmpty
              ? null
              : () {
                  onChanged?.call('');
                  setState(() => _dayStart = '');
                },
        );
      },
    );
  }

  Widget _dayEndField() {
    return TFormField<String>(
      name: 'dayEnd',
      value: _dayEnd,
      onChanged: (value) => setState(() => _dayEnd = value),
      validator: (value) => _validateDayPoint(value, isEnd: true),
      builder: (context, value, onChanged, errorText) {
        return _TimePointField(
          label: '当天下班时间',
          help: '选填。点按选择时间。不选时按 17:00，加班加在 17:00 之后。',
          value: _dayEnd,
          placeholder: '默认 17:00',
          errorText: errorText,
          onPick: () => _pickClock(isEnd: true, onChanged: onChanged),
          onClear: _dayEnd.isEmpty
              ? null
              : () {
                  onChanged?.call('');
                  setState(() => _dayEnd = '');
                },
        );
      },
    );
  }

  void _pickClock({
    required bool isEnd,
    required ValueChanged<String>? onChanged,
  }) {
    final current = _clockHours(isEnd ? _dayEnd : _dayStart);
    final totalMinutes = current == null
        ? (isEnd ? 17 : 9) * 60
        : (current * 60).round();
    var selected = TDateTimePickerValue(
      hour: totalMinutes ~/ 60,
      minute: totalMinutes % 60,
    );
    TPickerPopup.show(
      context,
      destroyOnClose: true,
      child: _ClockWheel(
        initial: selected,
        onChanged: (value) => selected = value,
      ),
      headerBuilder: (context, close) {
        final token = context.tTheme;
        return TPopupHeader(
          title: Text(isEnd ? '当天下班时间' : '当天上班时间'),
          cancelButton: GestureDetector(
            onTap: close,
            child: TText(
              '取消',
              style: TextStyle(color: token.textColorSecondary),
            ),
          ),
          confirmButton: GestureDetector(
            onTap: () {
              final text = _clockText(
                (selected.hour ?? 0) + (selected.minute ?? 0) / 60,
              );
              onChanged?.call(text);
              setState(() {
                if (isEnd) {
                  _dayEnd = text;
                } else {
                  _dayStart = text;
                }
              });
              close();
            },
            child: TText(
              '确定',
              style: TextStyle(
                color: token.brandColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  WorkConfig? _draftConfig() {
    final salaryError = _validateSalary(_salary);
    final lunchError = _validateLunch(_lunch);
    final overtimeError = _validateOvertime(_overtime);
    final startError = _validateDayPoint(_dayStart, isEnd: false);
    final endError = _validateDayPoint(_dayEnd, isEnd: true);
    if (_salary.isEmpty ||
        salaryError != null ||
        lunchError != null ||
        overtimeError != null ||
        startError != null ||
        endError != null) {
      return null;
    }
    if (_lunch.isEmpty) {
      return null;
    }
    return WorkConfig(
      salary: int.parse(_salary),
      lunchHours: double.parse(_lunch),
      overtimeHours: _optionalHours(_overtime) ?? 0,
      mode: _mode,
      dayStartHour: _clockHours(_dayStart),
      dayEndHour: _clockHours(_dayEnd),
    );
  }

  Future<void> _submit(AppModel model) async {
    final state = _formKey.currentState;
    if (state == null || !state.submit()) {
      return;
    }
    final config = _draftConfig();
    if (config == null) {
      return;
    }
    await model.applyConfig(config);
  }

  String? _validateSalary(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (!RegExp(r'^[1-9]\d{0,7}$').hasMatch(text)) {
      return '请输入正整数';
    }
    return null;
  }

  String? _validateLunch(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
      return '请输入正整数，或最多两位小数';
    }
    final hours = double.tryParse(text);
    if (hours == null || hours < 0.5 || hours > 2.5) {
      return '请输入 0.50 到 2.50 之间的数字';
    }
    return null;
  }

  String? _validateOvertime(String? value) {
    final hours = _optionalHours(value);
    if (_isBlankNumber(value)) {
      return null;
    }
    if (hours == null) {
      return '请输入正整数，或最多两位小数';
    }
    if (hours > WorkConfig.maxOvertimeHours) {
      return '请输入大于 0 且不超过 6 的数字';
    }
    return null;
  }

  String? _validateDayPoint(String? value, {required bool isEnd}) {
    final text = value?.trim() ?? '';
    final hours = text.isEmpty ? null : _clockHours(text);
    if (text.isNotEmpty && hours == null) {
      return '请选择时间';
    }
    final start = isEnd ? _clockHours(_dayStart) : hours;
    final end = isEnd ? hours : _clockHours(_dayEnd);
    if (start != null && end != null && end <= start) {
      return isEnd ? '下班时间要晚于上班时间' : null;
    }
    final defaultEnd =
        WorkConfig.shiftEndHour + (_optionalHours(_overtime) ?? 0.0);
    if (!isEnd && end == null && start != null && start >= defaultEnd) {
      return '上班时间要早于默认下班 ${formatHourValue(defaultEnd)} 点';
    }
    if (isEnd &&
        start == null &&
        end != null &&
        end <= WorkConfig.shiftStartHour) {
      return '下班时间要晚于 09:00';
    }
    return null;
  }

  String _clockText(double? hours) {
    if (hours == null) {
      return '';
    }
    final total = (hours * 60).round().clamp(0, 24 * 60);
    final hour = total ~/ 60;
    final minute = total % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}

double? _clockHours(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text);
  if (match == null) {
    return null;
  }
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour == 24 && minute == 0) {
    return 24;
  }
  if (hour > 23 || minute > 59) {
    return null;
  }
  return hour + minute / 60;
}

class _RuleField extends StatefulWidget {
  const _RuleField({
    required this.label,
    required this.help,
    required this.unit,
    required this.controller,
    required this.hintText,
    required this.inputType,
    required this.inputAction,
    required this.inputFormatters,
    required this.onChanged,
    this.errorText,
    this.required = false,
    this.blankIfZero = false,
  });

  final String label;
  final String help;
  final String unit;
  final TextEditingController controller;
  final String hintText;
  final TextInputType inputType;
  final TextInputAction inputAction;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool required;
  final bool blankIfZero;

  @override
  State<_RuleField> createState() => _RuleFieldState();
}

class _RuleFieldState extends State<_RuleField> {
  final _focusNode = FocusNode();
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_focusNode.hasFocus &&
        widget.blankIfZero &&
        _isBlankNumber(widget.controller.text)) {
      widget.controller.clear();
      widget.onChanged?.call('');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final token = context.tTheme;
    final theme = Theme.of(context);
    final invalid = widget.errorText != null;
    final focused = _focusNode.hasFocus;
    final emphasized = invalid || focused;
    final borderColor = invalid
        ? token.errorColor
        : focused
        ? token.brandColor
        : _hovered
        ? const Color(0xFF86868B)
        : const Color(0xFFD2D2D7);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TText(
                widget.label,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: token.textColorPrimary,
                ),
              ),
              const Spacer(),
              TText(
                widget.required ? '必填' : '选填',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.required
                      ? token.brandColor
                      : token.textColorPlaceholder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TText(
            widget.help,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: token.textColorSecondary,
            ),
          ),
          const SizedBox(height: 8),
          MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: EdgeInsets.all(emphasized ? 0 : 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: emphasized ? 2 : 1,
                ),
              ),
              child: Theme(
                data: theme.copyWith(
                  extensions: [
                    for (final extension in theme.extensions.values)
                      if (extension is! TInputThemeData) extension,
                    const TInputThemeData(
                      backgroundColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      borderWidth: 0,
                    ),
                  ],
                ),
                child: TInput(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  hintText: widget.hintText,
                  inputType: widget.inputType,
                  inputAction: widget.inputAction,
                  borderless: true,
                  status: invalid ? TInputStatus.error : TInputStatus.normal,
                  clearButtonMode: TInputClearButtonMode.focused,
                  inputFormatters: widget.inputFormatters,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  suffix: TText(
                    widget.unit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: token.textColorSecondary,
                    ),
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
            ),
          ),
          if (invalid) ...[
            const SizedBox(height: 6),
            TText(
              widget.errorText!,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: token.errorColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RestModeCard extends StatefulWidget {
  const _RestModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final WorkMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RestModeCard> createState() => _RestModeCardState();
}

class _RestModeCardState extends State<_RestModeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final token = context.tTheme;
    final selected = widget.selected;
    final borderColor = selected
        ? token.brandColor
        : _hovered
        ? const Color(0xFF86868B)
        : const Color(0xFFD2D2D7);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 15 : 16,
              vertical: selected ? 11 : 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: selected ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TText(
                  widget.mode.label,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: token.textColorPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                TText(
                  widget.mode.detail,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: token.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PositiveIntFormatter extends TextInputFormatter {
  const _PositiveIntFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty ||
        RegExp(r'^[1-9]\d{0,7}$').hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

bool _isBlankNumber(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) {
    return true;
  }
  final hours = double.tryParse(text);
  return hours == 0 && RegExp(r'^\d+(\.\d*)?$').hasMatch(text);
}

/// 选填数字。空和 0 都视为未填写。格式不对时返回 null，且 [_isBlankNumber] 为 false。
double? _optionalHours(String? raw) {
  final text = raw?.trim() ?? '';
  if (_isBlankNumber(text)) {
    return null;
  }
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
    return null;
  }
  return double.parse(text);
}

class _LunchFormatter extends TextInputFormatter {
  const _LunchFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty ||
        RegExp(r'^\d?(\.\d{0,2})?$').hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

class _OvertimeFormatter extends TextInputFormatter {
  const _OvertimeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty ||
        RegExp(r'^\d?(\.\d{0,2})?$').hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

class _TimePointField extends StatefulWidget {
  const _TimePointField({
    required this.label,
    required this.help,
    required this.value,
    required this.placeholder,
    required this.onPick,
    this.onClear,
    this.errorText,
  });

  final String label;
  final String help;
  final String value;
  final String placeholder;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final String? errorText;

  @override
  State<_TimePointField> createState() => _TimePointFieldState();
}

class _TimePointFieldState extends State<_TimePointField> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final token = context.tTheme;
    final invalid = widget.errorText != null;
    final filled = widget.value.isNotEmpty;
    final borderColor = invalid
        ? token.errorColor
        : _hovered
        ? const Color(0xFF86868B)
        : const Color(0xFFD2D2D7);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TText(
                widget.label,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: token.textColorPrimary,
                ),
              ),
              const Spacer(),
              TText(
                '选填',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: token.textColorPlaceholder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TText(
            widget.help,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: token.textColorSecondary,
            ),
          ),
          const SizedBox(height: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: invalid ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onPick,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: TText(
                          filled ? widget.value : widget.placeholder,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: filled
                                ? token.textColorPrimary
                                : token.textColorPlaceholder,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.onClear != null)
                    GestureDetector(
                      onTap: widget.onClear,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 14, 16, 14),
                        child: TText(
                          '清除',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: token.brandColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (invalid) ...[
            const SizedBox(height: 6),
            TText(
              widget.errorText!,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: token.errorColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClockWheel extends StatefulWidget {
  const _ClockWheel({required this.initial, required this.onChanged});

  final TDateTimePickerValue initial;
  final ValueChanged<TDateTimePickerValue> onChanged;

  @override
  State<_ClockWheel> createState() => _ClockWheelState();
}

class _ClockWheelState extends State<_ClockWheel> {
  late TDateTimePickerValue _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return TDateTimePicker(
      value: _value,
      mode: DateTimePickerMode(timeMode: TimeMode.minute),
      onChanged: (value) {
        setState(() => _value = value);
        widget.onChanged(value);
      },
    );
  }
}
