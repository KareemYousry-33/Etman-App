import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';
import 'package:flutter_login/flutter_login.dart';

class AdminController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  
  var isLoading = false.obs;
  var doctors = <UserModel>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // Only fetch when there's a logged-in admin — prevents permission-denied on cold start
    ever(_authController.currentUser, (user) {
      if (user != null && user.role == UserRole.admin) {
        fetchDoctors();
      }
    });
  }
  
  // Fetch all doctors from Firestore
  Future<void> fetchDoctors() async {
    isLoading.value = true;
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['doctor', 'pharmacy', 'nurse', 'lab', 'xray'])
          .get();
      
      doctors.value = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      if (e.toString().contains('permission-denied')) {
        Get.snackbar(
          'تنبيه الحماية',
          'قواعد Firebase تمنع قراءة البيانات. يرجى تعديل Firestore Rules إلى allow read, write: if true;',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
      } else {
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء جلب البيانات: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  // Add a new doctor account
  Future<void> addDoctor({
    required String email,
    required String password,
    required String name,
    required String specialty,
    String? price,
    String? location,
    String? governorate,
    String? city,
    String? bio,
    String? googleMapsLink,
    String? photoUrl,
  }) async {
    if (_authController.currentUser.value?.role != UserRole.admin) {
      Get.snackbar('Permission Denied', 'Only admins can add doctors.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    try {
      await _authController.createDoctorAccount(
        email: email,
        password: password,
        name: name,
        specialty: specialty,
        price: price,
        location: location,
        governorate: governorate,
        city: city,
        bio: bio,
        googleMapsLink: googleMapsLink,
        photoUrl: photoUrl,
      );
      // Save governorate/city to Firestore govs collection if new
      if (governorate != null && governorate.isNotEmpty) {
        await _saveGovCity(governorate, city ?? '');
      }
      
      // Refresh the doctors list
      await fetchDoctors();
      
      Get.snackbar(
        'Success',
        'Doctor added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add doctor: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Add a new nurse account
  Future<void> addNurse({
    required String email,
    required String password,
    required String name,
    required String specialty,
    String? price,
    String? location,
    String? governorate,
    String? city,
    String? bio,
    String? googleMapsLink,
    String? photoUrl,
  }) async {
    if (_authController.currentUser.value?.role != UserRole.admin) {
      Get.snackbar('Permission Denied', 'Only admins can add nurses.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    try {
      await _authController.createNurseAccount(
        email: email,
        password: password,
        name: name,
        specialty: specialty,
        price: price,
        location: location,
        governorate: governorate,
        city: city,
        bio: bio,
        googleMapsLink: googleMapsLink,
        photoUrl: photoUrl,
      );
      if (governorate != null && governorate.isNotEmpty) {
        await _saveGovCity(governorate, city ?? '');
      }
      await fetchDoctors();
      Get.snackbar('Success', 'Nurse added successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add nurse: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Update doctor details
  Future<void> updateDoctorDetails({
    required String doctorId,
    String? name,
    String? specialty,
    String? bio,
    String? price,
    String? location,
    String? governorate,
    String? city,
    String? googleMapsLink,
    String? photoUrl,
  }) async {
    if (_authController.currentUser.value?.role != UserRole.admin) {
      Get.snackbar('Permission Denied', 'Only admins can update doctor details.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    isLoading.value = true;
    try {
      Map<String, dynamic> updateData = {};
      
      if (name != null && name.isNotEmpty) updateData['name'] = name;
      if (specialty != null && specialty.isNotEmpty) updateData['specialty'] = specialty;
      if (bio != null && bio.isNotEmpty) updateData['bio'] = bio;
      if (price != null && price.isNotEmpty) updateData['price'] = price;
      if (location != null && location.isNotEmpty) updateData['location'] = location;
      if (governorate != null && governorate.isNotEmpty) updateData['governorate'] = governorate;
      if (city != null && city.isNotEmpty) updateData['city'] = city;
      if (googleMapsLink != null && googleMapsLink.isNotEmpty) updateData['googleMapsLink'] = googleMapsLink;
      if (photoUrl != null && photoUrl.isNotEmpty) updateData['photoUrl'] = photoUrl;
      
      await _firestore.collection('users').doc(doctorId).update(updateData);
      
      if (governorate != null && governorate.isNotEmpty) {
        await _saveGovCity(governorate, city ?? '');
      }

      // Refresh the doctors list
      await fetchDoctors();
      
      Get.snackbar(
        'Success',
        'Doctor details updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update doctor details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Remove a doctor account
  Future<void> removeDoctor(String doctorId) async {
    if (_authController.currentUser.value?.role != UserRole.admin) {
      Get.snackbar(
        'Permission Denied',
        'Only admins can remove doctors.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    isLoading.value = true;
    try {
      // Delete the doctor from Firestore
      await _firestore.collection('users').doc(doctorId).delete();
      
      // Note: This doesn't delete the Firebase Auth account, only the Firestore record
      // For a complete solution, use Firebase Admin SDK or Cloud Functions
      
      // Refresh the doctors list
      await fetchDoctors();
      
      Get.snackbar(
        'Success',
        'Doctor removed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove doctor: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Add a new pharmacy account
  Future<void> addPharmacy({
    required String email,
    required String password,
    required String name,
    required String specialty,
    String? location,
    String? governorate,
    String? city,
    String? bio,
    String? googleMapsLink,
    String? photoUrl,
  }) async {
    if (_authController.currentUser.value?.role != UserRole.admin) {
      Get.snackbar('Error', 'Only admins can add pharmacies', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    try {
      await _authController.createPharmacyAccount(
        email: email,
        password: password,
        name: name,
        specialty: specialty,
        location: location,
        city: city,
        governorate: governorate,
        bio: bio,
        googleMapsLink: googleMapsLink,
        photoUrl: photoUrl,
      );
      if (governorate != null && governorate.isNotEmpty) {
        await _saveGovCity(governorate, city ?? '');
      }
      Get.snackbar('Success', 'Pharmacy added successfully', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add pharmacy: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Add a new lab account
  Future<void> addLab({
    required String email,
    required String password,
    required String name,
    String? location,
    String? governorate,
    String? city,
    String? bio,
    String? googleMapsLink,
    String? photoUrl,
  }) async {
    if (_authController.currentUser.value?.role != UserRole.admin) {
      Get.snackbar('Error', 'Only admins can add labs', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    try {
      await _authController.createLabAccount(
        email: email,
        password: password,
        name: name,
        location: location,
        city: city,
        governorate: governorate,
        bio: bio,
        googleMapsLink: googleMapsLink,
        photoUrl: photoUrl,
      );
      if (governorate != null && governorate.isNotEmpty) {
        await _saveGovCity(governorate, city ?? '');
      }
      Get.snackbar('Success', 'Lab added successfully', backgroundColor: Colors.green, colorText: Colors.white);
      await fetchDoctors();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add lab: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Add a new xray center account
  Future<void> addXray({
    required String email,
    required String password,
    required String name,
    String? specialty,
    String? location,
    String? governorate,
    String? city,
    String? bio,
    String? googleMapsLink,
    String? photoUrl,
  }) async {
    if (_authController.currentUser.value?.role != UserRole.admin) {
      Get.snackbar('Error', 'Only admins can add xray centers', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    try {
      await _authController.createXrayAccount(
        email: email,
        password: password,
        name: name,
        specialty: specialty,
        location: location,
        city: city,
        governorate: governorate,
        bio: bio,
        googleMapsLink: googleMapsLink,
        photoUrl: photoUrl,
      );
      if (governorate != null && governorate.isNotEmpty) {
        await _saveGovCity(governorate, city ?? '');
      }
      Get.snackbar('Success', 'Xray center added successfully', backgroundColor: Colors.green, colorText: Colors.white);
      await fetchDoctors();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add xray center: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> seedDemoData() async {
    final List<Map<String, dynamic>> demoUsers = [
      // Admin
      {'email': 'admin@etman.com', 'password': 'admin123', 'name': 'المشرف العام', 'role': UserRole.admin},
      // Demo Patients
      {'email': 'kareemyousry78@gmail.com', 'password': 'patient123', 'name': 'كريم يسري (Patient)', 'role': UserRole.patient},
      {'email': 'patient@etman.com', 'password': 'patient123', 'name': 'مريض تجريبي', 'role': UserRole.patient},
      // Doctors
      {'email': 'karim@etman.com', 'password': 'doctor123', 'name': 'د. كريم يسري', 'role': UserRole.doctor, 'specialty': 'طب أطفال'},
      {'email': 'ahmed@etman.com', 'password': 'doctor123', 'name': 'د. أحمد إبراهيم', 'role': UserRole.doctor, 'specialty': 'قلب وأوعية دموية'},
      {'email': 'nour@etman.com', 'password': 'doctor123', 'name': 'د. نور حسن', 'role': UserRole.doctor, 'specialty': 'أمراض جلدية'},
      {'email': 'khaled@etman.com', 'password': 'doctor123', 'name': 'د. خالد محمود', 'role': UserRole.doctor, 'specialty': 'مخ وأعصاب'},
      {'email': 'fatma@etman.com', 'password': 'doctor123', 'name': 'د. فاطمة علي', 'role': UserRole.doctor, 'specialty': 'طب أطفال (ج)'},
      {'email': 'omar@etman.com', 'password': 'doctor123', 'name': 'د. عمر خالد', 'role': UserRole.doctor, 'specialty': 'عظام'},
      {'email': 'sara@etman.com', 'password': 'doctor123', 'name': 'د. سارة محمد', 'role': UserRole.doctor, 'specialty': 'نساء وتوليد'},
      // Pharmacy
      {'email': 'pharmacy@etman.com', 'password': 'pharmacy123', 'name': 'صيدلية إطمئن', 'role': UserRole.pharmacy, 'specialty': 'Pharmacy'},
      // Nurse
      {'email': 'nurse@etman.com', 'password': 'nurse123', 'name': 'علي محمد', 'role': UserRole.nurse, 'specialty': 'رعاية مسنين'},
      // Lab
      {'email': 'lab@etman.com', 'password': 'lab123', 'name': 'معمل حساب التجريبي', 'role': UserRole.lab},
    ];

    isLoading.value = true;
    int successCount = 0;
    
    try {
      for (var user in demoUsers) {
        try {
          if (user['role'] == UserRole.admin) {
            await _authController.createAdminAccount(email: user['email'], password: user['password'], name: user['name'], isSystemSeed: true);
          } else if (user['role'] == UserRole.doctor) {
            await _authController.createDoctorAccount(email: user['email'], password: user['password'], name: user['name'], specialty: user['specialty'], isSystemSeed: true);
          } else if (user['role'] == UserRole.patient) {
             await _authController.signupUser(SignupData.fromSignupForm(
              name: user['email'], 
              password: user['password'],
              additionalSignupData: {'role': 'patient', 'name': user['name']}
            ));
          } else if (user['role'] == UserRole.pharmacy) {
            await _authController.createPharmacyAccount(email: user['email'], password: user['password'], name: user['name'], specialty: user['specialty'], isSystemSeed: true);
          } else if (user['role'] == UserRole.nurse) {
            await _authController.createNurseAccount(email: user['email'], password: user['password'], name: user['name'], specialty: user['specialty'], price: '150', isSystemSeed: true);
          } else if (user['role'] == UserRole.lab) {
            await _authController.createLabAccount(email: user['email'], password: user['password'], name: user['name'], isSystemSeed: true);
          }
          
          // CRITICAL: Sign out after each creation to ensure the next iteration starts fresh
          await _authController.logoutSeederOnly(); 
          successCount++;
        } catch (e) {
          if (e.toString().contains('already-in-use')) { 
            // Force update role for existing accounts
            final query = await _firestore.collection('users').where('email', isEqualTo: user['email']).get();
            if (query.docs.isNotEmpty) {
              await _firestore.collection('users').doc(query.docs.first.id).update({
                'role': user['role'].toString().split('.').last,
                'name': user['name'],
                if (user.containsKey('specialty')) 'specialty': user['specialty'],
              });
            }
            successCount++;
            continue;
          }
          print('Error seeding ${user['email']}: $e');
        }
      }

      // After user accounts are ready, seed some appointments
      await _seedDemoAppointments();

      await fetchDoctors();
      
      Get.snackbar('Seeding Complete', 'Populated $successCount accounts and sample appointments.', backgroundColor: Colors.blueAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Seeding failed: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Helper to populate the dashboards with data
  Future<void> _seedDemoAppointments() async {
    try {
      final patientQuery = await _firestore.collection('users').where('email', isEqualTo: 'patient@etman.com').get();
      if (patientQuery.docs.isEmpty) return;
      final patientId = patientQuery.docs.first.id;
      final patientName = patientQuery.docs.first.get('name');

      final doctorQuery = await _firestore.collection('users').where('role', isEqualTo: 'doctor').get();
      
      for (var doc in doctorQuery.docs) {
        final existing = await _firestore.collection('appointments').where('doctorId', isEqualTo: doc.id).limit(1).get();
        if (existing.docs.isEmpty) {
          final List<String> slots = ['10:00 AM', '02:00 PM', '05:00 PM'];
          for (int i = 0; i < 2; i++) {
            await _firestore.collection('appointments').add({
              'doctorId': doc.id,
              'doctorName': doc.get('name'),
              'doctorSpecialty': doc.get('specialty'),
              'patientId': patientId,
              'patientName': patientName,
              'date': Timestamp.fromDate(DateTime.now().add(Duration(days: i))),
              'timeSlot': slots[i],
              'status': i == 0 ? 'pending' : 'approved',
              'createdAt': FieldValue.serverTimestamp(),
              'doctorImage': 'assets/doctor_m1.png',
            });
          }
        }
      }
    } catch (e) {
      print('Seeding appointments error: $e');
    }
  }
  // Save governorate & city to the 'governorates' Firestore collection
  Future<void> _saveGovCity(String gov, String city) async {
    try {
      final ref = _firestore.collection('governorates').doc(gov);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({'name': gov, 'cities': city.isEmpty ? [] : [city]});
      } else if (city.isNotEmpty) {
        final cities = List<String>.from(snap.data()?['cities'] ?? []);
        if (!cities.contains(city)) {
          cities.add(city);
          await ref.update({'cities': cities});
        }
      }
    } catch (_) {}
  }
}
