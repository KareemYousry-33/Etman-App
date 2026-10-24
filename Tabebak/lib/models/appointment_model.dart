import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { pending, approved, completed, cancelled }

class AppointmentModel {
  final String? id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String? patientImage;
  final String doctorName;
  final String doctorSpecialty;
  final String doctorImage;
  final DateTime date;
  final String timeSlot;
  final String? notes;
  final AppointmentStatus status;
  final DateTime? createdAt;
  final String providerRole;

  AppointmentModel({
    this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    this.patientImage,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.doctorImage,
    required this.date,
    required this.timeSlot,
    this.notes,
    this.status = AppointmentStatus.pending,
    this.createdAt,
    this.providerRole = 'doctor',
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      patientImage: data['patientImage'],
      doctorName: data['doctorName'] ?? '',
      doctorSpecialty: data['doctorSpecialty'] ?? '',
      doctorImage: data['doctorImage'] ?? 'assets/doctor_m1.png',
      date: (data['date'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] ?? '',
      notes: data['notes'],
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      providerRole: data['providerRole'] ?? 'doctor',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'patientImage': patientImage,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'doctorImage': doctorImage,
      'date': Timestamp.fromDate(date),
      'timeSlot': timeSlot,
      'notes': notes,
      'status': status.toString().split('.').last,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'providerRole': providerRole,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    String? patientName,
    String? doctorName,
    String? doctorSpecialty,
    String? doctorImage,
    DateTime? date,
    String? timeSlot,
    String? notes,
    AppointmentStatus? status,
    DateTime? createdAt,
    String? providerRole,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      doctorImage: doctorImage ?? this.doctorImage,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      providerRole: providerRole ?? this.providerRole,
    );
  }
}
