import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Package-level imports for the 'etman' project on D:
import 'package:etman/screens/etman/etman_colors.dart';
import 'package:etman/screens/etman/etman_doctor_screen.dart';
import 'package:etman/screens/etman/etman_pharmacy_screen.dart';
import 'package:etman/screens/etman/etman_lab_screen.dart';
import 'package:etman/screens/etman/etman_chat_screen.dart';
import 'package:etman/screens/etman/p2p_chat_screen.dart';
import 'package:etman/screens/etman/prescription_workflow_screen.dart';
import 'package:etman/screens/etman/etman_doctor_booking_screen.dart';
import 'package:etman/controllers/language_controller.dart';
import 'package:etman/controllers/auth_controller.dart';
import 'package:etman/controllers/appointment_controller.dart';
import 'package:etman/controllers/p2p_chat_controller.dart';
import 'package:etman/controllers/banner_controller.dart';
import 'package:etman/controllers/notification_controller.dart';
import 'package:etman/services/gemini_service.dart';
import 'etman_utils.dart';

class EtmanHomeScreen extends StatefulWidget {
  const EtmanHomeScreen({Key? key}) : super(key: key);

  @override
  State<EtmanHomeScreen> createState() => _EtmanHomeScreenState();
}

class _EtmanHomeScreenState extends State<EtmanHomeScreen> {
  final AuthController authController = Get.find<AuthController>();
  final AppointmentController appointmentController = Get.find<AppointmentController>();
  final LanguageController langController = Get.find<LanguageController>();
  final GeminiService geminiService = Get.put(GeminiService());
  
  List<Map<String, dynamic>> _topDoctors = [];
  late final BannerController _bannerCtrl;

  @override
  void initState() {
    super.initState();
    _bannerCtrl = Get.isRegistered<BannerController>()
        ? Get.find<BannerController>()
        : Get.put(BannerController());
    // Initialize notification controller so user receives admin notifications
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController());
    }
    _seedMissingDoctors();
    _fetchLiveDoctors();
    // Show any unread admin notifications
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAdminNotifications());
  }

  void _checkAdminNotifications() {
    final notifCtrl = Get.find<NotificationController>();
    if (notifCtrl.notifications.isNotEmpty) {
      final latest = notifCtrl.notifications.first;
      final title = latest['title'] ?? '';
      final body = latest['body'] ?? '';
      if (title.isNotEmpty) {
        Get.snackbar(
          '🔔 $title',
          body,
          backgroundColor: const Color(0xFF135B51),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
          icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
        );
      }
    }
  }

  Future<void> _seedMissingDoctors() async {
    final firestore = FirebaseFirestore.instance;
    final docs = await firestore.collection('users').where('role', isEqualTo: 'doctor').get();
    
    final missingDoctors = [
      {'email': 'sara@etman.com', 'name': 'د. سارة محمد', 'specialty': 'رمد', 'price': '200', 'rating': 5.0, 'img': 'assets/doctor_f1.png'},
      {'email': 'amr@etman.com', 'name': 'د. عمرو محمود', 'specialty': 'مخ وأعصاب', 'price': '300', 'rating': 4.9, 'img': 'assets/doctor_m1.png'},
      {'email': 'ahmed_ali@etman.com', 'name': 'د. أحمد علي', 'specialty': 'قلب', 'price': '400', 'rating': 4.8, 'img': 'assets/doctor_m2.png'},
      {'email': 'fatma_nour@etman.com', 'name': 'د. فاطمة نور', 'specialty': 'أطفال', 'price': '250', 'rating': 5.0, 'img': 'assets/doctor_f2.png'},
      {'email': 'karim_yousry@etman.com', 'name': 'د. كريم يسري', 'specialty': 'أطفال', 'price': '150', 'rating': 4.7, 'img': 'assets/doctor.png'},
      {'email': 'hoda@etman.com', 'name': 'د. هدى صالح', 'specialty': 'جراحة عظام ومفاصل', 'price': '350', 'rating': 4.8, 'img': 'assets/doctor2.png'},
      {'email': 'khaled@etman.com', 'name': 'د. خالد محمود', 'specialty': 'مخ وأعصاب', 'price': '400', 'rating': 4.9, 'img': 'assets/doctor3.png'},
      {'email': 'nour@etman.com', 'name': 'د. نور حسن', 'specialty': 'أمراض جلدية', 'price': '300', 'rating': 4.8, 'img': 'assets/doctor_f1.png'},
      {'email': 'mostafa@etman.com', 'name': 'د. مصطفى كمال', 'specialty': 'أمراض الصدر والحساسية', 'price': '220', 'rating': 4.7, 'img': 'assets/doctor4.png'},
    ];

    for (var doctor in missingDoctors) {
      final docId = doctor['email'] as String;
      final existingDoc = docs.docs.firstWhereOrNull((d) => d.id == docId);
      final currentRating = EtmanUtils.toDouble(existingDoc?.data()['rating'], defaultValue: 0.0);

      if (existingDoc == null || currentRating == 0.0) {
        final double targetRating = doctor['rating'] as double;
        final int targetCount = 150 + (targetRating * 10).toInt();
        final double targetSum = targetRating * targetCount;

        await firestore.collection('users').doc(docId).set({
          'email': doctor['email'],
          'name': doctor['name'],
          'role': 'doctor',
          'specialty': doctor['specialty'],
          'price': doctor['price'],
          'rating': targetRating,
          'ratingCount': targetCount,
          'ratingSum': targetSum,
          'imageUrl': doctor['img'],
          'location': 'حي الزهور',
          'createdAt': FieldValue.serverTimestamp(),
          'availability': [],
        }, SetOptions(merge: true));
      }
    }
  }

  void _fetchLiveDoctors() {
    FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .orderBy('rating', descending: true)
        .limit(6)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _topDoctors = snapshot.docs.map((doc) {
          final data = doc.data();
          String img = data['imageUrl'] ?? 'assets/doctor.png';
          final docName = data['name'].toString().toLowerCase();
          
          if (data['imageUrl'] == null) {
            if (docName.contains('سارة') || docName.contains('آية')) {
              img = 'assets/doctor_f1.png';
            } else if (docName.contains('فاطمة') || docName.contains('هدى')) {
              img = 'assets/doctor_f2.png';
            } else if (docName.contains('نور')) {
              img = 'assets/doctor2.png';
            } else if (docName.contains('أحمد')) {
              img = 'assets/doctor_m1.png';
            } else if (docName.contains('عمرو') || docName.contains('خالد')) {
              img = 'assets/doctor_m2.png';
            } else if (docName.contains('كريم')) {
              img = 'assets/doctor.png';
            } else if (docName.contains('مصطفى')) {
              img = 'assets/doctor4.png';
            } else {
              img = 'assets/doctor_m1.png';
            }
          }

          final double rawRating = EtmanUtils.toDouble(data['rating'], defaultValue: 5.0);
          return {
            'id': data['email'] ?? doc.id,
            'name': data['name'] ?? 'دكتور',
            'specialty': data['specialty'] ?? 'عام',
            'rating': rawRating.toStringAsFixed(1),
            'ratingCount': data['ratingCount'] ?? 150,
            'image': img,
            'price': data['price']?.toString() ?? '200',
            'location': data['location'] ?? 'حي الزهور',
            'distance': '${(1.0 + (rawRating) % 3).toStringAsFixed(1)} كم',
          };
        }).toList();
      });
    });
  }

  void _navigateTo(Widget screen) {
    Get.to(() => screen);
  }

  Future<void> _handleProductPhoto() async {
    final p2pChatController = Get.put(P2PChatController());
    final image = await p2pChatController.pickImage(ImageSource.camera);
    
    if (image != null) {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      try {
        const adminId = 'admin';
        final roomId = await p2pChatController.getOrCreateChatRoom(receiverId: adminId, type: 'admin');
        
        await p2pChatController.sendMessage(
          roomId: roomId, 
          receiverId: adminId, 
          text: 'استفسار عن توافر منتج',
          imageFile: image,
        );
        
        Get.back();
        Get.to(() => P2PChatScreen(roomId: roomId, receiverName: 'الإدارة', receiverId: adminId));
      } catch (e) {
        Get.back();
        Get.snackbar('Error', 'Failed to connect to admin');
      }
    }
  }

  Future<void> _handleConsultantCall() async {
    final Uri telUrl = Uri.parse('tel:01013558197');
    if (await canLaunchUrl(telUrl)) {
      await launchUrl(telUrl);
    } else {
      Get.snackbar('Error', 'Could not launch dialer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _buildHeaderChildren(),
                ),
                const SizedBox(height: 28),
                // ── Category Cards 3x2 Grid ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCartoonCategory('assets/doctor_category.png', 'دكتور',
                        onTap: () => _navigateTo(const EtmanDoctorScreen())),
                    _buildCartoonCategory('assets/pharmacy_category.png', 'صيدلية',
                        onTap: () => _navigateTo(const EtmanPharmacyScreen())),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCartoonCategory('assets/hospital_category.png', 'معامل التحاليل',
                        onTap: () => _navigateTo(const EtmanLabScreen())),
                    _buildCartoonCategory('assets/doctor_category.png', 'تمريض منزلي',
                        icon: Icons.medical_services_outlined,
                        onTap: () => _navigateTo(const EtmanDoctorScreen(role: 'nurse', title: 'تمريض منزلي'))),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCartoonCategory('assets/hospital_category.png', 'مراكز الأشعة',
                        icon: Icons.image_search_rounded,
                        onTap: () => _navigateTo(const EtmanLabScreen(role: 'xray', title: 'مراكز الأشعة والتصوير'))),
                  ],
                ),
                const SizedBox(height: 35),
                _buildDynamicBanner(),
                const SizedBox(height: 35),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('أفضل الأطباء', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
                    GestureDetector(
                      onTap: () => _navigateTo(const EtmanDoctorScreen()),
                      child: const Text('مشاهدة الكل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E8C78))),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 200, 
                  child: _topDoctors.isEmpty 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E8C78)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _topDoctors.length,
                        itemBuilder: (context, index) {
                          final doc = _topDoctors[index];
                          return _buildTopDoctorCard(doc);
                        },
                      ),
                ),
                const SizedBox(height: 35),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('اطلب ادوية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.grey[600])),
                ),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25), 
                    border: Border.all(color: Colors.grey[400]!, width: 1.2),
                  ),
                  child: const TextField(
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'ما الذي تبحث عنه؟',
                      hintStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45),
                      suffixIcon: Icon(Icons.search, color: Colors.black54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMedicineAction('روشتة/\nموافقة طبية', Icons.receipt_long_outlined, 
                        onTap: () => Get.to(() => const PrescriptionWorkflowScreen())),
                    _buildMedicineAction('صورة المنتج', Icons.camera_alt_outlined, 
                        onTap: _handleProductPhoto),
                    _buildMedicineAction('استشير صيدلي', Icons.phone_in_talk_outlined, 
                        onTap: _handleConsultantCall),
                  ],
                ),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
    ),
      );
  }
  List<Widget> _buildHeaderChildren() {
    return [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final userName = authController.currentUser.value?.name ?? 'Mohamed5';
              return Text(
                'أهلاً، $userName',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E8C78),
                ),
              );
            }),
            const SizedBox(height: 6),
            const Text(
              'ابحث عن حلولك الصحية المطلوبة',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.2))),
        child: Obx(() {
          final photoUrl = authController.currentUser.value?.photoUrl;
          return CircleAvatar(
            radius: 26, 
            backgroundColor: Colors.grey[100],
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl) as ImageProvider
                : const AssetImage('assets/user.png'),
          );
        }),
      ),
    ];
  }

  Widget _buildCartoonCategory(String assetName, String label, {VoidCallback? onTap, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 75, height: 75,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: icon != null
                ? Icon(icon, color: const Color(0xFF1E8C78), size: 38)
                : Image.asset(assetName, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.medical_services, color: Color(0xFF1E8C78), size: 38)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDynamicBanner() {
    return Obx(() {
      final title = _bannerCtrl.title.value;
      final subtitle = _bannerCtrl.subtitle.value;
      final btnText = _bannerCtrl.buttonText.value;
      final imgUrl = _bannerCtrl.imageUrl.value;

      return Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1E8C78),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 5, top: 18, right: 18, bottom: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.only(right: 20, top: 20, bottom: 20, left: 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Color(0xFF1E8C78), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (subtitle.isNotEmpty) ...
                    [
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Get.to(() => const EtmanDoctorScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E8C78), foregroundColor: Colors.white,
                        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      ),
                      child: Text(btnText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0, bottom: 0, top: -5,
              child: imgUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
                      child: Image.network(
                        imgUrl, height: 185, width: 135, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/doctor5.png', height: 185, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 100, color: Color(0xFF1E8C78)),
                        ),
                      ),
                    )
                  : Image.asset(
                      'assets/doctor5.png', height: 185, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 100, color: Color(0xFF1E8C78)),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTopDoctorCard(Map<String, dynamic> doc) {
    return GestureDetector(
      onTap: () => Get.to(() => EtmanDoctorBookingScreen(doctorData: doc)),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: Colors.white, backgroundImage: AssetImage(doc['image'])),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(doc['specialty'], style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4), 
                    Text(
                      doc['rating'], 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFFFB300)),
                    )
                  ]
                ),
                Text(doc['distance'], style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineAction(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFB2DFDB),
          borderRadius: BorderRadius.circular(12)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00695C), size: 28),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF00695C))),
          ],
        ),
      ),
    );
  }
}
