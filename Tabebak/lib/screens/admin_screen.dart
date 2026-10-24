import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/banner_controller.dart';
import '../controllers/notification_controller.dart';
import '../models/user_model.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();
    final authController = Get.find<AuthController>();
    
    if (authController.currentUser.value?.role != UserRole.admin) {
      return _buildAccessDenied(authController);
    }

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        appBar: AppBar(
          title: const Text('لوحة التحكم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF135B51),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => authController.logout(),
          ),
          actions: [
            IconButton(
              tooltip: 'إنشاء كافة الحسابات التجريبية',
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              onPressed: () => _showSeedConfirmDialog(context, adminController),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => adminController.fetchDoctors(),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.medical_services_outlined), text: 'الأطباء'),
              Tab(icon: Icon(Icons.healing_outlined), text: 'التمريض'),
              Tab(icon: Icon(Icons.local_pharmacy_outlined), text: 'الصيدليات'),
              Tab(icon: Icon(Icons.science_outlined), text: 'المعامل'),
              Tab(icon: Icon(Icons.image_search_rounded), text: 'الأشعة'),
              Tab(icon: Icon(Icons.notifications_outlined), text: 'الإشعارات'),
              Tab(icon: Icon(Icons.view_carousel_outlined), text: 'البانر'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildManagementList(context, adminController, filterRole: UserRole.doctor),
            _buildManagementList(context, adminController, filterRole: UserRole.nurse),
            _buildManagementList(context, adminController, filterRole: UserRole.pharmacy),
            _buildManagementList(context, adminController, filterRole: UserRole.lab),
            _buildManagementList(context, adminController, filterRole: UserRole.xray),
            _buildNotificationsTab(context),
            _buildBannerTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddChoice(context, adminController),
          backgroundColor: const Color(0xFF1E8C78),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAccessDenied(AuthController authController) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text('عذراً، هذه المنطقة للمشرفين فقط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => authController.logout(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51)),
              child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── NOTIFICATIONS TAB ─────────────────
  Widget _buildNotificationsTab(BuildContext context) {
    final notifCtrl = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إرسال إشعار لجميع المستخدمين',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF135B51)),
            ),
            const SizedBox(height: 6),
            const Text('سيظهر الإشعار فوراً لكل مستخدمي التطبيق',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),

            // Title field
            TextFormField(
              controller: titleCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'عنوان الإشعار',
                prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF1E8C78)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Body field
            TextFormField(
              controller: bodyCtrl,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'محتوى الإشعار...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.message_outlined, color: Color(0xFF1E8C78)),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Send button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: notifCtrl.isSending.value
                    ? null
                    : () => notifCtrl.sendNotificationToAll(
                          title: titleCtrl.text,
                          body: bodyCtrl.text,
                        ),
                icon: notifCtrl.isSending.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(notifCtrl.isSending.value ? 'جاري الإرسال...' : 'إرسال للجميع',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E8C78),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            )),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            const Text('الإشعارات المُرسلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Obx(() {
              if (notifCtrl.notifications.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        const Text('لا توجد إشعارات مُرسلة بعد', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: notifCtrl.notifications.map((notif) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF1E8C78).withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1E8C78)),
                    ),
                    title: Text(notif['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notif['body'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(notifCtrl.formatDate(notif['sentAt']), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => notifCtrl.deleteNotification(notif['id']),
                    ),
                  ),
                )).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ───────────────── BANNER TAB ─────────────────
  Widget _buildBannerTab() {
    final bannerCtrl = Get.isRegistered<BannerController>()
        ? Get.find<BannerController>()
        : Get.put(BannerController());

    final titleCtrl    = TextEditingController(text: bannerCtrl.title.value);
    final subtitleCtrl = TextEditingController(text: bannerCtrl.subtitle.value);
    final btnCtrl      = TextEditingController(text: bannerCtrl.buttonText.value);

    return Obx(() {
      final imgUrl = bannerCtrl.imageUrl.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إدارة بانر الصفحة الرئيسية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF135B51)),
            ),
            const SizedBox(height: 20),

            // Preview
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF1E8C78),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.hardEdge,
              child: imgUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(imgUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, color: Colors.white, size: 60)),
                        Container(color: Colors.black26),
                        Center(
                          child: Text(
                            bannerCtrl.title.value,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_outlined, color: Colors.white60, size: 50),
                        const SizedBox(height: 8),
                        Text(
                          bannerCtrl.title.value.isNotEmpty ? bannerCtrl.title.value : 'معاينة البانر',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // Image Picker Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final f = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (f != null) await bannerCtrl.uploadBannerImage(File(f.path));
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('المعرض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF135B51),
                      side: const BorderSide(color: Color(0xFF135B51)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final f = await ImagePicker().pickImage(source: ImageSource.camera);
                      if (f != null) await bannerCtrl.uploadBannerImage(File(f.path));
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('الكاميرا'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF135B51),
                      side: const BorderSide(color: Color(0xFF135B51)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Text Fields
            _buildBannerField(titleCtrl, 'عنوان البانر', Icons.title),
            const SizedBox(height: 14),
            _buildBannerField(subtitleCtrl, 'نص ثانوي (اختياري)', Icons.text_fields),
            const SizedBox(height: 14),
            _buildBannerField(btnCtrl, 'نص زرار البانر', Icons.smart_button_outlined),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: bannerCtrl.isSaving.value
                    ? null
                    : () async {
                        try {
                          await bannerCtrl.saveBannerText(
                            title:      titleCtrl.text.trim(),
                            subtitle:   subtitleCtrl.text.trim(),
                            buttonText: btnCtrl.text.trim(),
                          );
                          Get.snackbar(
                            '✅ نجاح',
                            'تم تحديث البانر وسيظهر فورًا لجميع المستخدمين',
                            backgroundColor: const Color(0xFF1E8C78),
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } catch (e) {
                          Get.snackbar('خطأ', 'فشل الحفظ',
                              backgroundColor: Colors.red, colorText: Colors.white);
                        }
                      },
                icon: bannerCtrl.isSaving.value
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, color: Colors.white),
                label: Text(
                  bannerCtrl.isSaving.value ? 'جاري الحفظ...' : 'حفظ التغييرات',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135B51),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }

  Widget _buildBannerField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E8C78)),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildManagementList(BuildContext context, AdminController controller, {required UserRole filterRole}) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF135B51)));
      }

      final users = controller.doctors.where((u) => u.role == filterRole).toList();

      if (users.isEmpty) {
        String msg = '';
        IconData icon = Icons.person_off;
        if (filterRole == UserRole.doctor) { msg = 'لا يوجد أطباء حالياً'; icon = Icons.medical_services_outlined; }
        else if (filterRole == UserRole.pharmacy) { msg = 'لا توجد صيدليات حالياً'; icon = Icons.local_pharmacy_outlined; }
        else if (filterRole == UserRole.nurse) { msg = 'لا يوجد تمريض حالياً'; icon = Icons.healing_outlined; }
        else if (filterRole == UserRole.lab) { msg = 'لا يوجد معامل حالياً'; icon = Icons.science_outlined; }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text(msg, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserManagementCard(context, user, controller);
        },
      );
    });
  }

  Widget _buildUserManagementCard(BuildContext context, UserModel user, AdminController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F5F3),
          child: Icon(
            user.role == UserRole.doctor ? Icons.person : 
            (user.role == UserRole.nurse ? Icons.healing : 
            (user.role == UserRole.lab ? Icons.science : 
            (user.role == UserRole.xray ? Icons.image_search_rounded : Icons.local_pharmacy))), 
            color: const Color(0xFF1E8C78)
          ),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${user.specialty ?? 'بدون تخصص'} - ${user.city ?? 'غير محدد'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
              onPressed: () => _showEditDoctorDialog(context, user, controller), // Reuse for simple name/specialty edits
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _showDeleteConfirmDialog(context, user, controller),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChoice(BuildContext context, AdminController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ماذا تريد أن تضيف؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.medical_services, color: Color(0xFF135B51)),
              title: const Text('إضافة دكتور'),
              onTap: () { Get.back(); _showAddDoctorDialog(context, controller); },
            ),
            ListTile(
              leading: const Icon(Icons.healing, color: Color(0xFF135B51)),
              title: const Text('إضافة تمريض منزلي'),
              onTap: () { Get.back(); _showAddNurseDialog(context, controller); },
            ),
            ListTile(
              leading: const Icon(Icons.local_pharmacy, color: Color(0xFF135B51)),
              title: const Text('إضافة صيدلية'),
              onTap: () { Get.back(); _showAddPharmacyDialog(context, controller); },
            ),
            ListTile(
              leading: const Icon(Icons.science, color: Color(0xFF135B51)),
              title: const Text('إضافة معمل'),
              onTap: () { Get.back(); _showAddLabDialog(context, controller); },
            ),
            ListTile(
              leading: const Icon(Icons.image_search_rounded, color: Color(0xFF135B51)),
              title: const Text('إضافة مركز أشعة'),
              onTap: () { Get.back(); _showAddXrayDialog(context, controller); },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddXrayDialog(BuildContext context, AdminController controller) {
    final formKey            = GlobalKey<FormState>();
    final nameController     = TextEditingController();
    final specialtyController = TextEditingController(text: 'أشعة وتصوير طبي');
    final locationController = TextEditingController();
    final govController      = TextEditingController();
    final cityController     = TextEditingController();
    final bioController      = TextEditingController();
    final emailController    = TextEditingController();
    final passwordController = TextEditingController();
    final mapsLinkController = TextEditingController();
    final photoUrlController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('إضافة مركز أشعة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPopupField(nameController,      'اسم مركز الأشعة',             Icons.image_search_rounded),
                  _buildPopupField(specialtyController, 'التخصص',                          Icons.category_outlined),
                  _buildPopupField(locationController,  'اللوكيشن (وصف نصي)',              Icons.location_on_outlined),
                  _buildPopupField(govController,       'المحافظة',                        Icons.map_outlined),
                  _buildPopupField(cityController,      'المدينة',                         Icons.location_city_outlined),
                  _buildPopupField(mapsLinkController,  'رابط جوجل ماب (اختياري)',         Icons.map_rounded),
                  _buildPopupField(photoUrlController,  'رابط صورة المركز (اختياري)',      Icons.image_outlined, suffixIcon: IconButton(icon: const Icon(Icons.photo_library), onPressed: () => _pickAndUploadImage(photoUrlController))),
                  _buildPopupField(bioController,       'نبذة عن المركز',                  Icons.info_outline),
                  _buildPopupField(emailController,     'الإيميل',                         Icons.email_outlined),
                  _buildPopupField(passwordController,  'الباسورد',                        Icons.lock_outline, obscure: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                controller.addXray(
                  name:          nameController.text,
                  specialty:     specialtyController.text,
                  location:      locationController.text,
                  governorate:   govController.text,
                  city:          cityController.text,
                  googleMapsLink: mapsLinkController.text.trim().isEmpty ? null : mapsLinkController.text.trim(),
                  photoUrl:      photoUrlController.text.trim().isEmpty ? null : photoUrlController.text.trim(),
                  bio:           bioController.text,
                  email:         emailController.text,
                  password:      passwordController.text,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddLabDialog(BuildContext context, AdminController controller) {
    final formKey = GlobalKey<FormState>();
    final nameController        = TextEditingController();
    final locationController    = TextEditingController();
    final govController         = TextEditingController();
    final cityController        = TextEditingController();
    final bioController         = TextEditingController();
    final emailController       = TextEditingController();
    final passwordController    = TextEditingController();
    final mapsLinkController    = TextEditingController();
    final photoUrlController    = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('إضافة معمل تحاليل', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPopupField(nameController,      'اسم المعمل',                      Icons.science_outlined),
                  _buildPopupField(locationController,  'اللوكيشن (وصف نصي)',              Icons.location_on_outlined),
                  _buildPopupField(govController,       'المحافظة',                        Icons.map_outlined),
                  _buildPopupField(cityController,      'المدينة',                         Icons.location_city_outlined),
                  _buildPopupField(mapsLinkController,  'رابط جوجل ماب (اختياري)',         Icons.map_rounded),
                  _buildPopupField(photoUrlController,  'رابط صورة المعمل (اختياري)',      Icons.image_outlined, suffixIcon: IconButton(icon: const Icon(Icons.photo_library), onPressed: () => _pickAndUploadImage(photoUrlController))),
                  _buildPopupField(bioController,       'نبذة عن المعمل',                  Icons.info_outline),
                  _buildPopupField(emailController,     'الإيميل',                         Icons.email_outlined),
                  _buildPopupField(passwordController,  'الباسورد',                        Icons.lock_outline, obscure: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                controller.addLab(
                  name:          nameController.text,
                  location:      locationController.text,
                  governorate:   govController.text,
                  city:          cityController.text,
                  googleMapsLink: mapsLinkController.text.trim().isEmpty ? null : mapsLinkController.text.trim(),
                  photoUrl:      photoUrlController.text.trim().isEmpty ? null : photoUrlController.text.trim(),
                  bio:           bioController.text,
                  email:         emailController.text,
                  password:      passwordController.text,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddPharmacyDialog(BuildContext context, AdminController controller) {
    final formKey = GlobalKey<FormState>();
    final nameController        = TextEditingController();
    final specialtyController   = TextEditingController();
    final locationController    = TextEditingController();
    final govController         = TextEditingController();
    final cityController        = TextEditingController();
    final bioController         = TextEditingController();
    final emailController       = TextEditingController();
    final passwordController    = TextEditingController();
    final mapsLinkController    = TextEditingController();
    final photoUrlController    = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('إضافة صيدلية جديدة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPopupField(nameController,      'اسم الصيدلية',                    Icons.local_pharmacy_outlined),
                  _buildPopupField(specialtyController, 'التخصص',                          Icons.category_outlined),
                  _buildPopupField(locationController,  'اللوكيشن (وصف نصي)',              Icons.location_on_outlined),
                  _buildPopupField(govController,       'المحافظة',                        Icons.map_outlined),
                  _buildPopupField(cityController,      'المدينة',                         Icons.location_city_outlined),
                  _buildPopupField(mapsLinkController,  'رابط جوجل ماب (اختياري)',         Icons.map_rounded),
                  _buildPopupField(photoUrlController,  'رابط صورة الصيدلية (اختياري)',    Icons.image_outlined, suffixIcon: IconButton(icon: const Icon(Icons.photo_library), onPressed: () => _pickAndUploadImage(photoUrlController))),
                  _buildPopupField(bioController,       'البايو بتاع الصيدلية',            Icons.info_outline),
                  _buildPopupField(emailController,     'الإيميل',                         Icons.email_outlined),
                  _buildPopupField(passwordController,  'الباسورد',                        Icons.lock_outline, obscure: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                controller.addPharmacy(
                  name:          nameController.text,
                  specialty:     specialtyController.text,
                  location:      locationController.text,
                  governorate:   govController.text,
                  city:          cityController.text,
                  googleMapsLink: mapsLinkController.text.trim().isEmpty ? null : mapsLinkController.text.trim(),
                  photoUrl:      photoUrlController.text.trim().isEmpty ? null : photoUrlController.text.trim(),
                  bio:           bioController.text,
                  email:         emailController.text,
                  password:      passwordController.text,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddNurseDialog(BuildContext context, AdminController controller) {
    final formKey = GlobalKey<FormState>();
    final nameController        = TextEditingController();
    final specialtyController   = TextEditingController();
    final priceController       = TextEditingController();
    final locationController    = TextEditingController();
    final govController         = TextEditingController();
    final cityController        = TextEditingController();
    final bioController         = TextEditingController();
    final emailController       = TextEditingController();
    final passwordController    = TextEditingController();
    final mapsLinkController    = TextEditingController();
    final photoUrlController    = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('إضافة تمريض منزلي', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPopupField(nameController,      'الاسم (مثال: أسماء أحمد)',        Icons.person_outline),
                  _buildPopupField(specialtyController, 'التخصص (مثال: رعاية جروح)',       Icons.medical_services_outlined),
                  _buildPopupField(priceController,     'سعر الزيارة (بالجنيه)',           Icons.attach_money_outlined, isNumeric: true),
                  _buildPopupField(locationController,  'اللوكيشن (وصف نصي)',              Icons.location_on_outlined),
                  _buildPopupField(govController,       'المحافظة',                        Icons.map_outlined),
                  _buildPopupField(cityController,      'المدينة',                         Icons.location_city_outlined),
                  _buildPopupField(mapsLinkController,  'رابط جوجل ماب (اختياري)',         Icons.map_rounded),
                  _buildPopupField(photoUrlController,  'رابط صورة التمريض (اختياري)',     Icons.image_outlined, suffixIcon: IconButton(icon: const Icon(Icons.photo_library), onPressed: () => _pickAndUploadImage(photoUrlController))),
                  _buildPopupField(bioController,       'البايو والخبرات',                 Icons.info_outline),
                  _buildPopupField(emailController,     'الإيميل',                         Icons.email_outlined),
                  _buildPopupField(passwordController,  'الباسورد',                        Icons.lock_outline, obscure: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                controller.addNurse(
                  name:          nameController.text,
                  specialty:     specialtyController.text,
                  price:         priceController.text,
                  location:      locationController.text,
                  governorate:   govController.text,
                  city:          cityController.text,
                  googleMapsLink: mapsLinkController.text.trim().isEmpty ? null : mapsLinkController.text.trim(),
                  photoUrl:      photoUrlController.text.trim().isEmpty ? null : photoUrlController.text.trim(),
                  bio:           bioController.text,
                  email:         emailController.text,
                  password:      passwordController.text,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddDoctorDialog(BuildContext context, AdminController controller) {
    final formKey = GlobalKey<FormState>();
    final nameController        = TextEditingController();
    final specialtyController   = TextEditingController();
    final priceController       = TextEditingController();
    final locationController    = TextEditingController();
    final govController         = TextEditingController();
    final cityController        = TextEditingController();
    final bioController         = TextEditingController();
    final emailController       = TextEditingController();
    final passwordController    = TextEditingController();
    final mapsLinkController    = TextEditingController();
    final photoUrlController    = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('إضافة دكتور جديد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPopupField(nameController,       'اسم الدكتور',                     Icons.person_outline),
                  _buildPopupField(specialtyController,  'التخصص',                          Icons.medical_services_outlined),
                  _buildPopupField(priceController,      'السعر',                           Icons.attach_money_outlined),
                  _buildPopupField(locationController,   'اللوكيشن (وصف نصي)',              Icons.location_on_outlined),
                  _buildPopupField(govController,        'المحافظة',                        Icons.map_outlined),
                  _buildPopupField(cityController,       'المدينة',                         Icons.location_city_outlined),
                  _buildPopupField(mapsLinkController,   'رابط جوجل ماب (اختياري)',         Icons.map_rounded),
                  _buildPopupField(photoUrlController,   'رابط صورة الدكتور (اختياري)',     Icons.image_outlined, suffixIcon: IconButton(icon: const Icon(Icons.photo_library), onPressed: () => _pickAndUploadImage(photoUrlController))),
                  _buildPopupField(bioController,        'البايو بتاع الدكتور',             Icons.info_outline),
                  _buildPopupField(emailController,      'الإيميل',                         Icons.email_outlined),
                  _buildPopupField(passwordController,   'الباسورد',                        Icons.lock_outline, obscure: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                controller.addDoctor(
                  name:          nameController.text,
                  specialty:     specialtyController.text,
                  price:         priceController.text,
                  location:      locationController.text,
                  governorate:   govController.text,
                  city:          cityController.text,
                  googleMapsLink: mapsLinkController.text.trim().isEmpty ? null : mapsLinkController.text.trim(),
                  bio:           bioController.text,
                  email:         emailController.text,
                  password:      passwordController.text,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8C78), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('إضافة الآن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDoctorDialog(BuildContext context, UserModel doctor, AdminController controller) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: doctor.name);
    final specialtyController = TextEditingController(text: doctor.specialty);
    final priceController = TextEditingController(text: doctor.price?.toString() ?? '');
    final locationController = TextEditingController(text: doctor.location);
    final govController = TextEditingController(text: doctor.governorate);
    final cityController = TextEditingController(text: doctor.city);
    final bioController = TextEditingController(text: doctor.bio);
    final mapsLinkController = TextEditingController(text: doctor.googleMapsLink);
    final photoUrlController = TextEditingController(text: doctor.photoUrl);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('تعديل البيانات', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPopupField(nameController, 'الاسم', Icons.person_outline),
                  _buildPopupField(specialtyController, 'التخصص', Icons.medical_services_outlined),
                  _buildPopupField(priceController, 'السعر / الكشف', Icons.attach_money_outlined, isNumeric: true),
                  _buildPopupField(locationController, 'اللوكيشن', Icons.location_on_outlined),
                  _buildPopupField(govController, 'المحافظة', Icons.map_outlined),
                  _buildPopupField(cityController, 'المدينة', Icons.location_city_outlined),
                  _buildPopupField(mapsLinkController, 'رابط ماب', Icons.map_rounded),
                  _buildPopupField(photoUrlController, 'رابط الصورة', Icons.image_outlined, suffixIcon: IconButton(icon: const Icon(Icons.photo_library), onPressed: () => _pickAndUploadImage(photoUrlController))),
                  _buildPopupField(bioController, 'البايو', Icons.info_outline),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                controller.updateDoctorDetails(
                  doctorId: doctor.uid,
                  name: nameController.text,
                  specialty: specialtyController.text,
                  price: priceController.text,
                  location: locationController.text,
                  governorate: govController.text,
                  city: cityController.text,
                  bio: bioController.text,
                  googleMapsLink: mapsLinkController.text,
                  photoUrl: photoUrlController.text,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B51), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, UserModel doctor, AdminController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف الدكتور ${doctor.name}؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('رجوع')),
          ElevatedButton(
            onPressed: () {
              controller.removeDoctor(doctor.uid);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSeedConfirmDialog(BuildContext context, AdminController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إنشاء حسابات تجريبية', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('سيقوم التطبيق بإنشاء كافة الحسابات المطلوبة (إدمن، دكاترة، صيدلية) لتجربة النظام بالكامل.\n\nهل تريد الاستمرار؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.seedDemoData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8C78)),
            child: const Text('إنشاء الآن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupField(TextEditingController controller, String hint, IconData icon, {bool obscure = false, bool isNumeric = false, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF1E8C78), size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (v) => hint.contains('اختياري') ? null : (v!.isEmpty ? 'لا يمكن ترك الحقل فارغاً' : null),
      ),
    );
  }

  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      
      Get.dialog(const Center(child: CircularProgressIndicator(color: Color(0xFF135B51))), barrierDismissible: false);
      
      final ref = FirebaseStorage.instance.ref('admin_uploads/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(await pickedFile.readAsBytes());
      final url = await ref.getDownloadURL();
      
      controller.text = url;
      Get.back();
      Get.snackbar('نجاح', 'تم رفع الصورة بنجاح!', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.back();
      if (e.toString().contains('permission-denied')) {
        Get.snackbar(
          'تنبيه الحماية',
          'قواعد Storage تمنع الرفع. يرجى تعديل Firebase Storage Rules إلى allow read, write: if true;',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
      } else {
        Get.snackbar('خطأ', 'حدث خطأ أثناء الرفع: $e', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }
}
