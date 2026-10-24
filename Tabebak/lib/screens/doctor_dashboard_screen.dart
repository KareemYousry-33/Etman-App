import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/doctor_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final doctorController = Get.find<DoctorController>();
  final authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    if (authController.currentUser.value?.role != UserRole.doctor) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text('عذراً، ليس لديك صلاحية دخول الأطباء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => authController.logout(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8C78)),
                child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF135B51),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF135B51), Color(0xFF1E8C78)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'أهلاً بك يا دكتور،',
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                                Text(
                                  authController.currentUser.value?.name ?? 'دكتور',
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => authController.logout(),
                              icon: const Icon(Icons.logout_rounded, color: Colors.white),
                            )
                          ],
                        ),
                        const Spacer(),
                        Obx(() {
                          final todayAppts = doctorController.appointments.where((a) => a.date.day == DateTime.now().day && a.date.month == DateTime.now().month && a.date.year == DateTime.now().year).length;
                          final pendingRequests = doctorController.appointments.where((a) => a.status == AppointmentStatus.pending).length;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickStat('$todayAppts', 'مريض اليوم'),
                              _buildQuickStat('$pendingRequests', 'طلبات انتظار'),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF135B51),
                labelColor: const Color(0xFF135B51),
                unselectedLabelColor: Colors.grey,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.calendar_today_outlined, size: 20), text: 'الطلبات'),
                  Tab(icon: Icon(Icons.people_outline, size: 20), text: 'مرضاي'),
                  Tab(icon: Icon(Icons.chat_bubble_outline, size: 20), text: 'شات'),
                  Tab(icon: Icon(Icons.access_time_outlined, size: 20), text: 'ساعات العمل'),
                  Tab(icon: Icon(Icons.person_outline, size: 20), text: 'الصفحة'),
                ],
              ),
            ),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAppointmentsTab(),
            _buildPatientsTab(),
            _buildChatTab(),
            _buildAvailabilityTab(),
            _buildProfileTab(),
          ],
        ),
      ),
    ));
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildAppointmentsTab() {
    return Obx(() {
      if (doctorController.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF1E8C78)));
      }
      
      if (doctorController.appointments.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 10),
              const Text('لا توجد مواعيد حالية', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: doctorController.appointments.length,
        itemBuilder: (context, index) {
          final appointment = doctorController.appointments[index];
          return _buildAppointmentCard(appointment);
        },
      );
    });
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final statusColor = _getStatusColor(appointment.status);
    final statusText = _getStatusText(appointment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                appointment.patientImage != null 
                  ? CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(appointment.patientImage!),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                      child: Icon(Icons.person_outline, color: statusColor),
                    ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${DateFormat('MMM d').format(appointment.date)} - ${appointment.timeSlot}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          if (appointment.notes != null && appointment.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFB), border: Border.symmetric(horizontal: BorderSide(color: Colors.grey[200]!))),
              child: Text(
                appointment.notes!,
                style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
              ),
            ),
          if (appointment.status == AppointmentStatus.pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => doctorController.updateAppointmentStatus(appointment.id!, AppointmentStatus.approved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E8C78),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('قبول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => doctorController.updateAppointmentStatus(appointment.id!, AppointmentStatus.cancelled),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('رفض', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تحديد مواعيد العمل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('اختر الفترات المتاحة لك لاستقبال الحجوزات', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),
          Expanded(
            child: Obx(() => ListView(
              children: [
                _buildTimeSection('الصباح', ['8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM']),
                _buildTimeSection('بعد الظهر', ['12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM']),
                _buildTimeSection('المساء', ['4:00 PM', '5:00 PM', '6:00 PM', '7:00 PM']),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(String title, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: slots.map((slot) {
            final isSelected = doctorController.availableTimeSlots.contains(slot);
            return FilterChip(
              label: Text(slot),
              selected: isSelected,
              onSelected: (selected) {
                var current = List<String>.from(doctorController.availableTimeSlots);
                if (selected) {
                  current.add(slot);
                } else {
                  current.remove(slot);
                }
                doctorController.updateAvailability(current);
              },
              selectedColor: const Color(0xFFC9E4E1),
              checkmarkColor: const Color(0xFF1E8C78),
              labelStyle: TextStyle(color: isSelected ? const Color(0xFF1E8C78) : Colors.black87),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Patients Tab ───────────────────────────────────────────────────────────
  Widget _buildPatientsTab() {
    return Obx(() {
      final patients = doctorController.appointments
          .where((a) => a.status != AppointmentStatus.cancelled)
          .map((a) => a.patientName)
          .toSet()
          .toList();
      if (patients.isEmpty) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text('لا يوجد مرضى حتى الآن', style: TextStyle(color: Colors.grey)),
        ]));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: patients.length,
        itemBuilder: (_, i) => Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFFE8F5F3), child: Text(patients[i][0], style: const TextStyle(color: Color(0xFF1E8C78), fontWeight: FontWeight.bold))),
            title: Text(patients[i], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('مريض مسجل', style: TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: const Icon(Icons.chevron_left, color: Colors.grey),
          ),
        ),
      );
    });
  }

  // ── Chat Tab ───────────────────────────────────────────────────────────────
  Widget _buildChatTab() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
      const SizedBox(height: 12),
      const Text('لا توجد محادثات حالياً', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 16),
      const Text('ستظهر محادثاتك مع المرضى هنا', style: TextStyle(color: Colors.grey, fontSize: 13)),
    ]));
  }

  // ── Profile Tab ──────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    final user = authController.currentUser.value;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        // ── Profile Photo
        Center(child: Stack(children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F3), shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E8C78), width: 2),
              image: (user?.photoUrl != null && user!.photoUrl!.startsWith('http'))
                  ? DecorationImage(image: NetworkImage(user.photoUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: (user?.photoUrl == null || !user!.photoUrl!.startsWith('http'))
                ? const Icon(Icons.person_rounded, size: 50, color: Color(0xFF1E8C78))
                : null,
          ),
          Positioned(bottom: 0, right: 0, child: GestureDetector(
            onTap: () => Get.snackbar('تحديث الصورة', 'تم فتح الكاميرا لتغيير صورتك', backgroundColor: const Color(0xFF135B51), colorText: Colors.white),
            child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF135B51), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 18, color: Colors.white)),
          )),
        ])),
        const SizedBox(height: 8),
        Center(child: Text(user?.name ?? 'دكتور', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Center(child: Text(user?.specialty ?? 'طبيب عام', style: const TextStyle(color: Colors.grey))),
        const SizedBox(height: 30),
        // ── Options
        _profileOption(Icons.badge_outlined, 'تغيير الاسم', () => _showEditDialog('تغيير الاسم', 'الاسم الجديد', user?.name ?? '', field: 'name')),
        _profileOption(Icons.attach_money_outlined, 'تغيير سعر الكشف', () => _showEditDialog('سعر الكشف', 'السعر بالجنيه (مثال: 300)', user?.price?.toString() ?? '', field: 'price', isNumeric: true)),
        _profileOption(Icons.cake_outlined, 'تغيير السن', () => _showEditDialog('تغيير السن', 'السن (مثال: 35)', user?.age?.toString() ?? '', field: 'age', isNumeric: true)),
        _profileOption(Icons.location_on_outlined, 'تغيير موقع العيادة', () => _showEditDialog('موقع العيادة', 'مثال: القاهرة - مدينة نصر', user?.location ?? '', field: 'location')),
        _profileOption(Icons.info_outline, 'تعديل البايو', () => _showEditDialog('البايو', 'نبذة عنك...', user?.bio ?? '', field: 'bio', multiLine: true)),
        _profileOption(Icons.logout_rounded, 'تسجيل الخروج', () => authController.logout(), color: Colors.redAccent),
      ],
    );
  }

  Widget _profileOption(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (color ?? const Color(0xFF1E8C78)).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color ?? const Color(0xFF1E8C78), size: 22)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        trailing: const Icon(Icons.chevron_left, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showEditDialog(
    String title,
    String hint,
    String initial, {
    bool obscure = false,
    bool isNumeric = false,
    bool multiLine = false,
    String? field,               // Firestore field key
  }) {
    final ctrl = TextEditingController(text: initial);
    final isSaving = false.obs;

    Get.dialog(Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          obscureText: obscure,
          maxLines: multiLine ? 4 : 1,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          Obx(() => ElevatedButton(
            onPressed: isSaving.value ? null : () async {
              final val = ctrl.text.trim();
              if (val.isEmpty) return;
              isSaving.value = true;
              try {
                final uid = authController.currentUser.value?.uid;
                if (uid == null) return;

                if (field != null) {
                  dynamic saveVal = val;
                  if (isNumeric) saveVal = int.tryParse(val) ?? double.tryParse(val) ?? val;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({field: saveVal});

                  // Refresh local user
                  authController.currentUser.value = authController.currentUser.value?.copyWith(
                    name:     field == 'name'     ? val  : authController.currentUser.value?.name,
                    location: field == 'location' ? val  : authController.currentUser.value?.location,
                    bio:      field == 'bio'      ? val  : authController.currentUser.value?.bio,
                    age:      field == 'age'      ? int.tryParse(val)    : authController.currentUser.value?.age,
                    price:    field == 'price'    ? double.tryParse(val) : authController.currentUser.value?.price,
                  );
                }

                Get.back();
                Get.snackbar(
                  '✅ تم الحفظ',
                  'تم تحديث $title بنجاح',
                  backgroundColor: const Color(0xFF135B51),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar('خطأ', 'فشل الحفظ: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
              } finally {
                isSaving.value = false;
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51)),
            child: isSaving.value
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('حفظ', style: TextStyle(color: Colors.white)),
          )),
        ],
      ),
    ));
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:   return Colors.orange;
      case AppointmentStatus.approved:  return const Color(0xFF1E8C78);
      case AppointmentStatus.completed: return Colors.blue;
      case AppointmentStatus.cancelled: return Colors.redAccent;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:   return 'قيد الانتظار';
      case AppointmentStatus.approved:  return 'مقبول';
      case AppointmentStatus.completed: return 'مكتمل';
      case AppointmentStatus.cancelled: return 'ملغي';
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
