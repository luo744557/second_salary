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
  WorkMode _mode = WorkMode.doubleRest;

  @override
  void initState() {
    super.initState();
    final config = AppScope.read(context).config;
    _salary = config?.salary.toString() ?? '';
    _lunch = config == null ? '' : formatHourValue(config.lunchHours);
    _overtime = config != null && config.overtimeHours > 0
        ? config.overtimeHours.toString()
        : '';
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
          '月工资会按当前月份的实际计薪秒数拆开。每天 09:00 上班，标准在岗 8 小时，午休从 12:00 开始并且不计薪，加班加在 8 小时之后。',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TText(
                    '休假方式（可选，只能选一个）',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: token.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TText(
                    '都不选时按双休计算，每周五天。',
                    style: TextStyle(
                      fontSize: 12,
                      color: token.textColorPlaceholder,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _modeOption(WorkMode.singleRest, '是否单休', '每周六天，周日休息'),
                  _modeOption(WorkMode.bigSmallWeek, '是否大小周', '一周七天、一周六天交替'),
                  _modeOption(WorkMode.biweeklyRest, '是否两周休一次', '按每周七天计入当月'),
                  _modeOption(WorkMode.fullMonth, '是否整月无休', '按本月每一天计入'),
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
        return TFormItem(
          label: '用户工资',
          help: '必填，税前月工资，单位元，正整数',
          child: TInput(
            controller: _salaryController,
            hintText: '例如 15000',
            inputType: TextInputType.number,
            inputAction: TextInputAction.next,
            status: errorText == null
                ? TInputStatus.normal
                : TInputStatus.error,
            clearButtonMode: TInputClearButtonMode.focused,
            inputFormatters: const [_PositiveIntFormatter()],
            onChanged: onChanged,
          ),
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
        return TFormItem(
          label: '日常午休时长',
          help: '必填，范围 0.50 到 2.50。可填正整数，小数最多两位',
          child: TInput(
            controller: _lunchController,
            hintText: '例如 1 或 1.5',
            inputType: const TextInputType.numberWithOptions(decimal: true),
            inputAction: TextInputAction.next,
            status: errorText == null
                ? TInputStatus.normal
                : TInputStatus.error,
            clearButtonMode: TInputClearButtonMode.focused,
            inputFormatters: const [_LunchFormatter()],
            onChanged: onChanged,
          ),
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
        return TFormItem(
          label: '日常加班时长',
          help: '选填。填写时为 1 到 6 的正整数，加在 8 小时班次之后',
          child: TInput(
            controller: _overtimeController,
            hintText: '不加班可留空',
            inputType: TextInputType.number,
            inputAction: TextInputAction.done,
            status: errorText == null
                ? TInputStatus.normal
                : TInputStatus.error,
            clearButtonMode: TInputClearButtonMode.focused,
            inputFormatters: const [_OvertimeFormatter()],
            onChanged: onChanged,
          ),
        );
      },
    );
  }

  Widget _modeOption(WorkMode mode, String title, String subtitle) {
    return TCheckbox(
      value: _mode == mode,
      title: title,
      subTitle: subtitle,
      cardMode: true,
      showDivider: false,
      onChanged: (checked) {
        setState(() {
          _mode = checked == true ? mode : WorkMode.doubleRest;
        });
      },
    );
  }

  WorkConfig? _draftConfig() {
    final salaryError = _validateSalary(_salary);
    final lunchError = _validateLunch(_lunch);
    final overtimeError = _validateOvertime(_overtime);
    if (_salary.isEmpty ||
        salaryError != null ||
        lunchError != null ||
        overtimeError != null) {
      return null;
    }
    if (_lunch.isEmpty) {
      return null;
    }
    return WorkConfig(
      salary: int.parse(_salary),
      lunchHours: double.parse(_lunch),
      overtimeHours: _overtime.isEmpty ? 0 : int.parse(_overtime),
      mode: _mode,
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
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (!RegExp(r'^[1-6]$').hasMatch(text)) {
      return '请输入 1 到 6 的正整数';
    }
    return null;
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
    if (newValue.text.isEmpty || RegExp(r'^[1-6]$').hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
