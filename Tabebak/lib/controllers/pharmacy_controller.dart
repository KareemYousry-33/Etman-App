import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pharmacy_model.dart';
import 'auth_controller.dart';

class PharmacyController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var isSaving = false.obs;
  var orders = <Map<String, dynamic>>[].obs;
  var pharmacies = <PharmacyModel>[].obs; // For patient-facing screens

  // Real-time state for Pharmacy Dashboard UI — backed by Firestore
  var adsAndOffers = <Map<String, dynamic>>[].obs;
  var workingHours = 'من 9 صباحاً حتى 11 مساءً'.obs;
  var workingDays = 'طوال الأسبوع (الجمعة مفتوح)'.obs;

  // Governorates and Cities for Egypt
  final Map<String, List<String>> locations = {
    'القاهرة': ['القاهرة الجديدة', 'مدينة نصر', 'المعادي', 'وسط البلد', 'حلوان'],
    'الجيزة': ['٦ أكتوبر', 'الدقي', 'الهرم', 'المهندسين', 'فيصل'],
    'الإسكندرية': ['سيدي جابر', 'سموحة', 'المنتزة', 'العجمي', 'ميامي'],
    'القليوبية': ['بنها', 'شبرا الخيمة', 'العبور', 'قليوب'],
    'الشرقية': ['الزقازيق', 'العاشر من رمضان', 'بلبيس'],
  };

  List<String> get governorates => locations.keys.toList();
  List<String> getCities(String governorate) => locations[governorate] ?? [];

  @override
  void onInit() {
    super.onInit();
    // Only load data when there's a logged-in user
    final authController = Get.find<AuthController>();
    ever(authController.currentUser, (user) {
      if (user != null) {
        fetchAllPharmacies();
        _listenToAds(user.uid);
        _loadWorkingInfo(user.uid);
      }
    });
    // Also load immediately if user is already logged in
    final uid = authController.currentUser.value?.uid;
    if (uid != null) {
      fetchAllPharmacies();
      _listenToAds(uid);
      _loadWorkingInfo(uid);
    }
  }

  void _loadPharmacyData() {
    // Kept for compatibility — logic now handled in onInit
  }

  // ─── Fetch all pharmacies from users collection (role=pharmacy) ───────────
  Future<void> fetchAllPharmacies() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'pharmacy')
          .get();
      pharmacies.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return PharmacyModel(
          id: doc.id,
          name: data['name'] ?? '',
          address: data['location'] ?? '${data['city'] ?? ''}, ${data['governorate'] ?? ''}',
          latitude: (data['latitude'] as num?)?.toDouble() ?? 30.05,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 31.25,
          phoneNumber: data['phoneNumber'],
          imageUrl: data['photoUrl'] ?? data['imageUrl'],
          governorate: data['governorate'],
          city: data['city'],
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          bio: data['bio'] ?? '',
          specialty: data['specialty'],
        );
      }).toList();
    } catch (e) {
      debugPrint('fetchAllPharmacies error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Fetch pharmacies by location (now from users collection) ──────────────
  Future<void> fetchPharmaciesByLocation(String governorate, String city) async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'pharmacy')
          .where('governorate', isEqualTo: governorate)
          .where('city', isEqualTo: city)
          .get();
      pharmacies.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return PharmacyModel(
          id: doc.id,
          name: data['name'] ?? '',
          address: data['location'] ?? '$city, $governorate',
          latitude: (data['latitude'] as num?)?.toDouble() ?? 30.05,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 31.25,
          phoneNumber: data['phoneNumber'],
          imageUrl: data['photoUrl'] ?? data['imageUrl'],
          governorate: governorate,
          city: city,
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          bio: data['bio'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('fetchPharmaciesByLocation error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Ads: Real-time listener from Firestore ───────────────────────────────
  void _listenToAds(String pharmacyId) {
    _firestore
        .collection('pharmacy_ads')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      adsAndOffers.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'desc': data['desc'] ?? '',
          'date': data['createdAt'],
        };
      }).toList();
    }, onError: (e) {
      // Ignore index errors silently — will work once index is created
      debugPrint('Ads listener error: $e');
    });
  }

  // ─── Add Offer → Firestore ─────────────────────────────────────────────────
  Future<void> addOffer(String title, String desc) async {
    final authController = Get.find<AuthController>();
    final uid = authController.currentUser.value?.uid;
    if (uid == null) return;

    isSaving.value = true;
    try {
      await _firestore.collection('pharmacy_ads').add({
        'pharmacyId': uid,
        'title': title,
        'desc': desc,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('تم بنجاح', 'تم إضافة العرض وسيظهر للمرضى فوراً',
          backgroundColor: const Color(0xFF1E8C78), colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إضافة الإعلان: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Delete Offer → Firestore ──────────────────────────────────────────────
  Future<void> deleteOffer(String adId) async {
    try {
      await _firestore.collection('pharmacy_ads').doc(adId).delete();
      Get.snackbar('تم الحذف', 'تم مسح الإعلان بنجاح',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حذف الإعلان: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // ─── Load working info from Firestore ─────────────────────────────────────
  Future<void> _loadWorkingInfo(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['workingHours'] != null) workingHours.value = data['workingHours'];
        if (data['workingDays'] != null) workingDays.value = data['workingDays'];
      }
    } catch (e) {
      debugPrint('Load working info error: $e');
    }
  }

  // ─── Update working info → Firestore ──────────────────────────────────────
  Future<void> updateWorkingInfo(String hours, String days) async {
    final authController = Get.find<AuthController>();
    final uid = authController.currentUser.value?.uid;
    if (uid == null) return;

    workingHours.value = hours;
    workingDays.value = days;

    try {
      await _firestore.collection('users').doc(uid).update({
        'workingHours': hours,
        'workingDays': days,
      });
      Get.snackbar('تم التحديث', 'تم حفظ مواعيد العمل بنجاح',
          backgroundColor: const Color(0xFF1E8C78), colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حفظ المواعيد: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // ─── Listen to incoming prescription chats ────────────────────────────────
  void listenToIncomingChats(String pharmacyId) {
    _listenToAds(pharmacyId); // refresh ads too
    _loadWorkingInfo(pharmacyId);

    _firestore
        .collection('chat_rooms')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .where('type', isEqualTo: 'pharmacy')
        .snapshots()
        .listen((snapshot) {
      orders.value = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'patientName': 'مريض (طلب روشتة)',
          'status': 'active',
          'type': 'طلب روشتة',
          'createdAt': (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'receiverId': (data['participants'] as List?)
                  ?.firstWhere((id) => id != pharmacyId, orElse: () => '') ??
              '',
        };
      }).toList();
    });
  }
}
