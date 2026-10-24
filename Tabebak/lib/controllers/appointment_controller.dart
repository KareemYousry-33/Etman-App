import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/appointment_model.dart';

class AppointmentController extends GetxController {
  static AppointmentController get to => Get.find<AppointmentController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var appointments = <AppointmentModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch appointments whenever the user logs in
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        fetchAppointments();
      } else {
        appointments.clear();
      }
    });
  }

  Future<void> fetchAppointments() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      appointments.value = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching appointments: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addAppointment(AppointmentModel appointment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = await _firestore.collection('appointments').add({
        ...appointment.toFirestore(),
        'patientId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update local state by adding the ID
      final newAppointment = appointment.copyWith(id: docRef.id);
      appointments.insert(0, newAppointment);
      
      Get.snackbar("نجاح", "تم حجز الموعد بنجاح!", snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar("خطأ", "فشل في حجز الموعد: $e", snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> cancelAppointment(String id) async {
    try {
      await _firestore.collection('appointments').doc(id).delete();
      appointments.removeWhere((item) => item.id == id);
      Get.snackbar("تم الإلغاء", "تم إلغاء الموعد بنجاح.", snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar("خطأ", "فشل في إلغاء الموعد: $e", snackPosition: SnackPosition.BOTTOM);
    }
  }

  List<AppointmentModel> get upcomingAppointments => 
      appointments.where((item) => item.status == AppointmentStatus.pending || item.status == AppointmentStatus.approved).toList();

  List<AppointmentModel> get historyAppointments => 
      appointments.where((item) => item.status == AppointmentStatus.completed || item.status == AppointmentStatus.cancelled).toList();
}
