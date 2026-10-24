import 'dart:io';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medical_record_model.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';

class MedicalRecordController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthController _authController = Get.find<AuthController>();

  var currentRecord = Rx<MedicalRecordModel?>(null);
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch record whenever user changes
    ever(_authController.currentUser, (user) {
      if (user != null && user.role == UserRole.patient) {
        fetchMedicalRecord(user.uid);
      }
    });
    
    // Initial fetch if already logged in
    final user = _authController.currentUser.value;
    if (user != null && user.role == UserRole.patient) {
      fetchMedicalRecord(user.uid);
    }
  }

  Future<void> fetchMedicalRecord(String uid) async {
    isLoading.value = true;
    try {
      final doc = await _firestore.collection('medical_records').doc(uid).get();
      if (doc.exists) {
        currentRecord.value = MedicalRecordModel.fromFirestore(doc);
      } else {
        // Create initial empty record
        currentRecord.value = MedicalRecordModel(uid: uid);
      }
    } catch (e) {
      print('Error fetching medical record: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveMedicalRecord(MedicalRecordModel record) async {
    isLoading.value = true;
    try {
      await _firestore
          .collection('medical_records')
          .doc(record.uid)
          .set(record.toFirestore(), SetOptions(merge: true));
      currentRecord.value = record;
      Get.snackbar('نجاح', 'تم حفظ بياناتك الطبية بنجاح');
    } catch (e) {
      print('Error saving medical record: $e');
      Get.snackbar('خطأ', 'فشل في حفظ البيانات');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateField({
    String? bloodType,
    double? height,
    double? weight,
    String? phoneNumber,
    List<ChronicDisease>? chronicDiseases,
    List<Medication>? currentMedications,
    List<Allergy>? allergies,
    List<Surgery>? surgeries,
    Lifestyle? lifestyle,
    CurrentSymptoms? currentSymptoms,
    List<TestResult>? testResults,
  }) async {
    final uid = _authController.currentUser.value?.uid;
    if (uid == null) return;

    final updated = MedicalRecordModel(
      uid: uid,
      bloodType: bloodType ?? currentRecord.value?.bloodType,
      height: height ?? currentRecord.value?.height,
      weight: weight ?? currentRecord.value?.weight,
      phoneNumber: phoneNumber ?? currentRecord.value?.phoneNumber,
      chronicDiseases: chronicDiseases ?? currentRecord.value?.chronicDiseases,
      currentMedications: currentMedications ?? currentRecord.value?.currentMedications,
      allergies: allergies ?? currentRecord.value?.allergies,
      surgeries: surgeries ?? currentRecord.value?.surgeries,
      lifestyle: lifestyle ?? currentRecord.value?.lifestyle,
      currentSymptoms: currentSymptoms ?? currentRecord.value?.currentSymptoms,
      testResults: testResults ?? currentRecord.value?.testResults,
      prescriptions: currentRecord.value?.prescriptions,
    );
    
    await saveMedicalRecord(updated);
  }

  Future<void> uploadTestResult(String testName, File imageFile) async {
    final uid = _authController.currentUser.value?.uid;
    if (uid == null) return;

    isLoading.value = true;
    try {
      final ref = _storage.ref().child('test_results/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();

      final newResult = TestResult(testName: testName, date: DateTime.now(), resultImageUrl: url);
      final updatedResults = List<TestResult>.from(currentRecord.value?.testResults ?? [])..add(newResult);
      
      await updateField(testResults: updatedResults);
    } catch (e) {
      print('Error uploading test result: $e');
      Get.snackbar('خطأ', 'فشل رفع نتيجة التحليل');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadPrescription(File imageFile) async {
    final uid = _authController.currentUser.value?.uid;
    if (uid == null) return;

    isLoading.value = true;
    try {
      final ref = _storage.ref().child('prescriptions/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();

      final updatedPrescriptions = List<String>.from(currentRecord.value?.prescriptions ?? [])..add(url);
      
      await _firestore.collection('medical_records').doc(uid).set({
        'prescriptions': updatedPrescriptions,
      }, SetOptions(merge: true));

      // Update local state without full reload
      fetchMedicalRecord(uid);
      
      Get.snackbar('نجاح', 'تم رفع الروشتة بنجاح');
    } catch (e) {
      print('Error uploading prescription: $e');
      Get.snackbar('خطأ', 'فشل رفع الصورة');
    } finally {
      isLoading.value = false;
    }
  }

  Future<File?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}
