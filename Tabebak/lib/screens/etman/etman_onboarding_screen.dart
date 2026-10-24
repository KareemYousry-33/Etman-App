import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'etman_colors.dart';

class EtmanOnboardingScreen extends StatefulWidget {
  const EtmanOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<EtmanOnboardingScreen> createState() => _EtmanOnboardingScreenState();
}

class _EtmanOnboardingScreenState extends State<EtmanOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "رعاية صحية متكاملة", 
      "subtitle": "عناية طبية شاملة",
      "description": "اعثر على أفضل طبيب واحجز موعدك بكل سهولة.",
      "image": "assets/doctor_7.png",
    },
    {
      "title": "ابحث عن طبيبك بسهولة", 
      "subtitle": "سهولة الوصول للأطباء",
      "description": "حلول طبية متكاملة بين يديك.",
      "image": "assets/doctor_6.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD6E8E6), 
              Colors.white,
              Colors.white,
            ],
            stops: [0.0, 0.4, 1.0], 
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return OnboardingContent(
                    title: onboardingData[index]["title"]!,
                    subtitle: onboardingData[index]["subtitle"]!,
                    description: onboardingData[index]["description"]!,
                    imagePath: onboardingData[index]["image"]!,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: CustomButton(
                text: _currentPage == 0 ? "التالي" : "يلا بينا",
                onPressed: () {
                  if (_currentPage == onboardingData.length - 1) {
                    Get.offNamed('/login');
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                    );
                  }
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length, 
                (index) => buildDot(index: index),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    )
      );
  }

  Widget buildDot({required int index}) {
    int activeIndex = _currentPage;
    return Container(
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: activeIndex == index 
          ? EtmanColors.primary 
          : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;

  const OnboardingContent({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Section
          Container(
            height: MediaQuery.of(context).size.height * 0.45, 
            width: double.infinity,
            alignment: Alignment.center, // Centering forced
            child: SizedBox(
              width: double.infinity,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain, // Maintain aspect ratio
                alignment: Alignment.center, // Centering forced inside Image
                errorBuilder: (ctx, err, stack) => const Icon(
                  Icons.local_hospital, 
                  size: 150, 
                  color: EtmanColors.primary
                ),
              ),
            ),
          ),
          const SizedBox(height: 48), 
          
          // Text Section
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black, 
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: EtmanColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600, 
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: EtmanColors.primary,
          gradient: const LinearGradient(
            colors: [Color(0xFF239983), Color(0xFF4C6B61)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
