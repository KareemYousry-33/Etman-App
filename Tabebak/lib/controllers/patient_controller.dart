import 'dart:async';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';
import '../services/notification_service.dart';
import '../services/email_service.dart';

class PatientController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  
  // Track notified appointments locally for the session
  final Set<String> _notifiedAppointmentIds = {};
  
  var isLoading = false.obs;
  var myAppointments = <AppointmentModel>[].obs;
  
  // Stream subscription to manage lifecycle
  StreamSubscription<QuerySnapshot>? _appointmentsSubscription;
  
  @override
  void onInit() {
    super.onInit();
    
    // Fetch immediately if user is already logged in as patient
    if (_authController.currentUser.value?.role == UserRole.patient) {
      fetchPatientAppointments();
    }

    // Listen for future changes to the current user
    ever(_authController.currentUser, (UserModel? user) {
      if (user?.role == UserRole.patient) {
        fetchPatientAppointments();
      }
    });

    // Listen for appointment updates to trigger notifications
    ever(myAppointments, (List<AppointmentModel> appointments) {
      for (var appointment in appointments) {
        if (appointment.status == AppointmentStatus.approved && 
            !_notifiedAppointmentIds.contains(appointment.id)) {
          
          _notifiedAppointmentIds.add(appointment.id!);
          
          // Trigger instant notification
          final notificationService = Get.find<NotificationService>();
          notificationService.showInstantNotification(
            id: appointment.id.hashCode,
            title: '🎉 تم قبول موعدك!',
            body: 'لقد وافق د. ${appointment.doctorName} على حجزك. نراك قريباً!',
            payload: 'appointments',
          );
        }
      }
    });
  }
  
  // Fetch appointments for the current patient
  void fetchPatientAppointments() {
    final patient = _authController.currentUser.value;
    if (patient == null || patient.role != UserRole.patient) {
      myAppointments.clear();
      return;
    }

    isLoading.value = true;
    
    // Cancel any existing subscription
    _appointmentsSubscription?.cancel();
    
    // Use snapshots for real-time updates
    _appointmentsSubscription = _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patient.uid)
        .snapshots()
        .listen((snapshot) {
      List<AppointmentModel> fetched = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      // Sort locally to avoid needing a composite index in Firestore
      fetched.sort((a, b) => a.date.compareTo(b.date));
      
      myAppointments.value = fetched;
      isLoading.value = false;
    }, onError: (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to sync transactions: $e');
    });
  }
  
  Future<void> bookAppointment({
    required String doctorId,
    required String doctorName,
    required String doctorImage,
    required DateTime appointmentDate,
    required String timeSlot,
    String? notes,
    String providerRole = 'doctor',
  }) async {
    final patient = _authController.currentUser.value;
    if (patient == null || patient.role != UserRole.patient) {
      Get.snackbar(
        'Permission Denied',
        'Only patients can book appointments.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Normalize the date to midnight to ensure consistency
    final normalizedDate = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
    
    isLoading.value = true;
    try {
      // First check if the doctor has this time slot available
      DocumentSnapshot doctorDoc = await _firestore
          .collection('users')
          .doc(doctorId)
          .get();
          
      if (!doctorDoc.exists) {
        throw 'Doctor not found';
      }
      
      // Check if the time slot is already booked for this doctor
      QuerySnapshot existingAppointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('timeSlot', isEqualTo: timeSlot)
          .where('status', whereIn: ['pending', 'approved'])
          .get();
          
      // Filter by date locally to avoid a composite index requirement
      bool alreadyBooked = existingAppointments.docs.any((doc) {
        DateTime bookedDate = (doc.get('date') as Timestamp).toDate();
        return DateUtils.isSameDay(bookedDate, normalizedDate);
      });
          
      if (alreadyBooked) {
        throw 'This time slot is already booked for this date';
      }
      
      // Create the appointment with enriched patient profile data
      AppointmentModel appointment = AppointmentModel(
        doctorId: doctorId,
        patientId: patient.uid,
        patientName: patient.name,
        doctorName: doctorName,
        doctorSpecialty: doctorDoc.get('specialty') ?? 'General Doctor',
        doctorImage: doctorImage,
        date: normalizedDate,
        timeSlot: timeSlot,
        notes: notes,
        providerRole: providerRole,
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
      );
      
      final Map<String, dynamic> appointmentData = appointment.toFirestore();
      
      // Enrich with extra patient fields for the doctor to see
      appointmentData.addAll({
        'patientEmail':   patient.email,
        'patientPhone':   patient.phoneNumber ?? 'غير مسجل',
        'patientAge':     patient.age ?? 0,
        'patientHistory': patient.medicalHistory ?? 'لا يوجد تاريخ طبي مسجل',
        'patientAddress': patient.address ?? 'غير مسجل',
      });
      
      await _firestore.collection('appointments').add(appointmentData);

      // ── Email notification to the doctor ─────────────────────────────────
      try {
        // For seeded doctors, doctorId IS the email (e.g. sara@etman.com).
        // For any doctor registered via Firebase Auth with a UID, we fetch it.
        final String doctorEmail;
        if (doctorId.contains('@')) {
          doctorEmail = doctorId;
        } else {
          final doctorSnap = await _firestore.collection('users').doc(doctorId).get();
          doctorEmail = doctorSnap.data()?['email'] as String? ?? '';
        }

        if (doctorEmail.isNotEmpty) {
          await EmailService.sendBookingToDoctorEmail(
            doctorEmail:     doctorEmail,
            doctorName:      doctorName,
            patientName:     patient.name,
            patientEmail:    patient.email,
            patientPhone:    patient.phoneNumber ?? 'غير مسجل',
            patientAge:      (patient.age ?? 0).toString(),
            patientAddress:  patient.address ?? 'غير مسجل',
            patientHistory:  patient.medicalHistory ?? 'لا يوجد تاريخ طبي مسجل',
            appointmentDate: DateFormat('EEEE, d MMMM yyyy', 'ar').format(normalizedDate),
            appointmentTime: timeSlot,
            notes:           notes,
          );
        }
      } catch (_) {
        // Silent — email failure should never block booking
      }
      // ─────────────────────────────────────────────────────────────────
      Get.snackbar(
        'تم الحجز ✅',
        'تم حجز موعدك بنجاح وتم إرسال تفاصيلك للدكتور',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to book appointment: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Cancel an appointment
  Future<void> cancelAppointment(String appointmentId) async {
    final patient = _authController.currentUser.value;
    if (patient == null || patient.role != UserRole.patient) {
      Get.snackbar(
        'Permission Denied',
        'Only patients can cancel their appointments.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    isLoading.value = true;
    try {
      // Get the appointment first to verify it belongs to this patient
      DocumentSnapshot appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
          
      if (!appointmentDoc.exists) {
        throw 'Appointment not found';
      }
      
      Map<String, dynamic> data = appointmentDoc.data() as Map<String, dynamic>;
      if (data['patientId'] != patient.uid) {
        throw 'You can only cancel your own appointments';
      }
      
      // Delete the appointment document
      await _firestore.collection('appointments').doc(appointmentId).delete();

      Get.snackbar(
        'Success',
        'Appointment removed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to cancel appointment: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _appointmentsSubscription?.cancel();
    super.onClose();
  }
}
