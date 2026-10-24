import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:etman/controllers/chatbot_controller.dart';
import 'package:etman/controllers/etman_main_wrapper_controller.dart';
import 'package:etman/screens/etman/etman_doctor_booking_screen.dart';

class EtmanChatBotScreen extends StatelessWidget {
  const EtmanChatBotScreen({Key? key}) : super(key: key);

  static const _teal = Color(0xFF135B51);
  static const _lightTeal = Color(0xFF1E8C78);

  bool _isRTL(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  @override
  Widget build(BuildContext context) {
    final chatController = Get.isRegistered<ChatbotController>()
        ? Get.find<ChatbotController>()
        : Get.put(ChatbotController());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE5F6F3), Color(0xFFF8FAFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──────────────────────────────────────────────────
              _buildAppBar(),

              // ── Quick Suggestions ─────────────────────────────────────
              _buildSuggestions(chatController),

              // ── Messages ──────────────────────────────────────────────
              Expanded(
                child: Obx(() => ListView.builder(
                  controller: chatController.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: chatController.messages.length,
                  itemBuilder: (_, i) =>
                      _buildItem(chatController.messages[i], context),
                )),
              ),

              // ── Typing Indicator ───────────────────────────────────────
              Obx(() => chatController.isProcessing
                  ? _buildTypingIndicator()
                  : const SizedBox.shrink()),

              // ── Input Bar ─────────────────────────────────────────────
              _buildInputBar(chatController),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () =>
                Get.find<EtmanMainWrapperController>().changeIndex(0),
            child: _circleBtn(Icons.arrow_back),
          ),
          Column(
            children: const [
              Text('مساعدك الطبي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
              Text('متاح دائماً لمساعدتك', style: TextStyle(fontSize: 11, color: Colors.black45)),
            ],
          ),
          _circleBtn(Icons.refresh_rounded,
              onTap: () => Get.find<ChatbotController>().reset()),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }

  // ── Quick Suggestions ─────────────────────────────────────────────────────
  Widget _buildSuggestions(ChatbotController ctrl) {
    final chips = [
      '🤒 عندي صداع',
      '❤️ ألم في القلب',
      '👁 مشكلة في عيوني',
      '🦴 آلام في المفاصل',
      '🔬 أريد تحاليل',
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => ctrl.addSuggestion(chips[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _teal.withOpacity(0.4)),
            ),
            child: Text(chips[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _teal)),
          ),
        ),
      ),
    );
  }

  // ── Build each list item: bubble or cards ────────────────────────────────
  Widget _buildItem(Message msg, BuildContext context) {
    // If there are doctor/lab cards, show them as a horizontal list
    if (msg.cards != null && msg.cards!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          height: msg.cards!.first['type'] == 'doctor' ? 190 : 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: msg.cards!.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final card = msg.cards![i];
              return card['type'] == 'doctor'
                  ? _doctorCard(card)
                  : _labCard(card);
            },
          ),
        ),
      );
    }

    // Normal text bubble
    if (msg.text.isEmpty) return const SizedBox.shrink();
    return _buildBubble(msg);
  }

  // ── Text Bubble ───────────────────────────────────────────────────────────
  Widget _buildBubble(Message msg) {
    final isUser = msg.isUserMessage;
    final isRTL = _isRTL(msg.text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _lightTeal.withOpacity(0.4)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
              ),
              child: const Icon(Icons.smart_toy_outlined, color: _teal, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? _teal : Colors.white,
                borderRadius: BorderRadius.circular(20).copyWith(
                  topLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  topRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Directionality(
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                child: Text(
                  msg.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Doctor Card ───────────────────────────────────────────────────────────
  Widget _doctorCard(Map<String, dynamic> d) {
    final name    = d['name']      as String? ?? 'دكتور';
    final spec    = d['specialty'] as String? ?? '';
    final rating  = (d['rating']  as double?) ?? 0.0;
    final price   = d['price'];
    final gov     = d['governorate'] as String? ?? '';
    final photo   = d['photoUrl']  as String?;

    return GestureDetector(
      onTap: () => Get.to(() => EtmanDoctorBookingScreen(doctorData: d)),
      child: Container(
        width: 165,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _lightTeal.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE8F5F3),
                backgroundImage: (photo != null && photo.startsWith('http')) ? NetworkImage(photo) : null,
                child: (photo == null || !photo.startsWith('http'))
                    ? const Icon(Icons.person_rounded, color: _teal, size: 24)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black87), overflow: TextOverflow.ellipsis),
                Text(spec, style: TextStyle(color: Colors.grey[600], fontSize: 10), overflow: TextOverflow.ellipsis),
              ])),
            ]),
            const SizedBox(height: 8),
            if (gov.isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                const SizedBox(width: 2),
                Text(gov, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              const Spacer(),
              if (price != null) Text('${price} ج', style: const TextStyle(fontSize: 10, color: _teal, fontWeight: FontWeight.bold)),
            ]),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.to(() => EtmanDoctorBookingScreen(doctorData: d)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal, foregroundColor: Colors.white,
                  elevation: 0, padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('احجز الآن', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lab Card ──────────────────────────────────────────────────────────────
  Widget _labCard(Map<String, dynamic> d) {
    final name   = d['name']      as String? ?? 'معمل';
    final spec   = d['specialty'] as String? ?? '';
    final rating = (d['rating']  as double?) ?? 4.5;
    final gov    = d['governorate'] as String? ?? '';

    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
              child: const Icon(Icons.science_rounded, color: Colors.blueAccent, size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Text(spec, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          if (gov.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
              const SizedBox(width: 2),
              Text(gov, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ],
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
            const SizedBox(width: 2),
            Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
          ]),
        ],
      ),
    );
  }

  // ── Typing Indicator ──────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, right: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: _lightTeal.withOpacity(0.3)),
            ),
            child: const Icon(Icons.smart_toy_outlined, color: _teal, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
            ),
            child: Row(children: [
              _dot(0), const SizedBox(width: 4),
              _dot(150), const SizedBox(width: 4),
              _dot(300),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return _AnimatedDot(delayMs: delayMs);
  }

  // ── Input Bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar(ChatbotController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: ctrl.messageController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText: 'اكتب أعراضك هنا...',
                  hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                onSubmitted: (_) => ctrl.sendMessage(),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: ctrl.sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated typing dot ────────────────────────────────────────────────────
class _AnimatedDot extends StatefulWidget {
  final int delayMs;
  const _AnimatedDot({required this.delayMs});
  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(color: Color(0xFF135B51), shape: BoxShape.circle),
      ),
    );
  }
}
