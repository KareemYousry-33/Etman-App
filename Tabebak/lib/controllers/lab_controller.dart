import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_controller.dart';

class LabController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  var isLoading = false.obs;
  var isSaving = false.obs;
  
  var requests = <Map<String, dynamic>>[].obs;
  var ads = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    final uid = _authController.currentUser.value?.uid;
    if (uid != null) {
      _listenToRequests(uid);
      _listenToAds(uid);
    }
  }

  void _listenToRequests(String uid) {
    _firestore
        .collection('lab_requests')
        .where('labId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      requests.value = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  void _listenToAds(String uid) {
    _firestore
        .collection('lab_ads')
        .where('labId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      ads.value = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> addAd(String content) async {
    final uid = _authController.currentUser.value?.uid;
    if (uid == null || content.isEmpty) return;

    isSaving.value = true;
    try {
      await _firestore.collection('lab_ads').add({
        'labId': uid,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('تم', 'تم إضافة الإعلان بنجاح', backgroundColor: const Color(0xFF135B51), colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حفظ الإعلان', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteAd(String adId) async {
    try {
      await _firestore.collection('lab_ads').doc(adId).delete();
      Get.snackbar('تم', 'تم مسح الإعلان بنجاح', backgroundColor: const Color(0xFF135B51), colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل مسح الإعلان', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> updateRequestStatus(String reqId, String status) async {
    try {
      await _firestore.collection('lab_requests').doc(reqId).update({'status': status});
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث حالة الطلب', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> updateLabDetails({String? workingHours, String? workingDays}) async {
    final uid = _authController.currentUser.value?.uid;
    if (uid == null) return;
    try {
      Map<String, dynamic> data = {};
      if (workingHours != null) data['workingHours'] = workingHours;
      if (workingDays != null) data['workingDays'] = workingDays;
      await _firestore.collection('users').doc(uid).update(data);
      Get.snackbar('تم', 'تم تحديث البيانات بنجاح', backgroundColor: const Color(0xFF135B51), colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل التحديث', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}
