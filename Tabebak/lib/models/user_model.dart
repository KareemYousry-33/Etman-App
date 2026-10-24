import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, doctor, patient, pharmacy, nurse, lab, xray }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final String? phoneNumber;
  final String? specialty;
  final String? bio;
  final double? rating;
  final List<String>? availability;
  final String? medicalHistory;
  final String? address;
  final String? location;        // clinic / pharmacy address text
  final int? age;
  final double? price;
  final String? city;
  final String? governorate;
  final String? googleMapsLink;
  
  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
    this.phoneNumber,
    this.specialty,
    this.bio,
    this.rating,
    this.availability,
    this.medicalHistory,
    this.address,
    this.location,
    this.age,
    this.price,
    this.city,
    this.governorate,
    this.googleMapsLink,
  });
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Helper for safe double conversion
    double? toDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.patient
      ),
      photoUrl: data['photoUrl'] ?? data['imageUrl'] ?? data['image'],
      phoneNumber: data['phoneNumber'],
      specialty: data['specialty'],
      bio: data['bio'],
      rating: toDouble(data['rating']),
      availability: data['availability'] != null 
          ? List<String>.from(data['availability']) 
          : null,
      medicalHistory: data['medicalHistory'],
      address: data['address'],
      location: data['location'],
      age: data['age'],
      price: toDouble(data['price']),
      city: data['city'],
      governorate: data['governorate'],
      googleMapsLink: data['googleMapsLink'],
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'city': city,
      'governorate': governorate,
      'googleMapsLink': googleMapsLink,
      if (role == UserRole.doctor || role == UserRole.pharmacy || role == UserRole.nurse || role == UserRole.lab || role == UserRole.xray) ...{
        'specialty': specialty,
        'bio': bio,
        'rating': rating,
        'availability': availability,
        'price': price,
        'location': location,
      },
      if (role == UserRole.patient) ...{
        'medicalHistory': medicalHistory,
        'address': address,
        'age': age,
      },
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    String? photoUrl,
    String? phoneNumber,
    String? specialty,
    String? bio,
    double? rating,
    List<String>? availability,
    double? price,
    String? medicalHistory,
    String? address,
    String? location,
    int? age,
    String? city,
    String? governorate,
    String? googleMapsLink,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      specialty: specialty ?? this.specialty,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      availability: availability ?? this.availability,
      price: price ?? this.price,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      address: address ?? this.address,
      location: location ?? this.location,
      age: age ?? this.age,
      city: city ?? this.city,
      governorate: governorate ?? this.governorate,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
    );
  }
}
