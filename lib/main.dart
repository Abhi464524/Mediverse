import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'common/config/api_config.dart';
import 'common/services/storage_service.dart';
import 'common/view/user_selection_view.dart';
import 'feature/doctorPages/view/doctor_homepage_view.dart';
import 'feature/patientsPages/view/patient_home_view.dart';
import 'common/translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Mediverse compiled API base: ${ApiConfig.baseUrl}');
  await Firebase.initializeApp();
  final storage = await StorageService.getInstance();

  Widget initialRoute;

  if (storage.isLoggedIn()) {
    final profile = await storage.getCurrentUserProfile();
    final role = profile?['role'] ?? '';
    final name = profile?['username'] ?? '';
    final speciality = profile?['speciality'] ?? '';

    if (role == "doctor") {
      initialRoute = DoctorHomePage(name: name, speciality: speciality);
    } else if (role == "patient") {
      initialRoute = PatientHomePage(name: name);
    } else {
      initialRoute = const userSelectionPage();
    }
  } else {
    initialRoute = const userSelectionPage();
  }

  // Load preferences
  final languageCode = storage.getLanguage();
  final isDarkMode = storage.getDarkMode();

  runApp(MyApp(
    initialRoute: initialRoute,
    languageCode: languageCode,
    isDarkMode: isDarkMode,
  ));
}

class MyApp extends StatelessWidget {
  final Widget initialRoute;
  final String languageCode;
  final bool isDarkMode;

  const MyApp({
    super.key,
    required this.initialRoute,
    required this.languageCode,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      title: "Mediverse",
      translations: AppTranslations(),
      locale: Locale(languageCode.split('_')[0],
          languageCode.split('_').length > 1 ? languageCode.split('_')[1] : ''),
      fallbackLocale: const Locale('en', 'US'),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6A9C89), brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF8FBF9),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6A9C89), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: initialRoute,
    );
  }
}
