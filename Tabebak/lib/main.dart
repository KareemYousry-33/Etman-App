import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:etman/firebase_options.dart';
import 'package:etman/controllers/language_controller.dart';
import 'package:etman/controllers/auth_controller.dart';
import 'controllers/appointment_controller.dart';
import 'package:etman/controllers/admin_controller.dart';
import 'controllers/doctor_controller.dart';
import 'controllers/pharmacy_controller.dart';
import 'controllers/doctor_list_controller.dart';
import 'screens/etman/etman_splash_screen.dart';
import 'screens/etman/etman_onboarding_screen.dart';
import 'screens/etman/etman_login_screen.dart';
import 'screens/etman/etman_main_wrapper.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/pharmacy_dashboard_screen.dart';
import 'utils/app_translations.dart';
import 'services/notification_service.dart';
import 'services/gemini_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Get.put(LanguageController());
  Get.put(AuthController());
  Get.put(GeminiService());
  Get.put(AppointmentController());
  Get.put(AdminController());
  Get.put(DoctorController());
  Get.put(PharmacyController());
  Get.put(DoctorListController());

  // Initialize Notification Service asynchronously without blocking runApp
  Get.putAsync<NotificationService>(() async {
    try {
      return await NotificationService().init();
    } catch (e) {
      debugPrint('⚠️ NotificationService init failed (non-fatal): $e');
      return NotificationService(); // Return uninitialized instance
    }
  });

  runApp(const EtmanApp());
}



class EtmanApp extends StatelessWidget {
  const EtmanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final langController = Get.find<LanguageController>();

    return GetMaterialApp(
      title: 'Atma\'en',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E8C78),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E8C78)),
        fontFamily: 'Roboto',
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr, // Force LTR even for Arabic (UI choice)
          child: child!,
        );
      },
      translations: AppTranslations(),
      locale: langController.currentLocale.value,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const EtmanSplashScreen()),
        GetPage(name: '/onboarding', page: () => const EtmanOnboardingScreen()),
        GetPage(name: '/login', page: () => const EtmanLoginScreen()),
        GetPage(name: '/main', page: () => const EtmanMainWrapper()),
        GetPage(name: '/doctor-dashboard', page: () => const DoctorDashboardScreen()),
        GetPage(name: '/admin', page: () => const AdminScreen()),
        GetPage(name: '/pharmacy-dashboard', page: () => const PharmacyDashboardScreen()),
      ],
    );
  }
}
