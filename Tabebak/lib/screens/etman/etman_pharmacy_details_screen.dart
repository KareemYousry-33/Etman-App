import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'etman_colors.dart';
import '../../models/pharmacy_model.dart';
import 'p2p_chat_screen.dart';
import '../../controllers/p2p_chat_controller.dart';
import 'prescription_workflow_screen.dart';

class EtmanPharmacyDetailsScreen extends StatelessWidget {
  final PharmacyModel pharmacy;

  const EtmanPharmacyDetailsScreen({Key? key, required this.pharmacy}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeaderInfo(),
                    const SizedBox(height: 25),
                    _buildQuickActions(),
                    const SizedBox(height: 30),
                    _buildAboutSection(),
                    const SizedBox(height: 30),
                    _buildLocationSection(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: _buildBottomAction(context),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: EtmanColors.primaryTeal,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.white24,
          child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            pharmacy.getImageWidget(fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pharmacy.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 16),
                  const SizedBox(width: 5),
                  Text('${pharmacy.governorate} - ${pharmacy.city}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 5),
                  Text(pharmacy.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 5),
                  const Text('(١٢٠ تقييم)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: pharmacy.getImageWidget(fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionCircle(Icons.phone, 'اتصال', () => launchUrl(Uri.parse('tel:${pharmacy.phoneNumber}'))),
        _buildActionCircle(Icons.chat_bubble_outline, 'محادثة', () async {
          Get.dialog(const Center(child: CircularProgressIndicator(color: EtmanColors.primaryTeal)), barrierDismissible: false);
          try {
            final p2pController = Get.put(P2PChatController());
            final roomId = await p2pController.getOrCreateChatRoom(receiverId: pharmacy.name, type: 'pharmacy', pharmacyId: pharmacy.name);
            Get.back();
            Get.to(() => P2PChatScreen(roomId: roomId, receiverName: pharmacy.name, receiverId: pharmacy.name));
          } catch (e) {
            Get.back();
            Get.snackbar("خطأ", "تعذر بدء المحادثة", backgroundColor: Colors.red, colorText: Colors.white);
          }
        }),
        _buildActionCircle(Icons.share_outlined, 'مشاركة', () {
          Clipboard.setData(ClipboardData(text: "🏥 ${pharmacy.name}\n📍 ${pharmacy.governorate} - ${pharmacy.city}\n📞 هاتف: ${pharmacy.phoneNumber ?? 'N/A'}\n\nتطبيق أطمئن - راحة بالك في إيدك"));
          Get.snackbar("تم النسخ", "تم تجهيز البيانات، يمكنك مشاركتها الآن!", backgroundColor: EtmanColors.primaryTeal, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        }),
      ],
    );
  }

  Widget _buildActionCircle(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF1FAF9), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1E8C78).withOpacity(0.1))),
            child: Icon(icon, color: const Color(0xFF1E8C78)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('عن الصيدلية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          pharmacy.bio.isEmpty ? 'تقدم الصيدلية خدمة متميزة على مدار الساعة مع توفير كافة الأدوية ومستحضرات التجميل العالمية.' : pharmacy.bio,
          style: const TextStyle(color: Colors.grey, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الموقع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12)),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('عرض على الخريطة', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const PrescriptionWorkflowScreen()),
                icon: const Icon(Icons.receipt_long, color: Colors.white),
                label: const Text('طلب بالروشتة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: EtmanColors.primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Container(
            height: 55, width: 55,
            decoration: BoxDecoration(color: const Color(0xFFF1FAF9), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1E8C78)),
          ),
        ],
      ),
    );
  }
}
