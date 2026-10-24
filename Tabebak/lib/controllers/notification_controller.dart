import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var notifications = <Map<String, dynamic>>[].obs;
  var isSending = false.obs;
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    listenToNotifications();
  }

  /// Listen to all notifications in real-time (for all users)
  void listenToNotifications() {
    _firestore
        .collection('notifications')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      notifications.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'body': data['body'] ?? '',
          'sentAt': data['sentAt'],
          'sentBy': data['sentBy'] ?? 'admin',
          'type': data['type'] ?? 'general',
        };
      }).toList();
      unreadCount.value = notifications.length;
    }, onError: (e) {
      debugPrint('Notifications listener error: $e');
    });
  }

  /// Admin: Send notification to all users (saves in Firestore)
  /// FCM push will trigger via Cloud Function if set up
  Future<void> sendNotificationToAll({
    required String title,
    required String body,
    String type = 'general',
  }) async {
    if (title.trim().isEmpty || body.trim().isEmpty) {
      Get.snackbar('تنبيه', 'يرجى ملء العنوان والمحتوى',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isSending.value = true;
    try {
      await _firestore.collection('notifications').add({
        'title': title.trim(),
        'body': body.trim(),
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': 'admin',
        'type': type,
        'targetAudience': 'all', // all users
      });

      Get.snackbar(
        'تم الإرسال ✓',
        'تم إرسال الإشعار لجميع المستخدمين',
        backgroundColor: const Color(0xFF1E8C78),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إرسال الإشعار: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSending.value = false;
    }
  }

  /// Admin: Delete a notification
  Future<void> deleteNotification(String notifId) async {
    try {
      await _firestore.collection('notifications').doc(notifId).delete();
      Get.snackbar('تم', 'تم حذف الإشعار',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حذف الإشعار: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  /// Helper: Format timestamp
  String formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.day}/${dt.month}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }
}
