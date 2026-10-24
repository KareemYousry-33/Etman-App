import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:etman/controllers/patient_controller.dart';
import 'package:etman/controllers/auth_controller.dart';
import 'package:etman/controllers/p2p_chat_controller.dart';
import 'package:etman/models/user_model.dart';
import 'package:etman/screens/etman/p2p_chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etman/controllers/etman_main_wrapper_controller.dart' as etman_main_wrapper_controller;
class EtmanDoctorBookingScreen extends StatefulWidget {
  final dynamic doctorData;
  const EtmanDoctorBookingScreen({Key? key, this.doctorData}) : super(key: key);

  @override
  State<EtmanDoctorBookingScreen> createState() => _EtmanDoctorBookingScreenState();
}

class _EtmanDoctorBookingScreenState extends State<EtmanDoctorBookingScreen> {
  late final PatientController patientController;
  late final AuthController authController;

  late String doctorUid;
  late String doctorName;
  late String doctorImage;
  late String doctorSpecialty;
  late double doctorRating;
  late double doctorPrice;
  late List<String> doctorAvailability;
  late String providerRole;
  String? doctorGoogleMapsLink;  // Google Maps link

  // Star (favorite) state — white initially, yellow when tapped
  bool _isStarred = false;

  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  final TextEditingController notesController = TextEditingController();

  static const List<String> _arabicDays   = ['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت'];
  static const List<String> _arabicMonths = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

  final List<String> _fallbackSlots = [
    'الأحد : 10:00 صباحاً - 6:00 مساءً',
    'الاثنين : 10:00 صباحاً - 4:00 مساءً',
    'الثلاثاء : 9:00 صباحاً - 5:00 مساءً',
    'الأربعاء : 11:00 صباحاً - 7:00 مساءً',
    'الخميس : 9:00 صباحاً - 3:00 مساءً',
  ];

  @override
  void initState() {
    super.initState();
    authController    = Get.find<AuthController>();
    patientController = Get.isRegistered<PatientController>()
        ? Get.find<PatientController>()
        : Get.put(PatientController());
    _parseDoctorData();
  }

  void _parseDoctorData() {
    final data = widget.doctorData ?? Get.arguments;
    if (data is UserModel) {
      doctorUid          = data.uid;
      doctorName         = data.name;
      doctorImage        = data.photoUrl ?? 'assets/doctor.png';
      doctorSpecialty    = _translateSpecialty(data.specialty ?? 'طبيب عام');
      doctorRating       = data.rating ?? 4.9;
      doctorPrice        = data.price ?? 200.0;
      doctorAvailability = (data.availability != null && data.availability!.isNotEmpty)
          ? data.availability! : _fallbackSlots;
      providerRole       = data.role.name;
      doctorGoogleMapsLink = data.googleMapsLink;
    } else if (data is Map) {
      doctorUid          = data['uid'] ?? data['id'] ?? '';
      doctorName         = data['name'] ?? 'دكتور';
      doctorImage        = data['imageUrl'] ?? data['image'] ?? data['photoUrl'] ?? 'assets/doctor.png';
      doctorSpecialty    = _translateSpecialty(data['specialty'] ?? 'طبيب عام');
      doctorRating       = (data['rating']  is num) ? (data['rating']  as num).toDouble() : 4.9;
      doctorPrice        = (data['price']   is num) ? (data['price']   as num).toDouble() : 200.0;
      final av = data['availability'];
      doctorAvailability = (av is List && av.isNotEmpty) ? List<String>.from(av) : _fallbackSlots;
      providerRole       = data['role'] ?? 'doctor';
      doctorGoogleMapsLink = data['googleMapsLink'];
    } else {
      doctorUid = ''; doctorName = 'الخدمة'; doctorImage = 'assets/doctor.png';
      doctorSpecialty = 'عام'; doctorRating = 4.9; doctorPrice = 200.0;
      doctorAvailability = _fallbackSlots;
      providerRole = 'doctor';
    }
  }

  String _translateSpecialty(String s) {
    const m = {
      'Neurologist':'مخ وأعصاب','Cardiologist':'قلب وأوعية',
      'Pulmonologist':'صدر وحساسية','Orthopedist':'عظام ومفاصل',
      'Dermatologist':'جلدية','Pediatrician':'أطفال',
      'Psychiatrist':'نفسية','Ophthalmologist':'رمد',
      'ENT':'أنف وأذن وحنجرة','Gynecologist':'نساء وتوليد',
      'cardiology':'قلب وأوعية','neurology':'مخ وأعصاب',
      'dermatology':'جلدية','pediatrics':'أطفال',
      'psychiatry':'نفسية','orthopedics':'عظام ومفاصل',
    };
    return m[s] ?? s;
  }

  @override
  void dispose() { notesController.dispose(); super.dispose(); }

  Widget _sectionTitle(String t) =>
      Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black54));

  @override
  Widget build(BuildContext context) {
    // Guard: non-patients
    if (authController.currentUser.value?.role != UserRole.patient) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFCBEAEA), elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_forward, color: Colors.black87), onPressed: () => Get.back()),
            title: const Text('حجز موعد', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_outline, size: 70, color: Colors.grey),
                const SizedBox(height: 20),
                const Text('يجب تسجيل الدخول كمريض لحجز المواعيد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8C78), foregroundColor: Colors.white),
                  child: const Text('العودة'),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    // ─── Main screen ────────────────────────────────────────────────────────────
    return Directionality(
      textDirection: TextDirection.rtl,   // ✅ RTL
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(top: 55, right: 10, left: 10, bottom: 20),
              decoration: const BoxDecoration(color: Color(0xFFCBEAEA)),
              child: Row(
                children: [
                   // ✅ iOS style back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 4),
                  Text(providerRole == 'nurse' ? 'حجز تمريض' : (providerRole == 'lab' ? 'حجز معمل' : 'حجز موعد'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                  const Spacer(),
                  // ✅ Doctor Chat Button
                  GestureDetector(
                    onTap: _startChat,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFF135B51), shape: BoxShape.circle),
                      child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Obx(() => patientController.isLoading.value
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E8C78)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDoctorCard(),
                        const SizedBox(height: 28),
                        _sectionTitle('اختر التاريخ'),
                        const SizedBox(height: 14),
                        _buildDateSelector(),
                        const SizedBox(height: 28),
                        _sectionTitle('المواعيد المتاحة'),
                        const SizedBox(height: 14),
                        _buildTimeSlots(),
                        const SizedBox(height: 28),
                        _sectionTitle(providerRole == 'nurse' ? 'ملاحظات للممرض/ة (اختياري)' : 'ملاحظات للدكتور (اختياري)'),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            controller: notesController,
                            maxLines: 4,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            decoration: InputDecoration(
                              hintText: providerRole == 'nurse' ? 'أضف أي ملاحظات للممرض/ة...' : 'أضف أي ملاحظات للدكتور...',
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: selectedTimeSlot == null ? null : _bookAppointment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF135B51),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            child: Text(
                              selectedTimeSlot == null ? 'اختر موعداً أولاً' : 'تأكيد الحجز',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9B8E), Color(0xFF6DCBBE)],
          begin: Alignment.centerRight, end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          // Image (right side in RTL)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 38,
              backgroundImage: doctorImage.startsWith('http')
                  ? NetworkImage(doctorImage) as ImageProvider
                  : AssetImage(doctorImage),
              onBackgroundImageError: (_, __) => null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctorName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(doctorSpecialty,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // ⭐ Interactive Rating Dialog
                    GestureDetector(
                      onTap: _showRatingDialog,
                      child: Icon(
                        _isStarred ? Icons.star : Icons.star_border,
                        color: _isStarred ? Colors.amber : Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(doctorRating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 16),
                    const Icon(Icons.payments_outlined, color: Colors.white70, size: 18),
                    const SizedBox(width: 4),
                    Text('${doctorPrice.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                // Google Maps button (shown only if link exists)
                if (doctorGoogleMapsLink != null && doctorGoogleMapsLink!.isNotEmpty) ...[  
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(doctorGoogleMapsLink!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        Get.snackbar('خطأ', 'تعذر فتح الخريطة',
                            backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white54),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: Colors.white, size: 16),
                          SizedBox(width: 5),
                          Text('عرض على الخريطة',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Parses start hour from an Arabic slot string.
  /// e.g. "الاثنين : 10:00 صباحاً - 4:00 مساءً" → 10 (AM) → 10
  ///        "الأحد : 10:00 صباحاً - 6:00 مساءً"  → 10 (AM) → 10
  ///        "الأربعاء : 11:00 صباحاً - 7:00 مساءً"  → 11 (AM) → 11
  ///        "الخميس : 9:00 صباحاً - 3:00 مساءً"   → 9 (AM)  → 9
  /// Supports formats like "9:00 AM", "4:00 PM", "10:00 صباحاً", "4:00 مساءً"
  int? _parseSlotHour(String slot) {
    // Extract the START time — everything after the last colon-section before '-'
    // Pattern: anything - HH:MM (AM/PM | صباحاً/مساءً) '-' ...
    final timeRegex = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM|صباحاً|مساءً)');
    final matches = timeRegex.allMatches(slot).toList();
    if (matches.isEmpty) return null;

    final m = matches.first; // first occurrence = start time
    int hour = int.parse(m.group(1)!);
    final period = m.group(3)!;

    if (period == 'PM' || period == 'مساءً') {
      if (hour != 12) hour += 12;
    } else if (period == 'AM' || period == 'صباحاً') {
      if (hour == 12) hour = 0;
    }
    return hour;
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: false,
        itemCount: 14,
        itemBuilder: (context, index) {
          // index 0 = today
          final date = DateTime.now().add(Duration(days: index));
          final isSel = DateUtils.isSameDay(selectedDate, date);
          final isToday = index == 0;
          return GestureDetector(
            onTap: () => setState(() { selectedDate = date; selectedTimeSlot = null; }),
            child: Container(
              width: 63,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF135B51) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isSel ? const Color(0xFF135B51) : Colors.grey[300]!),
                boxShadow: isSel
                    ? [BoxShadow(color: const Color(0xFF135B51).withOpacity(0.3), blurRadius: 8)]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isToday)
                    Text('اليوم',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w900,
                          color: isSel ? Colors.white70 : const Color(0xFF1E8C78),
                        ))
                  else
                    Text('${date.day}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                            color: isSel ? Colors.white : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(_arabicDays[date.weekday % 7],
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: isSel ? Colors.white70 : Colors.grey)),
                  if (isToday && !isSel)
                    Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E8C78), shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(selectedDate, now);

    // Filter past slots only when the selected date is today
    List<String> available = [];
    int hiddenCount = 0;

    for (final slot in doctorAvailability) {
      if (isToday) {
        final slotHour = _parseSlotHour(slot);
        if (slotHour != null && slotHour <= now.hour) {
          hiddenCount++;
          continue; // skip past/current slot
        }
      }
      available.add(slot);
    }

    if (available.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.schedule_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              isToday
                  ? 'انتهت جميع مواعيد اليوم\nيرجى اختيار يوم آخر'
                  : 'لا توجد مواعيد متاحة لهذا اليوم',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isToday && hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'تم إخفاء $hiddenCount موعد منتهي الوقت',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ...available.map((slot) {
          final isSel = selectedTimeSlot == slot;
          return GestureDetector(
            onTap: () => setState(() => selectedTimeSlot = slot),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF135B51) : const Color(0xFFCBEAEA),
                borderRadius: BorderRadius.circular(30),
                border: isSel ? null : Border.all(color: const Color(0xFF135B51).withOpacity(0.2)),
              ),
              child: Text(slot,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSel ? Colors.white : const Color(0xFF135B51),
                  fontWeight: FontWeight.w900, fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _startChat() async {
    try {
      final p2p = Get.isRegistered<P2PChatController>()
          ? Get.find<P2PChatController>()
          : Get.put(P2PChatController());

      final roomId = await p2p.getOrCreateChatRoom(
        receiverId: doctorUid,
        type: 'doctor', // Custom type for doctor chat
      );

      Get.to(() => P2PChatScreen(
        roomId: roomId,
        receiverName: doctorName,
        receiverId: doctorUid,
      ));
    } catch (e) {
      Get.snackbar('خطأ', 'فشل فتح المحادثة: $e');
    }
  }

  Future<void> _bookAppointment() async {
    final user = authController.currentUser.value;
    if (user != null) {
      if ((user.phoneNumber == null || user.phoneNumber!.isEmpty) ||
          (user.age == null) ||
          (user.governorate == null || user.governorate!.isEmpty)) {
        Get.dialog(
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF4E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'تنبيه هام',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF135B51)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'يرجى استكمال بيانات ملفك الشخصي قبل التمكن من الحجز',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135B51),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('حسناً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }
    }

    try {
      await patientController.bookAppointment(
        doctorId: doctorUid, doctorName: doctorName, doctorImage: doctorImage,
        appointmentDate: selectedDate, timeSlot: selectedTimeSlot!,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        providerRole: providerRole,
      );
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle, color: Color(0xFF1E8C78), size: 70),
            const SizedBox(height: 16),
            const Text('تم الحجز بنجاح!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'تم إرسال طلب حجزك مع $doctorName\nبتاريخ ${selectedDate.day} ${_arabicMonths[selectedDate.month - 1]}\nالوقت: $selectedTimeSlot',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.6),
            ),
            const SizedBox(height: 20),
            Text(providerRole == 'nurse' ? 'سيتم إشعارك عند موافقة التمريض' : 'سيتم إشعارك عند موافقة الدكتور',
                style: const TextStyle(color: Color(0xFF1E8C78), fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          actions: [
            TextButton(
              onPressed: () { Get.back(); Get.back(); },
              child: const Text('حسناً',
                  style: TextStyle(color: Color(0xFF1E8C78), fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('خطأ في الحجز', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showRatingDialog() {
    double currentRating = 5.0; // Default selected rating
    Get.dialog(
      StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF6F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.amber, size: 48),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    providerRole == 'nurse' ? 'تقييم التمريض' : 'تقييم الدكتور',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF135B51)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    providerRole == 'nurse' ? 'ما هو تقييمك لخدمة هذا الممرض؟' : 'ما هو تقييمك لخدمة هذا الدكتور؟',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            currentRating = index + 1.0;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          transform: Matrix4.identity()..scale(index < currentRating ? 1.1 : 1.0),
                          child: Icon(
                            index < currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Get.back();
                            await _submitRating(currentRating);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF135B51),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('تأكيد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitRating(double rating) async {
    final user = authController.currentUser.value;
    if (user == null || user.role != UserRole.patient) {
      Get.snackbar('تنبيه', 'يجب تسجيل الدخول كمريض لتقييم الدكتور');
      return;
    }
    
    Get.dialog(const Center(child: CircularProgressIndicator(color: Color(0xFF135B51))), barrierDismissible: false);
    try {
      final db = FirebaseFirestore.instance;
      // 1. Save rating under ratings collection
      await db.collection('ratings').doc('${user.uid}_$doctorUid').set({
        'patientId': user.uid,
        'doctorId': doctorUid,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // We only mark the star as filled, without changing the doctor's displayed average rating
      setState(() {
        _isStarred = true; // Mark as rated visually
      });
      Get.back(); // close loading
      Get.snackbar('نجاح', 'تم حفظ تقييمك بنجاح', backgroundColor: const Color(0xFF135B51), colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar('خطأ', 'فشل حفظ التقييم: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}

