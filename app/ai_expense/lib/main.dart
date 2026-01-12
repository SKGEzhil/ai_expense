import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/bindings/app_binding.dart';
import 'app/services/api_service.dart';
import 'app/services/settings_service.dart';
import 'app/utils/theme.dart';
import 'app/views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings first
  await SettingsService.getInstance();

  // Initialize API service with settings
  await ApiService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI Expense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialBinding: AppBinding(),
      home: HomeView(),
    );
  }
}
