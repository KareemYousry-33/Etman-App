import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'etman/etman_home_screen.dart';
import 'etman/etman_doctor_screen.dart';
import 'etman/etman_chatbot_screen.dart';
import 'etman/etman_profile_screen.dart';
import '../widgets/custom_etman_nav_bar.dart';

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({Key? key}) : super(key: key);

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const EtmanHomeScreen(),
    const EtmanChatBotScreen(), // "طبيبك الذكي"
    const EtmanDoctorScreen(),  // "معاملاتي" (Using doctor list as placeholder for appointments)
    const EtmanProfileScreen(), // "حسابي"
  ];

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.currentUser.value;

      if (authController.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (user == null) {
        Future.delayed(Duration.zero, () => Get.offAllNamed('/login'));
        return Container();
      }

      return Directionality(
        textDirection: TextDirection.rtl, // Match screenshot RTL
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          extendBody: true,
          bottomNavigationBar: CustomEtmanNavBar(
            currentIndex: _currentIndex,
            onItemSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      );
    });
  }
}
