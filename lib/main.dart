import 'package:flutter/widgets.dart';

import 'app.dart';
import 'services/desktop_window.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DesktopWindow.instance.prepare();
  runApp(const SecondSalaryApp());
}
