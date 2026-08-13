import 'package:flutter/material.dart';

import 'router.dart';
import 'services/vent_sfx.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VentSfx.instance.init();
  runApp(const GetMeBackApp());
}

class GetMeBackApp extends StatelessWidget {
  const GetMeBackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GetMeBack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
