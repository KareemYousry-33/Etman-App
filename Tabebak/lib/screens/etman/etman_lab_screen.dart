import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'etman_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/p2p_chat_controller.dart' as import_p2p;
import 'p2p_chat_screen.dart' as import_p2p_screen;
import 'etman_doctor_booking_screen.dart' as import_booking;

// ─── Simple Lab Model ─────────────────────────────────────────────────────────
class LabModel {
  final String id;
  final String name;
  final String governorate;
  final String city;
  final String address;
  final String phoneNumber;
  final double rating;
  final String? specialty;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  double? distanceInMeters;

  LabModel({
    required this.id,
    required this.name,
    this.governorate = '',
    this.city = '',
    this.address = '',
    this.phoneNumber = '',
    this.rating = 4.5,
    this.specialty,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.photoUrl,
    this.distanceInMeters,
  });

  factory LabModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LabModel(
      id: doc.id,
      name: d['name'] ?? 'معمل',
      governorate: d['governorate'] ?? '',
      city: d['city'] ?? '',
      address: d['address'] ?? d['location'] ?? '',
      phoneNumber: d['phoneNumber'] ?? '',
      rating: (d['rating'] is num) ? (d['rating'] as num).toDouble() : 4.5,
      specialty: d['specialty'],
      latitude: (d['latitude'] is num) ? (d['latitude'] as num).toDouble() : 0.0,
      longitude: (d['longitude'] is num) ? (d['longitude'] as num).toDouble() : 0.0,
      photoUrl: d['photoUrl'] ?? d['imageUrl'] ?? d['image'],
    );
  }
}

// ─── Lab Controller ──────────────────────────────────────────────────────────
class LabController extends GetxController {
  final String role;
  var labs = <LabModel>[].obs;
  
  LabController({required this.role});
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllLabs();
  }

  Future<void> fetchAllLabs() async {
    isLoading.value = true;
    try {
      // Fetch from 'users' collection where role = 'lab'
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      labs.value = snap.docs.map((d) => LabModel.fromFirestore(d)).toList();

      // If no labs yet, seed some demo labs
      if (labs.isEmpty) {
        labs.value = role == 'lab' ? _demoLabs() : _demoXrays();
      }
    } catch (_) {
      labs.value = role == 'lab' ? _demoLabs() : _demoXrays();
    } finally {
      isLoading.value = false;
    }
  }

  List<LabModel> _demoLabs() => [
    LabModel(id: 'lab1', name: 'معمل الدكتور إسلام', governorate: 'القاهرة', city: 'مدينة نصر',
        address: 'ش مكرم عبيد، مدينة نصر', phoneNumber: '01001234567', rating: 4.8,
        specialty: 'تحاليل طبية شاملة'),
    LabModel(id: 'lab2', name: 'معمل النيل للتحاليل', governorate: 'الجيزة', city: 'المهندسين',
        address: '12 ش جامعة الدول، المهندسين', phoneNumber: '01112345678', rating: 4.7,
        specialty: 'تحاليل طبية شاملة'),
    LabModel(id: 'lab3', name: 'معامل كلير', governorate: 'القاهرة', city: 'المعادي',
        address: 'ميدان المعادي', phoneNumber: '01223456789', rating: 4.9,
        specialty: 'تحاليل هرمونات وصبغيات'),
    LabModel(id: 'lab4', name: 'معامل المدينة', governorate: 'الإسكندرية', city: 'سموحة',
        address: 'ش فوزي معاذ، سموحة', phoneNumber: '01334567890', rating: 4.6,
        specialty: 'تحاليل طبية شاملة'),
    LabModel(id: 'lab5', name: 'معمل البشير', governorate: 'القليوبية', city: 'بنها',
        address: 'شارع الجيش، بنها', phoneNumber: '01012345678', rating: 4.5,
        specialty: 'تحاليل دم وبول'),
  ];

  List<LabModel> _demoXrays() => [
    LabModel(id: 'xray1', name: 'مركز كايرو سكان', governorate: 'القاهرة', city: 'مصر الجديدة',
        address: 'شارع الحجاز، مصر الجديدة', phoneNumber: '19000', rating: 4.9,
        specialty: 'أشعة مقطعية ورنين'),
    LabModel(id: 'xray2', name: 'مركز تكنوسكان', governorate: 'الجيزة', city: 'المهندسين',
        address: 'جامعة الدول، المهندسين', phoneNumber: '19010', rating: 4.7,
        specialty: 'أشعة عادية وموجات صوتية'),
    LabModel(id: 'xray3', name: 'مركز ألفا سكان', governorate: 'القاهرة', city: 'مدينة نصر',
        address: 'مكرم عبيد، مدينة نصر', phoneNumber: '16181', rating: 4.8,
        specialty: 'بانوراما أسنان وأشعة تداخلية'),
  ];
}

// ─── Lab Screen ───────────────────────────────────────────────────────────────
class EtmanLabScreen extends StatefulWidget {
  final String role;
  final String title;

  const EtmanLabScreen({
    Key? key,
    this.role = 'lab',
    this.title = 'المعامل الطبية',
  }) : super(key: key);

  @override
  State<EtmanLabScreen> createState() => _EtmanLabScreenState();
}

class _EtmanLabScreenState extends State<EtmanLabScreen> {
  late final LabController labController;
  String _activeFilter = 'كل';
  String _searchQuery = '';
  String _currentLocationName = 'تحديد موقعي للبحث بالأقرب';

  static const _teal = Color(0xFF00695C);
  static const _lightMint = Color(0xFFEAF5F3);

  @override
  void initState() {
    super.initState();
    labController = Get.isRegistered<LabController>(tag: widget.role)
        ? Get.find<LabController>(tag: widget.role)
        : Get.put(LabController(role: widget.role), tag: widget.role);
  }

  List<LabModel> get _filtered {
    return labController.labs.where((l) {
      final nameOk = l.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final filterOk = _activeFilter == 'كل' ||
          (l.specialty?.contains(_activeFilter) ?? false);
      return nameOk && filterOk;
    }).toList()
      ..sort((a, b) {
        if (a.distanceInMeters == null && b.distanceInMeters == null) return 0;
        if (a.distanceInMeters == null) return 1;
        if (b.distanceInMeters == null) return -1;
        return a.distanceInMeters!.compareTo(b.distanceInMeters!);
      });
  }

  Future<void> _fetchRealLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('خطأ', 'يرجى تفعيل خدمات الموقع', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        Get.snackbar('تحذير', 'تم رفض إذن الموقع', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
    }
    if (perm == LocationPermission.deniedForever) {
      Get.snackbar('خطأ', 'تم حظر صلاحيات الموقع نهائياً من الإعدادات', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (Get.isDialogOpen == false) {
      Get.dialog(const Center(child: CircularProgressIndicator(color: EtmanColors.primaryTeal)), barrierDismissible: false);
    }
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      try {
        final pm = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (pm.isNotEmpty) {
          _currentLocationName = 'موقعك: ${pm.first.locality ?? pm.first.subAdministrativeArea ?? 'الحي الحالي'}';
        }
      } catch (_) {
        _currentLocationName = 'تم تحديد الموقع';
      }
      for (var lab in labController.labs) {
        if (lab.latitude != 0.0 || lab.longitude != 0.0) {
          lab.distanceInMeters = Geolocator.distanceBetween(pos.latitude, pos.longitude, lab.latitude, lab.longitude);
        }
      }
      setState(() {});
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar('تم تحديد الموقع 📍', 'يتم الآن عرض المعامل الأقرب إليك',
          backgroundColor: EtmanColors.primaryTeal, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar('خطأ', 'تعذر جلب الموقع', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _callLab(String phone) async {
    if (phone.isEmpty) {
      Get.snackbar('خطأ', 'رقم المعمل غير متوفر', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('خطأ', 'لا يمكن فتح تطبيق الاتصال', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _startLabAdminChat(String initialMsg) async {
    final p2pChatController = Get.put(import_p2p.P2PChatController());
    Get.dialog(const Center(child: CircularProgressIndicator(color: _teal)), barrierDismissible: false);
    try {
      const adminId = 'admin';
      final roomId = await p2pChatController.getOrCreateChatRoom(receiverId: adminId, type: 'admin');
      if (initialMsg.isNotEmpty) {
        await p2pChatController.sendMessage(roomId: roomId, receiverId: adminId, text: initialMsg);
      }
      Get.back();
      Get.to(() => import_p2p_screen.P2PChatScreen(roomId: roomId, receiverName: 'إدارة المعامل', receiverId: adminId));
    } catch (e) {
      Get.back();
      Get.snackbar('خطأ', 'فشل الاتصال بالإدارة', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Get.back(),
          ),
          title: GestureDetector(
            onTap: _fetchRealLocation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, color: _teal, size: 20),
                const SizedBox(width: 4),
                Text(
                  _currentLocationName.contains('تحديد') ? 'تحديد موقعي' : _currentLocationName.split(': ').last,
                  style: const TextStyle(color: _teal, fontWeight: FontWeight.w900, fontSize: 16,
                      decoration: TextDecoration.underline, decorationColor: _teal),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header Block ──
                    Container(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25, top: 10),
                      decoration: const BoxDecoration(color: _lightMint),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[400]!, width: 1.2),
                            ),
                            child: TextField(
                              textAlign: TextAlign.right,
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: widget.role == 'lab' ? 'ابحث عن معمل تحاليل...' : 'ابحث عن مركز أشعة...',
                                hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _actionItem(Icons.phone_in_talk_outlined, 'تواصل معنا',
                                  onTap: () async { final uri = Uri.parse('tel:01013558197'); if (await canLaunchUrl(uri)) await launchUrl(uri); }),
                              _actionItem(Icons.science_outlined, widget.role == 'lab' ? 'اطلب تحليل' : 'احجز أشعة', onTap: () => _startLabAdminChat(widget.role == 'lab' ? 'أريد طلب تحليل منزلي' : 'أريد حجز أشعة')),
                              _actionItem(Icons.receipt_long_outlined, 'رفع نتيجة', onTap: () => _startLabAdminChat(widget.role == 'lab' ? 'أريد رفع نتيجة تحليل لمراجعتها' : 'أريد رفع نتيجة أشعة')),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ── Banner ──
                    SizedBox(
                      height: 150,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _bannerCard('خصم 20%', widget.role == 'lab' ? 'على جميع تحاليل الهرمونات' : 'على الرنين المغناطيسي', Colors.amber),
                          const SizedBox(width: 15),
                          _bannerCard(widget.role == 'lab' ? 'تحليل منزلي' : 'خصم المتابعة', widget.role == 'lab' ? 'نأتي إليك في أي مكان' : 'أشعة السونار', const Color(0xFF00B0FF)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ── Filter Chips ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(widget.role == 'lab' ? 'المعامل القريبة' : 'مراكز الأشعة القريبة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _filterChip('كل'),
                          const SizedBox(width: 10),
                          _filterChip(widget.role == 'lab' ? 'تحاليل طبية شاملة' : 'أشعة مقطعية ورنين'),
                          const SizedBox(width: 10),
                          _filterChip(widget.role == 'lab' ? 'تحاليل هرمونات وصبغيات' : 'سونار وموجات صوتية'),
                          const SizedBox(width: 10),
                          _filterChip(widget.role == 'lab' ? 'تحاليل دم وبول' : 'أشعة عادية وبانوراما'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ── Labs List ──
                    Obx(() {
                      if (labController.isLoading.value) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                      if (_filtered.isEmpty) {
                        return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(widget.role == 'lab' ? 'لا توجد معامل تطابق بحثك' : 'لا توجد مراكز أشعة تطابق بحثك')));
                      }
                      return Column(children: _filtered.map(_labCard).toList());
                    }),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionItem(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105, height: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _lightMint,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _teal, width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _teal, size: 26),
            const SizedBox(height: 6),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _teal)),
          ],
        ),
      ),
    );
  }

  Widget _bannerCard(String badge, String title, Color badgeColor) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF135B51), Color(0xFF1E8C78)], begin: Alignment.centerRight, end: Alignment.centerLeft),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10)),
            child: Text(badge, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.right),
          const SizedBox(height: 4),
          const Icon(Icons.science_outlined, color: Colors.white70, size: 22),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _teal : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: _teal, width: 1.2),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : _teal, fontWeight: FontWeight.w900, fontSize: 12)),
      ),
    );
  }

  Widget _labCard(LabModel lab) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF3F7F7), borderRadius: BorderRadius.circular(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: _lightMint, 
              shape: BoxShape.circle,
              image: (lab.photoUrl != null && lab.photoUrl!.startsWith('http'))
                  ? DecorationImage(image: NetworkImage(lab.photoUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: (lab.photoUrl == null || !lab.photoUrl!.startsWith('http'))
                ? const Icon(Icons.science_rounded, color: _teal, size: 36)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lab.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87), overflow: TextOverflow.ellipsis),
                Text('${lab.governorate} - ${lab.city}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                if (lab.distanceInMeters != null)
                  Text('تبعد ${(lab.distanceInMeters! / 1000).toStringAsFixed(1)} كم عنك',
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                if (lab.specialty != null)
                  Text(lab.specialty!, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text(lab.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _callLab(lab.phoneNumber),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB2DFDB),
                          foregroundColor: _teal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          minimumSize: const Size(60, 32),
                        ),
                        child: const Text('اتصل الآن', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Pass lab data as if it were a doctor to reuse the booking screen
                          Get.to(() => import_booking.EtmanDoctorBookingScreen(doctorData: {
                            'uid': lab.id,
                            'name': lab.name,
                            'specialty': lab.specialty ?? 'معمل تحاليل',
                            'rating': lab.rating,
                            'price': 100.0, // Default price or fetch from lab
                            'governorate': lab.governorate,
                            'city': lab.city,
                          }));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          minimumSize: const Size(60, 32),
                        ),
                        child: const Text('احجز', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
