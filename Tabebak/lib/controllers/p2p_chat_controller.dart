import 'dart:io';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';
import 'auth_controller.dart';

class P2PChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthController _authController = Get.find<AuthController>();

  var currentMessages = <ChatMessageModel>[].obs;
  var isLoading = false.obs;

  // Send a message to a room
  Future<void> sendMessage({
    required String roomId,
    required String receiverId,
    required String text,
    File? imageFile,
    String? type,
  }) async {
    final senderId = _authController.currentUser.value?.uid;
    if (senderId == null) return;

    try {
      String? imageUrl;
      if (imageFile != null) {
        final ref = _storage.ref().child('chat_images').child(DateTime.now().toString());
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final message = ChatMessageModel(
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      // Add message to Firestore
      await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .add(message.toFirestore());

      // Update last message in room
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'lastMessage': imageFile != null ? 'صورة برسالة' : text,
        'lastMessageTime': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending message: $e');
      Get.snackbar('Error', 'Failed to send message');
    }
  }

  // Create or get a chat room
  Future<String> getOrCreateChatRoom({
    required String receiverId,
    required String type, // 'pharmacy', 'admin'
    String? pharmacyId,
  }) async {
    final senderId = _authController.currentUser.value?.uid;
    if (senderId == null) throw Exception('User not logged in');

    final participants = [senderId, receiverId]..sort();
    
    // Check if room exists
    final query = await _firestore
        .collection('chat_rooms')
        .where('participants', isEqualTo: participants)
        .where('type', isEqualTo: type)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    // Create new room
    final docRef = await _firestore.collection('chat_rooms').add({
      'participants': participants,
      'lastMessage': 'بداية المحادثة',
      'lastMessageTime': Timestamp.now(),
      'type': type,
      'pharmacyId': pharmacyId,
      'createdAt': Timestamp.now(),
    });

    return docRef.id;
  }

  // Listen for messages in a room
  void listenToMessages(String roomId) {
    _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      currentMessages.value = snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList();
    });
  }

  // Pick an image from gallery/camera
  Future<File?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}
