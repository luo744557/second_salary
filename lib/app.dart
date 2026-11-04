import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'state/app_model.dart';
import 'widgets/desktop_shell.dart';

class SecondSalaryApp extends StatefulWidget {
  const SecondSalaryApp({super.key});

  @override
  State<SecondSalaryApp> createState() => _SecondSalaryAppState();
}

class _SecondSalaryAppState extends State<SecondSalaryApp> {
  late final AppModel _model = AppModel();

  @override
  void initState() {
    super.initState();
    _model.bootstrap();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      model: _model,
      child: MaterialApp(
        title: '秒薪',
        debugShowCheckedModeBanner: false,
        theme: TThemeBuilder.light(TThemeData.defaultData()),
        themeMode: ThemeMode.light,
        home: const DesktopShell(),
      ),
    );
  }
}
