import 'package:flutter/material.dart';

import 'router.dart';
import 'services/storage_service.dart';
import 'services/vent_sfx.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.loadSettings();
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
