import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../controllers/pharmacy_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'etman/p2p_chat_screen.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final pharmacyController = Get.find<PharmacyController>();
  final authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (authController.currentUser.value?.uid != null) {
      pharmacyController.listenToIncomingChats(authController.currentUser.value!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (authController.currentUser.value?.role != UserRole.pharmacy) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person, size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                const Text('عذراً، هذه المنطقة مخصصة للصيدليات فقط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                  'مرحباً،',
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                                Text(
                                  authController.currentUser.value?.name ?? 'صيدلية إطمئن',
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
                          final totalOrders = pharmacyController.orders.length;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickStat('$totalOrders', 'إجمالي الطلبات (الروشتات)'),
                              _buildQuickStat('0', 'طلبات مكتملة'),
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
                tabs: const [
                  Tab(text: 'الروشتات والدردشة'),
                  Tab(text: 'الإعلانات والعروض'),
                  Tab(text: 'بيانات الصيدلية'),
                ],
              ),
            ),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOrdersTab(),
            _buildAdsTab(),
            _buildSettingsTab(),
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

  Widget _buildOrdersTab() {
    return Obx(() {
      if (pharmacyController.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF1E8C78)));
      }
      
      final displayOrders = pharmacyController.orders;
      
      if (displayOrders.isEmpty) {
        return const Center(child: Text('لا توجد طلبات روشتات حالياً'));
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayOrders.length,
        itemBuilder: (context, index) {
          final order = displayOrders[index];
          return _buildOrderCard(order);
        },
      );
    });
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF1E8C78).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF1E8C78)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['patientName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${order['type'] ?? 'طلب دواء'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF1E8C78).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Text('نشط', style: TextStyle(color: Color(0xFF1E8C78), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => P2PChatScreen(
                      roomId: order['id'], 
                      receiverName: order['patientName'], 
                      receiverId: order['receiverId']
                    )),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.white),
                    label: const Text('عرض الروشتة', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8C78),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Get.to(() => P2PChatScreen(
                      roomId: order['id'], 
                      receiverName: order['patientName'], 
                      receiverId: order['receiverId']
                    )),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF1E8C78)),
                    label: const Text('تواصل', style: TextStyle(color: Color(0xFF1E8C78))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E8C78)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAdsTab() {
    return Obx(() {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: () => _showAddAdDialog(),
            icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
            label: const Text('إضافة إعلان أو عرض جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E8C78),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 20),
          if (pharmacyController.adsAndOffers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign_outlined, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    const Text('لا توجد عروض أو إعلانات نشطة حالياً', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ...pharmacyController.adsAndOffers.map((ad) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF1E8C78).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.local_offer_outlined, color: Color(0xFF1E8C78)),
                ),
                title: Text(ad['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(ad['desc'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => pharmacyController.deleteOffer(ad['id']),
                ),
              ),
            )).toList(),
        ],
      );
    });
  }

  void _showAddAdDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إعلان جديد', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'عنوان العرض (مثال: خصم 20% على... )',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'تفاصيل العرض...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  pharmacyController.addOffer(titleController.text, descController.text);
                  Get.back();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51)),
              child: const Text('نشر العرض', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 10),
        // Profile Picture Section
        Center(
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F3),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E8C78), width: 2),
                ),
                child: const Icon(Icons.local_pharmacy_rounded, size: 50, color: Color(0xFF1E8C78)),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Get.snackbar('تحديث الصورة', 'تم فتح إعدادت الكاميرا/المعرض لتغيير صورتك', backgroundColor: const Color(0xFF135B51), colorText: Colors.white),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFF135B51), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: InkWell(
            onTap: () => Get.snackbar('تحديث الصورة', 'تم فتح إعدادت الكاميرا/المعرض لتغيير صورتك', backgroundColor: const Color(0xFF135B51), colorText: Colors.white),
            child: const Text('تغيير الصورة الشخصية', style: TextStyle(color: Color(0xFF135B51), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 40),
        
        // Working Hours Section
        const Text('تخصيص مواعيد العمل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        Obx(() => ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          tileColor: Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1E8C78).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.access_time_filled, color: Color(0xFF1E8C78)),
          ),
          title: const Text('ساعات العمل اليومية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(pharmacyController.workingHours.value, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
          onTap: () => _showEditWorkingHoursDialog(),
        )),
        const SizedBox(height: 12),
        Obx(() => ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          tileColor: Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1E8C78).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1E8C78)),
          ),
          title: const Text('أيام العمل والإجازات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(pharmacyController.workingDays.value, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
          onTap: () => _showEditWorkingHoursDialog(),
        )),
      ],
    );
  }

  void _showEditWorkingHoursDialog() {
    final hoursController = TextEditingController(text: pharmacyController.workingHours.value);
    final daysController = TextEditingController(text: pharmacyController.workingDays.value);
    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('مواعيد العمل', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hoursController,
                decoration: InputDecoration(
                  labelText: 'ساعات العمل (مثال: من 9ص لـ 11م)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: daysController,
                decoration: InputDecoration(
                  labelText: 'أيام الإجازات (مثال: الجمعة إجازة)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                pharmacyController.updateWorkingInfo(hoursController.text, daysController.text);
                Get.back();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51)),
              child: const Text('تحديث', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
