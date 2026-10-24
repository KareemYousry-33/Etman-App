import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String? facebookUrl;
  final String? imageUrl;
  final String? governorate;
  final String? city;
  final double rating;
  final String bio;
  final String? specialty;
  double? distanceInMeters; // Mutable to allow runtime calculation
  
  PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.facebookUrl,
    this.imageUrl,
    this.governorate,
    this.city,
    this.rating = 0.0,
    this.bio = '',
    this.specialty,
  });
  
  factory PharmacyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PharmacyModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      phoneNumber: data['phoneNumber'],
      facebookUrl: data['facebookUrl'],
      imageUrl: data['photoUrl'] ?? data['imageUrl'],
      governorate: data['governorate'],
      city: data['city'],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      bio: data['bio'] ?? '',
      specialty: data['specialty'],
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'facebookUrl': facebookUrl,
      'imageUrl': imageUrl,
      'governorate': governorate,
      'city': city,
      'rating': rating,
      'bio': bio,
    };
  }

  // Helper dedicated to handling images (Assets vs Network vs Fallback)
  Widget getImageWidget({double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Image.asset('assets/pharmacy_category.png', width: width, height: height, fit: fit);
    }
    
    if (imageUrl!.startsWith('assets/')) {
      return Image.asset(imageUrl!, width: width, height: height, fit: fit);
    }
    
    return Image.network(
      imageUrl!, 
      width: width, height: height, fit: fit,
      errorBuilder: (context, error, stackTrace) => Image.asset('assets/pharmacy_category.png', width: width, height: height, fit: fit),
    );
  }
}
