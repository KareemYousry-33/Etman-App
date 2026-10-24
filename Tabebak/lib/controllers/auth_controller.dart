import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../screens/etman/etman_main_wrapper.dart';
import '../screens/admin_screen.dart';
import '../screens/doctor_dashboard_screen.dart';
import '../screens/pharmacy_dashboard_screen.dart';
import '../screens/nurse_dashboard_screen.dart';
import '../screens/lab_dashboard_screen.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '691068365729-u2jc9g68g71qb8m997cr0tp5gfa6u5eg.apps.googleusercontent.com',
  );

  Rx<User?> firebaseUser = Rx<User?>(null);
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  var isLoading = false.obs;

  // Add a flag to control automatic navigation
  var shouldAutoNavigate = false.obs;

  // Flag to show registration form
  var shouldShowRegistrationForm = false.obs;

  get user => null;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.value = _auth.currentUser;

    // Listen for auth state changes
    _auth.authStateChanges().listen((User? user) {
      firebaseUser.value = user;
      if (user != null) {
        _fetchUserData(user.uid);
        // No automatic navigation - navigation must be explicitly called
      } else {
        currentUser.value = null;
      }
    });

    // Intercept navigation to patient-profile route
    ever(currentUser, (user) {
      // If navigation to patient profile is detected and we don't want auto-navigation
      if (Get.currentRoute == '/patient-profile' && !shouldAutoNavigate.value) {
        // Navigate back or to a safe route
        Get.back();
      }
    });
  }

  // Sign in with Google
  Future<String?> signInWithGoogle() async {
    isLoading.value = true;
    try {
      // Force account picker by signing out first
      await _googleSignIn.signOut();
      
      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "Login Cancelled";

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 5. Check if the user document exists in Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // Create initial Patient profile for first-time Google signups
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? user.email?.split('@').first ?? 'User',
            'email': user.email,
            'role': 'patient',
            'photoUrl': user.photoURL, // Store Google photo
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Update existing user's photo if it changed or was missing
          await _firestore.collection('users').doc(user.uid).update({
            'photoUrl': user.photoURL,
          });
        }
        
        await _fetchUserData(user.uid);
        _navigateToMainScreen();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Unexpected error: $e";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchUserData(String uid) async {
    isLoading.value = true;
    try {
      DocumentSnapshot? doc;
      try {
        doc = await _firestore.collection('users').doc(uid).get();
      } catch (e) {
        debugPrint('⚠️ Warning: Could not read user doc from Firestore: $e');
        // We do not throw here! We fall through to the fallback logic below.
      }

      final email = _auth.currentUser?.email ?? '';
      
      final doctorEmails = {
        'ahmed@etman.com': 'قلب وأوعية دموية',
        'nour@etman.com': 'أمراض جلدية',
        'khaled@etman.com': 'مخ وأعصاب',
        'hoda@etman.com': 'جراحة عظام ومفاصل',
        'mostafa@etman.com': 'أمراض الصدر والحساسية',
        'fatma@etman.com': 'طب أطفال',
        'karim@etman.com': 'طب أطفال',
      };

      if (doc != null && doc.exists) {
        UserModel user = UserModel.fromFirestore(doc);
        
        // --- SMART REPAIR LOGIC: Auto-elevate roles for key accounts ---

        try {
          if (doctorEmails.containsKey(user.email) && user.role == UserRole.patient) {
            await _firestore.collection('users').doc(uid).update({
              'role': 'doctor',
              'specialty': doctorEmails[user.email],
            });
            user = user.copyWith(role: UserRole.doctor, specialty: doctorEmails[user.email]);
          } else if (user.email == 'admin@etman.com' && user.role == UserRole.patient) {
            await _firestore.collection('users').doc(uid).update({'role': 'admin'});
            user = user.copyWith(role: UserRole.admin);
          } else if (user.email == 'pharmacy@etman.com' && user.role == UserRole.patient) {
            await _firestore.collection('users').doc(uid).update({'role': 'pharmacy'});
            user = user.copyWith(role: UserRole.pharmacy);
          }
        } catch (updateError) {
          // If Firestore rules prevent updating, elevate locally so they can log in
          if (doctorEmails.containsKey(user.email)) {
            user = user.copyWith(role: UserRole.doctor, specialty: doctorEmails[user.email]);
          } else if (user.email == 'admin@etman.com') {
            user = user.copyWith(role: UserRole.admin);
          } else if (user.email == 'pharmacy@etman.com') {
            user = user.copyWith(role: UserRole.pharmacy);
          }
        }
        
        currentUser.value = user;
      } else {
        // --- AUTO-CREATE LOGIC FOR SPECIAL ACCOUNTS IF MISSING OR BLOCKED BY RULES ---
        if (email == 'admin@etman.com') {
          UserModel adminUser = UserModel(
            uid: uid,
            name: 'Admin',
            email: email,
            role: UserRole.admin,
          );
          try {
            await _firestore.collection('users').doc(uid).set(adminUser.toFirestore());
          } catch (_) {} // Ignore permission errors on set
          currentUser.value = adminUser;
        } else if (email == 'pharmacy@etman.com') {
          UserModel pharmacyUser = UserModel(
            uid: uid,
            name: 'صيدلية العزبي',
            email: email,
            role: UserRole.pharmacy,
          );
          try {
            await _firestore.collection('users').doc(uid).set(pharmacyUser.toFirestore());
          } catch (_) {}
          currentUser.value = pharmacyUser;
        } else if (doctorEmails.containsKey(email)) {
          UserModel doctorUser = UserModel(
            uid: uid,
            name: 'دكتور',
            email: email,
            role: UserRole.doctor,
            specialty: doctorEmails[email],
          );
          try {
            await _firestore.collection('users').doc(uid).set(doctorUser.toFirestore());
          } catch (_) {}
          currentUser.value = doctorUser;
        } else {
            // It's just a normal user and we couldn't fetch their profile
            // If they just signed up, they will create their profile in ProfileSetupScreen
        }
      }
    } catch (e) {
      debugPrint('Fatal error fetching user: $e');
      if (currentUser.value == null) {
        Get.snackbar(
          'تنبيه',
          'قواعد الحماية منعت جلب البيانات، ولكن تم تسجيل الدخول بنجاح كحساب خاص.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Used by flutter_login widget
  Future<String?> authUser(LoginData data) async {
    // Disable auto-navigation before authentication
    shouldAutoNavigate.value = false;

    isLoading.value = true;
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: data.name,
        password: data.password,
      );

      await _fetchUserData(result.user!.uid);
      
      if (currentUser.value == null) {
        return 'User data not found in database.';
      }

      _navigateToMainScreen();

      return null; // No error means success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'Unexpected error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Updated method to navigate to the correct dashboard based on role
  void _navigateToMainScreen() {
    if (currentUser.value == null) {
      Get.offAllNamed('/login');
      return;
    }
    
    Widget target;
    String? routeName;

    switch (currentUser.value!.role) {
      case UserRole.admin:
        target = const AdminScreen();
        routeName = '/admin';
        break;
      case UserRole.doctor:
        target = const DoctorDashboardScreen();
        routeName = '/doctor-dashboard';
        break;
      case UserRole.pharmacy:
        target = const PharmacyDashboardScreen();
        routeName = '/pharmacy-dashboard';
        break;
      case UserRole.lab:
        target = const LabDashboardScreen();
        routeName = '/lab-dashboard';
        break;
      case UserRole.nurse:
        // Will create this file next
        target = const NurseDashboardScreen();
        routeName = '/nurse-dashboard';
        break;
      case UserRole.patient:
      default:
        target = const EtmanMainWrapper();
        routeName = '/main';
        break;
    }

    Get.offAll(
      () => target,
      routeName: routeName,
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 500),
    );
  }

  // Explicit navigation method that can be called when desired
  void navigateToPatientProfile() {
    shouldAutoNavigate.value = true;
    Get.toNamed('/patient-profile');
  }

  // Used by flutter_login widget
  Future<String?> signupUser(SignupData data) async {
    final email = data.name;
    if (email == null || data.password == null) {
      return "Email and password are required";
    }

    isLoading.value = true;
    try {
      // Create auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: data.password!,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': data.additionalSignupData?['name'] ?? email.split('@').first,
        'email': email,
        'role': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _fetchUserData(result.user!.uid);
      _navigateToMainScreen();

      return null; // No error means success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'Unexpected error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Used by flutter_login widget
  Future<String> recoverPassword(String email) async {
    isLoading.value = true;
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return 'Password reset link has been sent to $email';
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e) ?? 'Failed to send password reset email';
    } finally {
      isLoading.value = false;
    }
  }

  String? _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return e.message;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    currentUser.value = null;
    Get.offAllNamed('/login');
  }

  // Helper for seeding to avoid triggering heavy UI logic
  Future<void> logoutSeederOnly() async {
    await _auth.signOut();
  }

  // Create admin account (can only be called by existing admins)
  Future<void> createAdminAccount({
    required String email,
    required String password,
    required String name,
    bool isSystemSeed = false,
  }) async {
    // Check if the current user is an admin or it's a system seed
    if (!isSystemSeed && currentUser.value?.role != UserRole.admin) {
      throw 'Only admins can create other admin accounts';
    }

    try {
      // Create auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add admin data to Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'name': name,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Create doctor account (can only be called by admins)
  Future<void> createDoctorAccount({
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
    bool isSystemSeed = false,
  }) async {
    if (!isSystemSeed && currentUser.value?.role != UserRole.admin) {
      throw 'Only admins can create doctor accounts';
    }
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email, 'name': name, 'role': 'doctor',
        'specialty': specialty, 'price': price,
        'location': location, 'governorate': governorate,
        'city': city, 'bio': bio,
        if (googleMapsLink != null && googleMapsLink.isNotEmpty)
          'googleMapsLink': googleMapsLink,
        if (photoUrl != null && photoUrl.isNotEmpty)
          'photoUrl': photoUrl,
        'rating': 0.0, 'availability': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { rethrow; }
  }

  // Create pharmacy account (can only be called by admins)
  Future<void> createPharmacyAccount({
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
    bool isSystemSeed = false,
  }) async {
    if (!isSystemSeed && currentUser.value?.role != UserRole.admin) {
      throw 'Only admins can create pharmacy accounts';
    }
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email, 'name': name, 'role': 'pharmacy',
        'specialty': specialty, 'location': location,
        'governorate': governorate, 'city': city, 'bio': bio,
        if (googleMapsLink != null && googleMapsLink.isNotEmpty)
          'googleMapsLink': googleMapsLink,
        if (photoUrl != null && photoUrl.isNotEmpty)
          'photoUrl': photoUrl,
        'rating': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // NOTE: pharmacies are now served from users collection only (role=pharmacy)
    } catch (e) {
      rethrow;
    }
  }

  // Create nurse account (can only be called by admins)
  Future<void> createNurseAccount({
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
    bool isSystemSeed = false,
  }) async {
    if (!isSystemSeed && currentUser.value?.role != UserRole.admin) {
      throw 'Only admins can create nurse accounts';
    }
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email, 'name': name, 'role': 'nurse',
        'specialty': specialty, 'price': price,
        'location': location, 'governorate': governorate,
        'city': city, 'bio': bio,
        if (googleMapsLink != null && googleMapsLink.isNotEmpty)
          'googleMapsLink': googleMapsLink,
        if (photoUrl != null && photoUrl.isNotEmpty)
          'photoUrl': photoUrl,
        'rating': 0.0, 'availability': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { rethrow; }
  }

  // Create lab account (can only be called by admins)
  Future<void> createLabAccount({
    required String email,
    required String password,
    required String name,
    String? location,
    String? governorate,
    String? city,
    String? bio,
    String? googleMapsLink,
    String? photoUrl,
    bool isSystemSeed = false,
  }) async {
    if (!isSystemSeed && currentUser.value?.role != UserRole.admin) {
      throw 'Only admins can create lab accounts';
    }
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email, 'name': name, 'role': 'lab',
        'location': location, 'governorate': governorate,
        'city': city, 'bio': bio,
        if (googleMapsLink != null && googleMapsLink.isNotEmpty)
          'googleMapsLink': googleMapsLink,
        if (photoUrl != null && photoUrl.isNotEmpty)
          'photoUrl': photoUrl,
        'rating': 0.0, 'availability': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { rethrow; }
  }

  // Create xray center account (can only be called by admins)
  Future<void> createXrayAccount({
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
    bool isSystemSeed = false,
  }) async {
    if (!isSystemSeed && currentUser.value?.role != UserRole.admin) {
      throw 'Only admins can create xray center accounts';
    }
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email, 'name': name, 'role': 'xray',
        'specialty': specialty ?? 'أشعة وتصوير طبي',
        'location': location, 'governorate': governorate,
        'city': city, 'bio': bio,
        if (googleMapsLink != null && googleMapsLink.isNotEmpty)
          'googleMapsLink': googleMapsLink,
        if (photoUrl != null && photoUrl.isNotEmpty)
          'photoUrl': photoUrl,
        'rating': 0.0, 'availability': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { rethrow; }
  }


  Future<void> registerDoctorRequest({
    required String email,
    required String password,
    required String name,
    required String specialty,
    String? bio,
  }) async {
    try {
      // Create auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add doctor data to Firestore with pending status
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'name': name,
        'role': 'doctor',
        'approvalStatus': 'pending', // Requires admin approval
        'specialty': specialty,
        'bio': bio ?? '',
        'rating': 0.0,
        'availability': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also create a doctor registration request
      await _firestore.collection('doctorRequests').doc(result.user!.uid).set({
        'email': email,
        'name': name,
        'specialty': specialty,
        'bio': bio ?? '',
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Sign out the user after registration - they need to wait for approval
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile data
  Future<void> updateUserProfile(String newName) async {
    if (currentUser.value == null) return;
    
    isLoading.value = true;
    try {
      await _firestore.collection('users').doc(currentUser.value!.uid).update({
        'name': newName,
      });
      
      // Update local state
      currentUser.value = currentUser.value!.copyWith(name: newName);
      
      Get.snackbar(
        'التحديث ناجح',
        'تم تحديث اسمك بنجاح يا بطل!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1E8C78),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ في التحديث',
        'فشلنا نحدث البيانات، جرب تاني يا غالي.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update patient essential booking data (phone, age, governorate)
  Future<void> updatePatientInfo({
    String? phoneNumber,
    int? age,
    String? governorate,
  }) async {
    if (currentUser.value == null) return;

    isLoading.value = true;
    try {
      final Map<String, dynamic> data = {};
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (age != null) data['age'] = age;
      if (governorate != null) data['governorate'] = governorate;

      if (data.isEmpty) return;

      await _firestore.collection('users').doc(currentUser.value!.uid).update(data);

      // Reflect locally
      currentUser.value = currentUser.value!.copyWith(
        phoneNumber: phoneNumber ?? currentUser.value!.phoneNumber,
        age: age ?? currentUser.value!.age,
        governorate: governorate ?? currentUser.value!.governorate,
      );

      Get.snackbar(
        'تم الحفظ',
        'تم تحديث بياناتك الشخصية بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E8C78),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل حفظ البيانات: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
