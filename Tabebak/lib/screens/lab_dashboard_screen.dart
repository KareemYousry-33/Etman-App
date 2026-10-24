import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/lab_controller.dart';
import '../models/user_model.dart';
import 'etman/p2p_chat_screen.dart';

class LabDashboardScreen extends StatefulWidget {
  const LabDashboardScreen({Key? key}) : super(key: key);

  @override
  State<LabDashboardScreen> createState() => _LabDashboardScreenState();
}

class _LabDashboardScreenState extends State<LabDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final authController = Get.find<AuthController>();
  final labController = Get.put(LabController());

  // Local state for working hours
  final _workingHours = 'من 8 صباحاً لـ 10 مساءً'.obs;
  final _workingDays  = 'السبت → الخميس (الجمعة إجازة)'.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (authController.currentUser.value?.role != UserRole.lab) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person, size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                const Text('عذراً، هذه المنطقة مخصصة للمعامل فقط',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => authController.logout(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51)),
                  child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            // ── Header ──────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 210,
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('مرحباً،',
                                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                                  Text(
                                    authController.currentUser.value?.name ?? 'معمل إطمئن',
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Icon(Icons.science_rounded, color: Colors.white70, size: 40),
                            ],
                          ),
                          const Spacer(),
                          Obx(() => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _quickStat('${labController.requests.length}', 'إجمالي الطلبات'),
                              _quickStat('0', 'طلبات مكتملة'),
                            ],
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── Tab Bar ──────────────────────────────────────────────────────
            SliverPersistentHeader(
              delegate: _SliverDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF135B51),
                  labelColor: const Color(0xFF135B51),
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'الطلبات'),
                    Tab(text: 'الإعلانات'),
                    Tab(text: 'بيانات المعمل'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _requestsTab(),
              _adsTab(),
              _settingsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickStat(String val, String label) => Column(children: [
    Text(val, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
  ]);

  // ── Requests Tab ────────────────────────────────────────────────────────────
  Widget _requestsTab() {
    return Obx(() {
      if (labController.requests.isEmpty) {
        return const Center(child: Text('لا توجد طلبات حالياً'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: labController.requests.length,
        itemBuilder: (_, i) => _requestCard(labController.requests[i]),
      );
    });
  }

  Widget _requestCard(Map<String, dynamic> req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E8C78).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.science_outlined, color: Color(0xFF1E8C78)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(req['patientName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${req['type'] ?? 'طلب تحليل'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF1E8C78).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Text('نشط', style: TextStyle(color: Color(0xFF1E8C78), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => P2PChatScreen(
                  roomId: req['id'], receiverName: req['patientName'], receiverId: req['receiverId'])),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.white),
                label: const Text('عرض الطلب', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8C78), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Get.to(() => P2PChatScreen(
                  roomId: req['id'], receiverName: req['patientName'], receiverId: req['receiverId'])),
                icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF1E8C78)),
                label: const Text('تواصل', style: TextStyle(color: Color(0xFF1E8C78))),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1E8C78)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Ads Tab ─────────────────────────────────────────────────────────────────
  Widget _adsTab() {
    return Obx(() => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: _showAddAdDialog,
          icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
          label: const Text('إضافة إعلان أو عرض جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8C78), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        ),
        const SizedBox(height: 20),
        if (labController.ads.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(children: [
              Icon(Icons.campaign_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 10),
              const Text('لا توجد إعلانات نشطة', style: TextStyle(color: Colors.grey)),
            ]),
          ))
        else
          ...labController.ads.map((ad) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF1E8C78).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.local_offer_outlined, color: Color(0xFF1E8C78))),
              title: Text(ad['content'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => labController.deleteAd(ad['id']),
              ),
            ),
          )).toList(),
      ],
    ));
  }

  void _showAddAdDialog() {
    final contentCtrl = TextEditingController();
    Get.dialog(Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إعلان جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: contentCtrl, maxLines: 3, decoration: InputDecoration(hintText: 'تفاصيل العرض...', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
        ]),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          Obx(() => ElevatedButton(
            onPressed: labController.isSaving.value ? null : () async { 
              if (contentCtrl.text.isNotEmpty) { 
                await labController.addAd(contentCtrl.text); 
                Get.back(); 
              } 
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51)),
            child: labController.isSaving.value 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('نشر العرض', style: TextStyle(color: Colors.white)),
          )),
        ],
      ),
    ));
  }

  // ── Settings Tab ─────────────────────────────────────────────────────────────
  Widget _settingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 10),
        Center(child: Stack(children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: const Color(0xFFE8F5F3), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1E8C78), width: 2)),
            child: const Icon(Icons.science_rounded, size: 50, color: Color(0xFF1E8C78)),
          ),
          Positioned(bottom: 0, right: 0, child: GestureDetector(
            onTap: () => Get.snackbar('تحديث الصورة', 'تم فتح الكاميرا لتغيير الصورة', backgroundColor: const Color(0xFF135B51), colorText: Colors.white),
            child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF135B51), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 18, color: Colors.white)),
          )),
        ])),
        const SizedBox(height: 10),
        Center(child: InkWell(
          onTap: () => Get.snackbar('تحديث الصورة', 'تم فتح الكاميرا لتغيير الصورة', backgroundColor: const Color(0xFF135B51), colorText: Colors.white),
          child: const Text('تغيير الصورة', style: TextStyle(color: Color(0xFF135B51), fontWeight: FontWeight.bold)),
        )),
        const SizedBox(height: 30),
        const Text('مواعيد العمل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Obx(() => _settingsTile(Icons.access_time_filled, 'ساعات العمل اليومية', _workingHours.value, () => _showEditHoursDialog())),
        const SizedBox(height: 12),
        Obx(() => _settingsTile(Icons.calendar_month_rounded, 'أيام العمل والإجازات', _workingDays.value, () => _showEditHoursDialog())),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      tileColor: Colors.white,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF1E8C78).withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF1E8C78))),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
      onTap: onTap,
    );
  }

  void _showEditHoursDialog() {
    final hoursCtrl = TextEditingController(text: _workingHours.value);
    final daysCtrl  = TextEditingController(text: _workingDays.value);
    Get.dialog(Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('مواعيد العمل', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: hoursCtrl, decoration: InputDecoration(labelText: 'ساعات العمل', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
          const SizedBox(height: 10),
          TextField(controller: daysCtrl, decoration: InputDecoration(labelText: 'أيام الإجازات', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
        ]),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              _workingHours.value = hoursCtrl.text;
              _workingDays.value = daysCtrl.text;
              labController.updateLabDetails(workingHours: hoursCtrl.text, workingDays: daysCtrl.text);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51)),
            child: const Text('تحديث', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ));
  }
}

class _SliverDelegate extends SliverPersistentHeaderDelegate {
  _SliverDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Colors.white, child: _tabBar);
  @override bool shouldRebuild(_SliverDelegate _) => false;
}
