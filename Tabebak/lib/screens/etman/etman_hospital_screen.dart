import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'etman_colors.dart';

class EtmanHospitalScreen extends StatelessWidget {
  const EtmanHospitalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'المستشفيات',
          style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3D-like Hospital Icon Placeholder
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1FAF9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1E8C78).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: const Icon(Icons.location_city_rounded, size: 100, color: Color(0xFF1E8C78)),
              ),
              const SizedBox(height: 40),
              const Text(
                'قريباً جداً! 🏥',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 15),
              const Text(
                'خدمة حجز المستشفيات والعمليات الكبرى ستتوفر في التحديث القادم.. انتظرونا!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E8C78),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('فهمت، شكراً!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
