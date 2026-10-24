import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/p2p_chat_controller.dart';
import '../../controllers/auth_controller.dart';
import 'etman_colors.dart';

class P2PChatScreen extends StatefulWidget {
  final String roomId;
  final String receiverName;
  final String receiverId;

  const P2PChatScreen({
    Key? key,
    required this.roomId,
    required this.receiverName,
    required this.receiverId,
  }) : super(key: key);

  @override
  State<P2PChatScreen> createState() => _P2PChatScreenState();
}

class _P2PChatScreenState extends State<P2PChatScreen> {
  final P2PChatController _controller = Get.find<P2PChatController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.listenToMessages(widget.roomId);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.receiverName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final messages = _controller.currentMessages;
              if (messages.isEmpty) {
                return const Center(child: Text('ابدأ المحادثة الآن'));
              }
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == _authController.currentUser.value?.uid;
                  return _buildMessageBubble(msg, isMe);
                },
              );
            }),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E8C78) : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(msg.imageUrl!, width: 200, fit: BoxFit.cover),
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image, color: Color(0xFF1E8C78)),
              onPressed: () async {
                final image = await _controller.pickImage(ImageSource.gallery);
                if (image != null) {
                  _controller.sendMessage(
                    roomId: widget.roomId,
                    receiverId: widget.receiverId,
                    text: 'صورة',
                    imageFile: image,
                  );
                }
              },
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF1E8C78)),
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  _controller.sendMessage(
                    roomId: widget.roomId,
                    receiverId: widget.receiverId,
                    text: _textController.text,
                  );
                  _textController.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
