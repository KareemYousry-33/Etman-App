import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:etman/screens/etman/etman_home_screen.dart';
import 'package:etman/screens/etman/etman_chatbot_screen.dart';
import 'package:etman/screens/etman/etman_profile_screen.dart';
import 'package:etman/screens/etman/etman_appointments_screen.dart';
import 'package:etman/controllers/etman_main_wrapper_controller.dart';
import 'package:etman/controllers/auth_controller.dart';

class EtmanMainWrapper extends StatelessWidget {
  const EtmanMainWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EtmanMainWrapperController nav = Get.put(EtmanMainWrapperController());

    final List<Widget> screens = [
      EtmanHomeScreen(),
      EtmanChatBotScreen(), // Smart Chat (AI Chatbot) - matches Image 3
      EtmanAppointmentsScreen(),
      EtmanProfileScreen(),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(() {
        // Safe guard: Show loader if user data is not yet available to prevent 'Red Screen'
        if (Get
            .find<AuthController>()
            .currentUser
            .value == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
                child: CircularProgressIndicator(color: Color(0xFF1E8C78))),
          );
        }

        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutQuart,
            switchOutCurve: Curves.easeInQuart,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(nav.currentIndex.value),
              child: screens[nav.currentIndex.value],
            ),
          ),
          bottomNavigationBar: _buildBottomNavBar(nav),
        );
      }),
    );
  }

  Widget _buildBottomNavBar(EtmanMainWrapperController nav) {
    return Container(
      // Full width and full bottom coverage
      decoration: BoxDecoration(
        color: const Color(0xFF135B51),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(
            color: Color(0xFF1E8C78), // Subtle highlight line on top
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double width = constraints.maxWidth;
              double itemWidth = width / 4;
              
              return Stack(
                children: [
                  // Sliding Pill Indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    right: (nav.currentIndex.value * itemWidth) + 12,
                    top: 12,
                    bottom: 12,
                    child: Container(
                      width: itemWidth - 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E8C78),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                    ),
                  ),
                  // Navigation Items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(nav, 0, Icons.home_rounded, Icons.home_outlined, 'الرئيسية'),
                      _navItem(nav, 1, Icons.smart_toy_rounded, Icons.smart_toy_outlined, 'طبيبك الذكي'),
                      _navItem(nav, 2, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'معاملاتي'),
                      _navItem(nav, 3, Icons.person_rounded, Icons.person_outline, 'حسابي'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _navItem(EtmanMainWrapperController nav, int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final bool isSelected = nav.currentIndex.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (nav.currentIndex.value != index) {
            HapticFeedback.lightImpact();
            nav.changeIndex(index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 400),
              scale: isSelected ? 1.0 : 0.85,
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                size: isSelected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: isSelected ? 11 : 9,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
