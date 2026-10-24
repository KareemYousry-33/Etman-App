import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';
import '../services/notification_service.dart';

class DoctorController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  
  var isLoading = false.obs;
  var appointments = <AppointmentModel>[].obs;
  var availableTimeSlots = <String>[].obs;
  
  // Stream subscription to manage lifecycle
  StreamSubscription<QuerySnapshot>? _appointmentsSubscription;
  
  @override
  void onInit() {
    super.onInit();
    
    // Fetch immediately if user is already logged in as doctor or nurse
    final role = _authController.currentUser.value?.role;
    if (role == UserRole.doctor || role == UserRole.nurse) {
      fetchDoctorAppointments();
      loadAvailability();
    }

    // Listen for future changes to the current user
    ever(_authController.currentUser, (UserModel? user) {
      if (user?.role == UserRole.doctor || user?.role == UserRole.nurse) {
        fetchDoctorAppointments();
        loadAvailability();
      }
    });
  }
  
  // Fetch appointments for the current doctor
  void fetchDoctorAppointments() {
    final doctor = _authController.currentUser.value;
    if (doctor == null || doctor.role != UserRole.doctor) {
      appointments.clear();
      return;
    }

    isLoading.value = true;
    
    // Cancel any existing subscription to prevent duplicates/leaks
    _appointmentsSubscription?.cancel();
    
    // Use snapshots for real-time updates
    _appointmentsSubscription = _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctor.email) // Match using explicit email alias
        .snapshots()
        .listen((snapshot) {
      List<AppointmentModel> fetched = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      // Sort locally
      fetched.sort((a, b) => a.date.compareTo(b.date));
      
      appointments.value = fetched;
      isLoading.value = false;
    }, onError: (e) {
      isLoading.value = false;
      // SILENT LOGGING to avoid annoying the user with snackbars
    });
  }

  @override
  void onClose() {
    _appointmentsSubscription?.cancel();
    super.onClose();
  }
  
  // Update appointment status (approve, complete, or cancel)
  Future<void> updateAppointmentStatus(String appointmentId, AppointmentStatus newStatus) async {
    final doctor = _authController.currentUser.value;
    if (doctor == null || doctor.role != UserRole.doctor) {
      Get.snackbar(
        'Permission Denied',
        'Only doctors can update appointment status.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    isLoading.value = true;
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': newStatus.toString().split('.').last,
      });
      
      // Trigger notification (simulated for demonstration)
      String title = '';
      String body = '';
      if (newStatus == AppointmentStatus.approved) {
        title = 'تم قبول موعدك! ✅';
        body = 'قام الدكتور بالموافقة على حجزك. نراك قريباً!';
      } else if (newStatus == AppointmentStatus.cancelled) {
        title = 'تم إلغاء الموعد ❌';
        body = 'عذراً، قام الدكتور بإلغاء الموعد. يمكنك حجز موعد آخر.';
      }

      if (title.isNotEmpty) {
        try {
          await Get.find<NotificationService>().showInstantNotification(
            id: appointmentId.hashCode,
            title: title,
            body: body,
            payload: 'appointments',
          );
        } catch (_) {}
      }
      
      Get.snackbar(
        'Success',
        'Appointment status updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update appointment status: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Load doctor availability time slots
  Future<void> loadAvailability() async {
    final doctor = _authController.currentUser.value;
    if (doctor == null || doctor.role != UserRole.doctor) {
      return;
    }
    
    isLoading.value = true;
    try {
      DocumentSnapshot docSnapshot = await _firestore
          .collection('users')
          .doc(doctor.uid)
          .get();
      
      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        if (data['availability'] != null) {
          availableTimeSlots.value = List<String>.from(data['availability']);
        } else {
          availableTimeSlots.value = [];
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load availability: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Update doctor availability time slots
  Future<void> updateAvailability(List<String> newAvailability) async {
    final doctor = _authController.currentUser.value;
    if (doctor == null || doctor.role != UserRole.doctor) {
      Get.snackbar(
        'Permission Denied',
        'Only doctors can update availability.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    isLoading.value = true;
    try {
      await _firestore.collection('users').doc(doctor.uid).update({
        'availability': newAvailability,
      });
      
      // Update local state
      availableTimeSlots.value = newAvailability;
      
      Get.snackbar(
        'Success',
        'Availability updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update availability: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
