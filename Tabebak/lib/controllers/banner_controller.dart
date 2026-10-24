import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class BannerController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  var title = 'حماية مبكرة لصحة عائلتك اليوم'.obs;
  var subtitle = ''.obs;
  var buttonText = 'معرفة المزيد'.obs;
  var imageUrl = ''.obs; // empty = use local asset
  var isLoading = false.obs;
  var isSaving = false.obs;

  static const _docId = 'home_banner';

  @override
  void onInit() {
    super.onInit();
    _listenBanner();
  }

  /// Real-time listener on the banner document
  void _listenBanner() {
    _firestore
        .collection('settings')
        .doc(_docId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final d = doc.data()!;
        title.value      = d['title']      ?? 'حماية مبكرة لصحة عائلتك اليوم';
        subtitle.value   = d['subtitle']   ?? '';
        buttonText.value = d['buttonText'] ?? 'معرفة المزيد';
        imageUrl.value   = d['imageUrl']   ?? '';
      }
    });
  }

  /// Save new text data to Firestore
  Future<void> saveBannerText({
    required String title,
    required String subtitle,
    required String buttonText,
  }) async {
    isSaving.value = true;
    try {
      await _firestore.collection('settings').doc(_docId).set({
        'title':      title,
        'subtitle':   subtitle,
        'buttonText': buttonText,
        'imageUrl':   imageUrl.value,
        'updatedAt':  FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  /// Upload a new banner image and save its URL
  Future<void> uploadBannerImage(File imageFile) async {
    isLoading.value = true;
    try {
      final ref = _storage
          .ref()
          .child('banners/home_banner_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();

      await _firestore.collection('settings').doc(_docId).set({
        'imageUrl':  url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      imageUrl.value = url;
    } catch (e) {
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}
