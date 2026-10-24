import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String type; // 'pharmacy', 'admin', 'doctor'
  final String? pharmacyId;
  final String? doctorId;

  ChatRoomModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.type,
    this.pharmacyId,
    this.doctorId,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      type: data['type'] ?? 'pharmacy',
      pharmacyId: data['pharmacyId'],
      doctorId: data['doctorId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'type': type,
      'pharmacyId': pharmacyId,
      'doctorId': doctorId,
    };
  }
}
