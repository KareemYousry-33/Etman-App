import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'etman_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../services/notification_service.dart';

class EtmanSplashScreen extends StatefulWidget {
  const EtmanSplashScreen({Key? key}) : super(key: key);

  @override
  State<EtmanSplashScreen> createState() => _EtmanSplashScreenState();
}

class _EtmanSplashScreenState extends State<EtmanSplashScreen> with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Elastic pop effect
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Heartbeat pulse effect
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // تشغيل الأنيميشن
    _introController.forward().then((_) {
      _pulseController.repeat(reverse: true);
    });

    // النقل للشاشة التالية بعد 4 ثواني مع التحقق من الدخول
    Future.delayed(const Duration(seconds: 4), () {
      final authController = Get.find<AuthController>();
      
      if (authController.firebaseUser.value != null) {
        // المستخدم مسجل دخول بالفعل
        // AuthController has the login logic to go to the right dashboard
        // We'll wait a brief moment to ensure currentUser is fetched then call the navigation
        if (authController.currentUser.value != null) {
          // If already loaded, go to the right place
          authController.onInit(); // This is a bit hacky, let's just trigger its internal navigate logic
          // Actually, let's just use the logic from AuthController
          _navigateBasedOnRole(authController.currentUser.value!);
        } else {
          // Wait for currentUser to populate then navigate
          ever(authController.currentUser, (user) {
            if (user != null) {
              _navigateBasedOnRole(user);
            }
          });
          // Fallback if currentUser takes too long but firebaseUser is there
          Future.delayed(const Duration(seconds: 2), () {
            if (Get.currentRoute == '/splash') {
              Get.offAllNamed('/login');
            }
          });
        }
      } else {
        Get.offNamed('/onboarding');
      }
    });
  }

  void _navigateBasedOnRole(dynamic user) {
    if (Get.currentRoute != '/splash') return;
    
    // Simple logic to mirror AuthController navigation
    String route = '/main';
    if (user.role.toString().contains('admin')) route = '/admin';
    else if (user.role.toString().contains('doctor')) route = '/doctor-dashboard';
    else if (user.role.toString().contains('pharmacy')) route = '/pharmacy-dashboard';
    
    Get.offAllNamed(route);
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Top-Center: Logo + Powered by Savix ──
          Positioned(
            top: MediaQuery.of(context).size.height * 0.20,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with pop + pulse animation
                AnimatedBuilder(
                  animation: Listenable.merge([_introController, _pulseController]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value * _pulseAnimation.value,
                        child: Image.asset(
                          'assets/logo.png',
                          width: 300,
                          height: 300,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.favorite,
                            size: 150,
                            color: EtmanColors.primaryTeal,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Pull it closer to the logo image because the image might have empty transparent space
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.electric_bolt_rounded,
                            size: 14, color: EtmanColors.primaryTeal.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          'Powered by Savix',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: EtmanColors.primaryTeal.withOpacity(0.85),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom: copyright only ──
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                '© All Rights Reserved to B2B Agency',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

