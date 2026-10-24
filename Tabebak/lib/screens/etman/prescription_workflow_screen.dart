import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:etman/controllers/pharmacy_controller.dart';
import 'package:etman/controllers/p2p_chat_controller.dart';
import 'package:etman/models/pharmacy_model.dart';
import 'package:etman/screens/etman/p2p_chat_screen.dart';
import 'dart:io';

class PrescriptionWorkflowScreen extends StatefulWidget {
  const PrescriptionWorkflowScreen({Key? key}) : super(key: key);

  @override
  State<PrescriptionWorkflowScreen> createState() => _PrescriptionWorkflowScreenState();
}

class _PrescriptionWorkflowScreenState extends State<PrescriptionWorkflowScreen> {
  final PharmacyController pharmacyController = Get.isRegistered<PharmacyController>()
      ? Get.find<PharmacyController>()
      : Get.put(PharmacyController());

  File? _prescriptionImage;
  String? _selectedGovernorate;
  String? _selectedCity;
  bool _sending = false;

  final Map<String, List<String>> _locations = {
    'القاهرة':     ['مدينة نصر', 'مصر الجديدة', 'المعادي', 'التجمع الخامس', 'شبرا', 'حلوان'],
    'الجيزة':      ['المهندسين', 'الدقي', 'الهرم', '6 أكتوبر', 'بولاق الدكرور'],
    'الإسكندرية': ['سموحة', 'سيدي جابر', 'المنتزه', 'كليوباترا', 'العجمي'],
    'الشرقية':    ['الزقازيق', 'منيا القمح', 'بلبيس', 'العاشر من رمضان'],
    'المنوفية':   ['شبين الكوم', 'منوف', 'أشمون'],
    'الدقهلية':   ['المنصورة', 'طلخا', 'ميت غمر'],
  };

  @override
  void initState() {
    super.initState();
    pharmacyController.fetchAllPharmacies();
  }

  Future<void> _handleUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _prescriptionImage = File(picked.path));
    }
  }

  // ── After choosing a pharmacy: create/get P2P room, send image, navigate to chat ──
  Future<void> _sendToPharmacy(PharmacyModel pharmacy) async {
    if (_prescriptionImage == null) return;

    setState(() => _sending = true);
    Get.back(); // close bottom sheet

    try {
      final p2p = Get.isRegistered<P2PChatController>()
          ? Get.find<P2PChatController>()
          : Get.put(P2PChatController());

      final pharmacyId = pharmacy.id ?? pharmacy.name;

      // Create or get existing room with the pharmacy
      final roomId = await p2p.getOrCreateChatRoom(
        receiverId: pharmacyId,
        type: 'pharmacy',
      );

      // Send the prescription image as a message
      await p2p.sendMessage(
        roomId: roomId,
        receiverId: pharmacyId,
        text: 'طلب صرف روشتة',
        imageFile: _prescriptionImage,
      );

      setState(() => _sending = false);

      // ✅ Navigate to P2P chat with the pharmacy
      Get.to(() => P2PChatScreen(
        roomId: roomId,
        receiverName: pharmacy.name,
        receiverId: pharmacyId,
      ));
    } catch (e) {
      setState(() => _sending = false);
      Get.snackbar('خطأ', 'فشل إرسال الروشتة: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _submitPrescription() {
    if (_prescriptionImage == null) {
      Get.snackbar('تنبيه', 'الرجاء تصوير الروشتة أولاً',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (_selectedGovernorate == null || _selectedCity == null) {
      Get.snackbar('تنبيه', 'الرجاء اختيار المحافظة والمدينة',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    // Filter pharmacies
    List<PharmacyModel> matched = pharmacyController.pharmacies.where((p) =>
        p.governorate == _selectedGovernorate && p.city == _selectedCity).toList();

    if (matched.isEmpty) {
      matched = pharmacyController.pharmacies.where((p) =>
          p.governorate == _selectedGovernorate).toList();
    }

    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('الصيدليات المتاحة في منطقتك',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              if (matched.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(children: [
                    const Icon(Icons.local_pharmacy_outlined, size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text('لا توجد صيدليات مسجلة في هذا النطاق حالياً.',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ]),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: matched.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = matched[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E8C78),
                          child: const Icon(Icons.local_pharmacy, color: Colors.white),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.governorate} - ${p.city}',
                            style: const TextStyle(fontSize: 12)),
                        trailing: ElevatedButton(
                          onPressed: () => _sendToPharmacy(p),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E8C78),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size(70, 36),
                          ),
                          child: const Text('إرسال', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,   // ✅ RTL
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('روشتة / موافقة طبية',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ),
        body: _sending
            ? const Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CircularProgressIndicator(color: Color(0xFF1E8C78)),
                  SizedBox(height: 16),
                  Text('جاري إرسال الروشتة...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ]),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Step 1: Image ──
                    if (_prescriptionImage == null) ...[
                      const Icon(Icons.receipt_long, size: 90, color: Color(0xFF1E8C78)),
                      const SizedBox(height: 20),
                      const Text('قم برفع صورة الروشتة أو الموافقة الطبية لطلب الأدوية مباشرة',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 35),
                      _uploadBtn('التقط صورة بالكاميرا', Icons.camera_alt,
                          () => _handleUpload(ImageSource.camera)),
                      const SizedBox(height: 16),
                      _uploadBtn('اختر من المعرض', Icons.photo_library,
                          () => _handleUpload(ImageSource.gallery)),
                    ] else ...[
                      // ── Prescription preview ──
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_prescriptionImage!,
                            height: 220, width: double.infinity, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => setState(() => _prescriptionImage = null),
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        label: const Text('إعادة التقاط الصورة',
                            style: TextStyle(color: Colors.orange)),
                      ),
                      const Divider(height: 30),

                      // ── Step 2: Location ──
                      const Text('📍 اختر منطقتك للبحث عن صيدليات قريبة:',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),

                      // Governorate
                      _dropdown(
                        hint: 'اختر المحافظة',
                        value: _selectedGovernorate,
                        items: _locations.keys.toList(),
                        onChanged: (v) => setState(() {
                          _selectedGovernorate = v;
                          _selectedCity = null;
                        }),
                      ),
                      const SizedBox(height: 12),

                      // City
                      _dropdown(
                        hint: 'اختر المدينة / الحي',
                        value: _selectedCity,
                        items: _selectedGovernorate == null ? [] : _locations[_selectedGovernorate]!,
                        onChanged: (v) => setState(() => _selectedCity = v),
                      ),
                      const SizedBox(height: 24),

                      _uploadBtn('بحث وإرسال للصيدليات ←', Icons.send, _submitPrescription),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          value: value,
          items: items.map((s) => DropdownMenuItem(value: s,
              child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _uploadBtn(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E8C78),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}
