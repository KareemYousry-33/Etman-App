import 'package:get/get.dart';
import 'package:etman/screens/etman/etman_splash_screen.dart';
import 'package:etman/screens/etman/etman_onboarding_screen.dart';
import 'package:etman/screens/etman/etman_login_screen.dart';
import 'package:etman/screens/etman/etman_home_screen.dart';
import 'package:etman/screens/etman/etman_doctor_screen.dart';
import 'package:etman/screens/etman/etman_doctor_booking_screen.dart';
import 'package:etman/screens/etman/etman_pharmacy_screen.dart';
import 'package:etman/screens/etman/etman_chatbot_screen.dart';
import 'package:etman/screens/etman/etman_profile_screen.dart';
import 'package:etman/screens/etman/etman_appointments_screen.dart';
import 'package:etman/screens/etman/etman_main_wrapper.dart';
import 'package:etman/screens/main_container_screen.dart';
import 'package:etman/screens/doctor_list_screen.dart';
import 'package:etman/screens/admin_screen.dart';
import 'package:etman/screens/doctor_dashboard_screen.dart';
import 'package:etman/screens/patient_profile_screen.dart';
import 'package:etman/screens/book_appointment_screen.dart';

class AppRoutes {
  static final routes = [
    GetPage(name: '/splash', page: () => const EtmanSplashScreen()),
    GetPage(name: '/onboarding', page: () => const EtmanOnboardingScreen()),
    GetPage(
      name: '/login',
      page: () => const EtmanLoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: '/home',
      page: () => const EtmanMainWrapper(),
    ),
    GetPage(
      name: '/doctor-search',
      page: () => const EtmanDoctorScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/doctor-booking',
      page: () => const EtmanDoctorBookingScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/pharmacy',
      page: () => const EtmanPharmacyScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/chatbot',
      page: () => const EtmanChatBotScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/profile',
      page: () => const EtmanProfileScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/appointments',
      page: () => const EtmanAppointmentsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/main',
      page: () => const MainContainerScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/doctors',
      page: () => const DoctorListScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/admin',
      page: () => const AdminScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/doctor-dashboard',
      page: () => const DoctorDashboardScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/patient-profile',
      page: () => const PatientProfileScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/book-appointment',
      page: () => const EtmanDoctorBookingScreen(), // Using the restored Etman version
      transition: Transition.rightToLeft,
    ),
  ];
}
