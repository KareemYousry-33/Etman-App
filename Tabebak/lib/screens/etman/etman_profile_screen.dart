import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'etman_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/medical_record_controller.dart';
import '../../models/medical_record_model.dart';
import '../../controllers/etman_main_wrapper_controller.dart';

class EtmanProfileScreen extends StatefulWidget {
  const EtmanProfileScreen({Key? key}) : super(key: key);

  @override
  State<EtmanProfileScreen> createState() => _EtmanProfileScreenState();
}

class _EtmanProfileScreenState extends State<EtmanProfileScreen> {
  final AuthController authController = Get.find<AuthController>();
  final MedicalRecordController recordController = Get.put(MedicalRecordController());
  
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildEssentialDataSection(),
                const SizedBox(height: 20),
                _buildPrescriptionSection(),
                const SizedBox(height: 20),
                _buildMedicalRecordForm(),
                const SizedBox(height: 20),
                _buildLogoutButton(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: EtmanColors.primaryTeal,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Get.back();
          } else if (Get.isRegistered<EtmanMainWrapperController>()) {
            Get.find<EtmanMainWrapperController>().changeIndex(0);
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [EtmanColors.primaryTeal, const Color(0xFF135B51)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildProfileAvatar(),
              const SizedBox(height: 12),
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    authController.currentUser.value?.name ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showEditNameDialog(),
                    child: const Icon(Icons.edit, color: Colors.white70, size: 18),
                  ),
                ],
              )),
              Obx(() => Text(
                authController.currentUser.value?.email ?? '',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
          child: Obx(() {
            final photoUrl = authController.currentUser.value?.photoUrl;
            return CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white24,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) as ImageProvider : null,
              child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
            );
          }),
        ),
        GestureDetector(
          onTap: () => _showEditProfileSheet(),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.camera_alt, color: EtmanColors.primaryTeal, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('روشتاتي السابقة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => _pickAndUploadPrescription(),
                icon: Icon(Icons.add_a_photo, color: EtmanColors.primaryTeal),
              ),
            ],
          ),
        ),
        Obx(() {
          final prescriptions = recordController.currentRecord.value?.prescriptions ?? [];
          if (prescriptions.isEmpty) {
            return _buildEmptyPrescriptionPlaceholder();
          }
          return SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: prescriptions.length,
              itemBuilder: (context, index) {
                return _buildPrescriptionItem(prescriptions[index]);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyPrescriptionPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Icon(Icons.receipt_long, color: Colors.grey[400], size: 40),
          const SizedBox(height: 10),
          const Text('لا توجد روشتات محفوظة بعد', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPrescriptionItem(String url) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildEssentialDataSection() {
    final user = authController.currentUser.value;
    final phoneCtrl  = TextEditingController(text: user?.phoneNumber ?? '');
    final ageCtrl    = TextEditingController(text: user?.age?.toString() ?? '');
    String? selectedGov = user?.governorate;

    final govs = [
      'القاهرة','الجيزة','الإسكندرية','الشرقية','الدقهلية','الغربية','المنوفية',
      'القليوبية','البحيرة','كفر الشيخ','الفيوم','بني سويف','المنيا','أسيوط',
      'سوهاج','قنا','الأقصر','أسوان','البحر الأحمر','مطروح','الوادي الجديد',
      'شمال سيناء','جنوب سيناء','السويس','الإسماعيلية','بورسعيد',
    ];

    return StatefulBuilder(builder: (ctx, ss) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF6F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E8C78).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_pin_outlined, color: Color(0xFF135B51)),
                const SizedBox(width: 8),
                const Text('البيانات الأساسية للحجز',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF135B51))),
                const Spacer(),
                Obx(() {
                  final u = authController.currentUser.value;
                  final complete = (u?.phoneNumber?.isNotEmpty == true) &&
                      (u?.age != null) &&
                      (u?.governorate?.isNotEmpty == true);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: complete ? const Color(0xFF135B51) : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      complete ? 'مكتملة ✓' : 'ناقصة',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            const Text('هذه البيانات مطلوبة لإتمام الحجز',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            // Phone
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF135B51)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            // Age
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'السن',
                prefixIcon: const Icon(Icons.cake_outlined, color: Color(0xFF135B51)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            // Governorate
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedGov,
                  isExpanded: true,
                  hint: const Text('اختر المحافظة', style: TextStyle(color: Colors.grey)),
                  items: govs.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => ss(() => selectedGov = val),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                onPressed: authController.isLoading.value
                    ? null
                    : () {
                        final phone = phoneCtrl.text.trim();
                        final age   = int.tryParse(ageCtrl.text.trim());
                        if (phone.isEmpty || age == null || selectedGov == null) {
                          Get.snackbar('تنبيه', 'برجاء إدخال جميع البيانات',
                              backgroundColor: Colors.orange, colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        authController.updatePatientInfo(
                          phoneNumber: phone,
                          age: age,
                          governorate: selectedGov,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135B51),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: authController.isLoading.value
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('حفظ البيانات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMedicalRecordForm() {
    return Obx(() {
      final rec = recordController.currentRecord.value;

      // local mutable copies — rebuilt only when rec changes
      String? bloodType   = rec?.bloodType;
      double height       = rec?.height  ?? 170;
      double weight       = rec?.weight  ?? 70;
      bool isSmoking      = rec?.lifestyle?.isSmoking  ?? false;
      bool isDrinking     = rec?.lifestyle?.isDrinking ?? false;
      String? activityLevel = rec?.lifestyle?.activityLevel;
      String? complaint   = rec?.currentSymptoms?.complaint;
      String? onset       = rec?.currentSymptoms?.onset;
      int painScale       = rec?.currentSymptoms?.painScale ?? 5;
      String? trend       = rec?.currentSymptoms?.trend;
      String medication   = rec?.currentMedications?.map((m) => m.name).join(', ') ?? '';
      String allergy      = rec?.allergies?.map((a) => a.name).join(', ') ?? '';
      List<String> selectedChronicDiseases =
          rec?.chronicDiseases?.map((e) => e.name).toList() ?? [];

      final medCtrl       = TextEditingController(text: medication);
      final allergyCtrl   = TextEditingController(text: allergy);
      final complaintCtrl = TextEditingController(text: complaint);
      final onsetCtrl     = TextEditingController(text: onset);

      final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
      final chronicOptions = ['سكر', 'ضغط', 'قلب', 'ربو'];
      final activityOptions = ['رياضي', 'متوسط', 'خامل'];
      final trendOptions = ['تحسن', 'استقرار', 'تدهور'];

      return StatefulBuilder(builder: (ctx, ss) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('السجل الطبي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // ── 1. البيانات الأساسية ──
              _sectionCard(
                title: 'البيانات الجسمانية',
                icon: Icons.person_outline,
                children: [
                  _dropRow('فصيلة الدم', bloodTypes, bloodType,
                      (v) => ss(() => bloodType = v)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _sliderTile(
                      label: 'الطول (سم)',
                      value: height, min: 100, max: 220, divisions: 120,
                      onChanged: (v) => ss(() => height = v),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _sliderTile(
                      label: 'الوزن (كجم)',
                      value: weight, min: 30, max: 200, divisions: 170,
                      onChanged: (v) => ss(() => weight = v),
                    )),
                  ]),
                ],
              ),

              // ── 2. التاريخ المرضي ──
              _sectionCard(
                title: 'الأمراض المزمنة',
                icon: Icons.history,
                children: [
                  Wrap(
                    spacing: 8, runSpacing: 4,
                    children: chronicOptions.map((e) {
                      final sel = selectedChronicDiseases.contains(e);
                      return FilterChip(
                        label: Text(e),
                        selected: sel,
                        selectedColor: const Color(0xFFCBEAEA),
                        checkmarkColor: const Color(0xFF135B51),
                        onSelected: (v) => ss(() {
                          if (v) selectedChronicDiseases.add(e);
                          else selectedChronicDiseases.remove(e);
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // ── 3. نمط الحياة ──
              _sectionCard(
                title: 'نمط الحياة',
                icon: Icons.monitor_heart_outlined,
                children: [
                  _switchTile('هل تدخن؟', isSmoking,
                      (v) => ss(() => isSmoking = v)),
                  if (isSmoking)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: Text('(سيتم حفظ ذلك ضمن ملفك الطبي)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ),
                  _switchTile('هل تتناول كحول؟', isDrinking,
                      (v) => ss(() => isDrinking = v)),
                  _dropRow('مستوى النشاط البدني', activityOptions, activityLevel,
                      (v) => ss(() => activityLevel = v)),
                ],
              ),

              // ── 4. الأدوية والحساسية ──
              _sectionCard(
                title: 'الأدوية والحساسية',
                icon: Icons.medication_liquid,
                children: [
                  _inputTile('الأدوية الحالية', 'اسم الدواء والجرعة', medCtrl),
                  const SizedBox(height: 8),
                  _inputTile('الحساسية', 'نوع الحساسية (دواء/أكل)', allergyCtrl),
                ],
              ),

              // ── 5. الأعراض الحالية ──
              _sectionCard(
                title: 'الأعراض الحالية',
                icon: Icons.personal_injury_outlined,
                children: [
                  _inputTile('شكواك الحالية؟', 'مثلاً: صداع، تعب عام...', complaintCtrl, maxLines: 3),
                  const SizedBox(height: 8),
                  _inputTile('من امتى بدأت الأعراض؟', 'مثلاً: منذ يومين', onsetCtrl),
                  const SizedBox(height: 10),
                  Text('شدة الألم: $painScale / 10',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  Slider(
                    value: painScale.toDouble(), min: 1, max: 10, divisions: 9,
                    activeColor: const Color(0xFF135B51),
                    label: painScale.toString(),
                    onChanged: (v) => ss(() => painScale = v.toInt()),
                  ),
                  _dropRow('اتجاه الحالة', trendOptions, trend,
                      (v) => ss(() => trend = v)),
                ],
              ),

              // ── 6. الفحوصات والتحاليل ──
              _sectionCard(
                title: 'الفحوصات والتحاليل',
                icon: Icons.biotech_outlined,
                children: [
                  Obx(() {
                    final tests = recordController.currentRecord.value?.testResults ?? [];
                    return Column(children: [
                      ...tests.map((t) => ListTile(
                        dense: true,
                        title: Text(t.testName),
                        subtitle: Text(t.date != null
                            ? '${t.date!.day}/${t.date!.month}/${t.date!.year}' : ''),
                        trailing: t.resultImageUrl != null
                            ? const Icon(Icons.image, color: Colors.blue) : null,
                      )),
                      TextButton.icon(
                        onPressed: () => _showAddTestDialog(),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('رفع نتيجة تحليل/أشعة'),
                      ),
                    ]);
                  }),
                ],
              ),

              // ── زرار الحفظ ──
              const SizedBox(height: 8),
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: recordController.isLoading.value
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: const Text('حفظ السجل الطبي',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: recordController.isLoading.value ? null : () {
                    final uid = authController.currentUser.value?.uid;
                    if (uid == null) return;

                    final updatedRecord = MedicalRecordModel(
                      uid: uid,
                      bloodType: bloodType,
                      height: height,
                      weight: weight,
                      chronicDiseases: selectedChronicDiseases
                          .map((n) => ChronicDisease(name: n)).toList(),
                      lifestyle: Lifestyle(
                        isSmoking: isSmoking,
                        isDrinking: isDrinking,
                        activityLevel: activityLevel,
                      ),
                      currentMedications: medCtrl.text.trim().isEmpty
                          ? null : [Medication(name: medCtrl.text.trim())],
                      allergies: allergyCtrl.text.trim().isEmpty
                          ? null : [Allergy(name: allergyCtrl.text.trim())],
                      currentSymptoms: complaintCtrl.text.trim().isEmpty
                          ? null : CurrentSymptoms(
                              complaint: complaintCtrl.text.trim(),
                              onset: onsetCtrl.text.trim().isEmpty ? null : onsetCtrl.text.trim(),
                              painScale: painScale,
                              trend: trend,
                            ),
                      prescriptions: rec?.prescriptions,
                      testResults: rec?.testResults,
                      surgeries: rec?.surgeries,
                    );
                    recordController.saveMedicalRecord(updatedRecord);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135B51),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      });
    });
  }

  // ── helpers ──
  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: const Color(0xFF135B51)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: const Color(0xFF135B51),
      onChanged: onChanged,
    );
  }

  Widget _dropRow(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _sliderTile({
    required String label, required double value,
    required double min, required double max, required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Slider(value: value, min: min, max: max, divisions: divisions,
            activeColor: const Color(0xFF135B51), onChanged: onChanged),
      ],
    );
  }

  Widget _inputTile(String label, String hint, TextEditingController ctrl, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: const TextStyle(fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildFormSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: EtmanColors.primaryTeal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, Function(String?) onChanged, {String? initialValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          DropdownButtonFormField<String>(
            value: initialValue,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, Function(String) onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildTextField(String label, String hint, Function(String) onChanged, {bool hasVoice = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label, 
          hintText: hint, 
          labelStyle: const TextStyle(fontSize: 12),
          suffixIcon: hasVoice ? IconButton(
            icon: const Icon(Icons.mic, color: Colors.grey),
            onPressed: () => _simulateVoiceInput(label),
          ) : null,
        ),
      ),
    );
  }

  void _simulateVoiceInput(String fieldwork) {
    Get.snackbar(
      'Voice Input', 
      'جاري الاستماع لـ $fieldwork...', 
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Widget _buildCheckList(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Obx(() {
          final selected = recordController.currentRecord.value?.chronicDiseases?.map((e) => e.name).toList() ?? [];
          return Wrap(
            spacing: 8,
            children: items.map((e) {
              final isSelected = selected.contains(e);
              return FilterChip(
                label: Text(e), 
                selected: isSelected,
                selectedColor: EtmanColors.primaryTeal.withOpacity(0.2),
                onSelected: (val) {
                  List<ChronicDisease> current = List.from(recordController.currentRecord.value?.chronicDiseases ?? []);
                  if (val) {
                    if (!selected.contains(e)) current.add(ChronicDisease(name: e));
                  } else {
                    current.removeWhere((item) => item.name == e);
                  }
                  recordController.updateField(chronicDiseases: current);
                }
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool initial, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Switch(
          value: initial, 
          onChanged: onChanged, 
          activeColor: EtmanColors.primaryTeal
        ),
      ],
    );
  }

  // --- New Logic Dialogs ---

  void _showAddSurgeryDialog() {
    String type = '';
    String complications = '';
    Get.defaultDialog(
      title: 'إضافة عملية جراحية',
      content: Column(
        children: [
          TextField(decoration: const InputDecoration(labelText: 'نوع العملية'), onChanged: (v) => type = v),
          TextField(decoration: const InputDecoration(labelText: 'المضاعفات (إختياري)'), onChanged: (v) => complications = v),
        ],
      ),
      textConfirm: 'حفظ',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (type.isNotEmpty) {
          final current = recordController.currentRecord.value?.surgeries ?? [];
          final newList = List<Surgery>.from(current)..add(Surgery(type: type, date: DateTime.now(), complications: complications));
          recordController.updateField(surgeries: newList);
          Get.back();
        }
      }
    );
  }

  void _showAddTestDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text(
              'رفع نتيجة تحليل / أشعة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'اختر مصدر الصورة',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Get.back();
                      final file = await recordController.pickImage(ImageSource.camera);
                      if (file != null) {
                        await recordController.uploadTestResult('نتيجة تحليل', file);
                      } else {
                        Get.snackbar('تنبيه', 'لم يتم اختيار صورة', snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF6F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt, size: 34, color: Color(0xFF135B51)),
                          SizedBox(height: 8),
                          Text('الكاميرا', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF135B51))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Get.back();
                      final file = await recordController.pickImage(ImageSource.gallery);
                      if (file != null) {
                        await recordController.uploadTestResult('نتيجة تحليل', file);
                      } else {
                        Get.snackbar('تنبيه', 'لم يتم اختيار صورة', snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF6F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library, size: 34, color: Color(0xFF135B51)),
                          SizedBox(height: 8),
                          Text('المعرض', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF135B51))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _updateRecord({String? bloodType, double? height, double? weight}) {
    final uid = authController.currentUser.value?.uid;
    if (uid == null) return;
    
    final current = recordController.currentRecord.value;
    final updated = MedicalRecordModel(
      uid: uid,
      bloodType: bloodType ?? current?.bloodType,
      height: height ?? current?.height,
      weight: weight ?? current?.weight,
      // ... more fields can be added here
    );
    recordController.saveMedicalRecord(updated);
  }

  Future<void> _pickAndUploadPrescription() async {
    final file = await recordController.pickImage(ImageSource.gallery);
    if (file != null) {
      recordController.uploadPrescription(file);
    }
  }

  void _showEditNameDialog() {
    final currentName = authController.currentUser.value?.name ?? '';
    final TextEditingController nameController = TextEditingController(text: currentName);

    Get.defaultDialog(
      title: 'تعديل الاسم',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'أدخل الاسم الجديد',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EtmanColors.primaryTeal)),
          ),
          textAlign: TextAlign.center,
        ),
      ),
      textConfirm: 'حفظ',
      confirmTextColor: Colors.white,
      buttonColor: EtmanColors.primaryTeal,
      textCancel: 'إلغاء',
      cancelTextColor: EtmanColors.primaryTeal,
      onConfirm: () {
        final newName = nameController.text.trim();
        if (newName.isNotEmpty && newName != currentName) {
          authController.updateUserProfile(newName);
        }
        Get.back();
      },
    );
  }

  void _showEditProfileSheet() {
    // Basic account edit as before but with photo upload support
    Get.bottomSheet(Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('تغيير صورة الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt), 
            title: const Text('الكاميرا'), 
            onTap: () {}
          ),
          ListTile(
            leading: const Icon(Icons.photo_library), 
            title: const Text('المعرض'), 
            onTap: () {}
          ),
        ],
      ),
    ));
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        child: TextButton.icon(
          onPressed: () => _confirmLogout(),
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text(
            'تسجيل الخروج من الحساب',
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor: Colors.redAccent.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15), 
              side: BorderSide(color: Colors.redAccent.withOpacity(0.2))
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    Get.defaultDialog(
      title: 'تسجيل الخروج',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      textConfirm: 'نعم، اخرج',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        Get.back(); // Close dialog
        authController.logout();
      },
    );
  }
}
