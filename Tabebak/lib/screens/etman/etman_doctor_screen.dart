import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:etman/screens/etman/etman_doctor_booking_screen.dart';
import 'package:etman/models/user_model.dart';
import 'package:etman/models/appointment_model.dart';
import 'package:etman/controllers/doctor_list_controller.dart';
import 'package:etman/controllers/patient_controller.dart';


// ─── Seed doctors ─────────────────────────────────────────────────────────────
const List<Map<String, dynamic>> _seedDoctors = [
  {'email': 'sara@etman.com',         'name': 'د. سارة محمد',    'specialty': 'رمد',          'price': 200.0, 'rating': 5.0, 'img': 'assets/doctor_f1.png',  'governorate': 'القاهرة',      'city': 'مدينة نصر',       'gender': 'female', 'title': 'استشاري'},
  {'email': 'amr@etman.com',          'name': 'د. عمرو محمود',   'specialty': 'مخ وأعصاب',   'price': 300.0, 'rating': 4.9, 'img': 'assets/doctor_m1.png',  'governorate': 'الجيزة',       'city': 'المهندسين',        'gender': 'male',   'title': 'أستاذ'},
  {'email': 'ahmed_ali@etman.com',    'name': 'د. أحمد علي',     'specialty': 'قلب وأوعية',  'price': 400.0, 'rating': 4.8, 'img': 'assets/doctor_m2.png',  'governorate': 'القاهرة',      'city': 'المعادي',          'gender': 'male',   'title': 'استشاري'},
  {'email': 'fatma_nour@etman.com',   'name': 'د. فاطمة نور',    'specialty': 'أطفال',        'price': 250.0, 'rating': 5.0, 'img': 'assets/doctor_f2.png',  'governorate': 'الإسكندرية',  'city': 'سموحة',            'gender': 'female', 'title': 'أستاذ'},
  {'email': 'karim_yousry@etman.com', 'name': 'د. كريم يسري',    'specialty': 'باطنة',        'price': 150.0, 'rating': 4.7, 'img': 'assets/doctor.png',     'governorate': 'القليوبية',   'city': 'شبرا الخيمة',     'gender': 'male',   'title': 'أخصائي'},
  {'email': 'hoda@etman.com',         'name': 'د. هدى صالح',     'specialty': 'عظام ومفاصل', 'price': 350.0, 'rating': 4.8, 'img': 'assets/doctor2.png',    'governorate': 'الشرقية',     'city': 'الزقازيق',         'gender': 'female', 'title': 'مدرس'},
  {'email': 'khaled@etman.com',       'name': 'د. خالد محمود',   'specialty': 'مخ وأعصاب',   'price': 400.0, 'rating': 4.9, 'img': 'assets/doctor3.png',    'governorate': 'القاهرة',      'city': 'القاهرة الجديدة', 'gender': 'male',   'title': 'أستاذ'},
  {'email': 'nour@etman.com',         'name': 'د. نور حسن',      'specialty': 'جلدية',        'price': 300.0, 'rating': 4.8, 'img': 'assets/doctor4.png',    'governorate': 'الجيزة',       'city': '6 أكتوبر',         'gender': 'female', 'title': 'استشاري'},
  {'email': 'mostafa@etman.com',      'name': 'د. مصطفى كمال',   'specialty': 'صدر وحساسية', 'price': 220.0, 'rating': 4.7, 'img': 'assets/doctor_m3.png',  'governorate': 'الإسكندرية',  'city': 'المنتزه',          'gender': 'male',   'title': 'أخصائي'},
  {'email': 'rana@etman.com',         'name': 'د. رنا علي',      'specialty': 'نساء وتوليد', 'price': 280.0, 'rating': 4.8, 'img': 'assets/doctor_f2.png',  'governorate': 'القاهرة',      'city': 'حلوان',             'gender': 'female', 'title': 'مدرس'},
  {'email': 'hassan@etman.com',       'name': 'د. حسن الشافعي',  'specialty': 'قلب وأوعية',  'price': 450.0, 'rating': 4.9, 'img': 'assets/doctor_m1.png',  'governorate': 'الشرقية',     'city': 'العاشر من رمضان', 'gender': 'male',   'title': 'أستاذ'},
  {'email': 'dina@etman.com',         'name': 'د. دينا يوسف',    'specialty': 'جلدية',        'price': 250.0, 'rating': 4.7, 'img': 'assets/doctor_f1.png',  'governorate': 'القليوبية',   'city': 'بنها',              'gender': 'female', 'title': 'استشاري'},
];

// ─── Categories ───────────────────────────────────────────────────────────────
class _Cat {
  final String label, specialty;
  final IconData icon;
  final Color color;
  const _Cat(this.label, this.specialty, this.icon, this.color);
}

const List<_Cat> _cats = [
  _Cat('الكل',   '',             Icons.apps,               Color(0xFFDFF5EF)),
  _Cat('قلب',    'قلب وأوعية',  Icons.favorite,            Color(0xFFFFD5D5)),
  _Cat('صدر',    'صدر وحساسية', Icons.air,                 Color(0xFFD5E8FF)),
  _Cat('أعصاب',  'مخ وأعصاب',  Icons.psychology,          Color(0xFFE8D5F5)),
  _Cat('عظام',   'عظام ومفاصل',Icons.accessible_forward,  Color(0xFFD5F5E3)),
  _Cat('أطفال',  'أطفال',       Icons.child_care,          Color(0xFFFFEDD5)),
  _Cat('جلدية',  'جلدية',       Icons.face,                Color(0xFFFFF0D5)),
  _Cat('رمد',    'رمد',         Icons.remove_red_eye,      Color(0xFFD5F0FF)),
  _Cat('نساء',   'نساء وتوليد', Icons.pregnant_woman,      Color(0xFFFFD5EC)),
];

// ─── Screen ────────────────────────────────────────────────────────────────────
class EtmanDoctorScreen extends StatefulWidget {
  final String role;
  final String title;

  const EtmanDoctorScreen({
    Key? key,
    this.role = 'doctor',
    this.title = 'احجز دكتور',
  }) : super(key: key);
  
  @override
  State<EtmanDoctorScreen> createState() => _EtmanDoctorScreenState();
}

class _EtmanDoctorScreenState extends State<EtmanDoctorScreen> {
  late final DoctorListController _favCtrl;
  late final PatientController _patientCtrl;
  final _searchCtrl = TextEditingController();
  String _selSpec = '';
  List<UserModel> _all = [];
  List<UserModel> _shown = [];
  bool _loading = true;
  String? _error;

  // ── Filter state ──
  String _sortBy          = ''; // '', 'rating', 'priceAsc', 'priceDesc'
  bool _facilityClinic    = false;
  bool _facilityHospital  = false;
  double _maxPrice        = 3000;
  String _locationLabel   = '';
  String _selectedGov     = '';
  String _selectedCity    = '';
  // New filters
  String _filterGender    = ''; // '', 'male', 'female'
  String _filterTitle     = ''; // '', 'أستاذ', 'استشاري', 'مدرس', 'أخصائي'
  String _filterAvail     = ''; // '', 'today', 'tomorrow', 'any'

  bool get _hasActiveFilter => _sortBy.isNotEmpty || _facilityClinic ||
      _facilityHospital || _maxPrice < 3000 ||
      _filterGender.isNotEmpty || _filterTitle.isNotEmpty ||
      _filterAvail.isNotEmpty;

  void _resetFilters() {
    _sortBy = ''; _facilityClinic = false; _facilityHospital = false;
    _maxPrice = 3000; _filterGender = ''; _filterTitle = ''; _filterAvail = '';
  }

  // Dynamic governorates/cities — loaded from Firestore, fallback to defaults
  Map<String, List<String>> _govCities = {
    'القاهرة':     ['مدينة نصر', 'المعادي', 'وسط البلد', 'حلوان', 'القاهرة الجديدة'],
    'الجيزة':      ['6 أكتوبر', 'الدقي', 'الهرم', 'المهندسين', 'فيصل'],
    'الإسكندرية': ['سيدي جابر', 'سموحة', 'المنتزه', 'العجمي', 'ميامي'],
    'القليوبية':  ['بنها', 'شبرا الخيمة', 'العبور', 'قليوب'],
    'الشرقية':    ['الزقازيق', 'العاشر من رمضان', 'بلبيس'],
  };

  @override
  void initState() {
    super.initState();
    _favCtrl = Get.isRegistered<DoctorListController>()
        ? Get.find<DoctorListController>()
        : Get.put(DoctorListController());
    
    _patientCtrl = Get.isRegistered<PatientController>()
        ? Get.find<PatientController>()
        : Get.put(PatientController());

    _loadDoctors();
    _loadGovCities();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  /// Loads governorates and their cities from Firestore.
  /// Merges with local defaults so the list never appears empty.
  Future<void> _loadGovCities() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('governorates').get();
      if (snap.docs.isEmpty) return;
      final Map<String, List<String>> loaded = {};
      for (final doc in snap.docs) {
        final name   = (doc.data()['name'] ?? doc.id) as String;
        final cities = List<String>.from(doc.data()['cities'] ?? []);
        loaded[name] = cities;
      }
      // Merge: remote wins; add any local govs not yet in Firestore
      final merged = Map<String, List<String>>.from(_govCities);
      loaded.forEach((g, cities) {
        if (merged.containsKey(g)) {
          // union of cities
          final all = {...merged[g]!, ...cities}.toList();
          merged[g] = all;
        } else {
          merged[g] = cities;
        }
      });
      if (mounted) setState(() => _govCities = merged);
    } catch (_) { /* keep defaults on error */ }
  }

  Future<void> _loadDoctors() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    try {
      final fs = FirebaseFirestore.instance;

      // ── 1. Seed missing doctors with governorate/city ──
      if (widget.role == 'doctor') {
        for (final d in _seedDoctors) {
          final id = d['email'] as String;
          final snap = await fs.collection('users').doc(id).get();
          if (!snap.exists) {
            final rating = double.tryParse(d['rating'].toString()) ?? 5.0;
            await fs.collection('users').doc(id).set({
              'email': id, 'name': d['name'], 'role': 'doctor',
              'specialty': d['specialty'],
              'price': double.tryParse(d['price'].toString()) ?? 200.0,
              'rating': rating, 'ratingCount': 150, 'ratingSum': rating * 150,
              'imageUrl': d['img'],
              'governorate': d['governorate'] ?? '',
              'city': d['city'] ?? '',
              'gender': d['gender'] ?? 'male',
              'title': d['title'] ?? '',
              'availability': [],
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      }

      // ── 2. Fetch WITHOUT orderBy (sort locally to avoid index error) ──
      final snap = await fs
          .collection('users')
          .where('role', isEqualTo: widget.role)
          .get();

      final docs = snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
      // Sort by rating locally
      docs.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

      if (mounted) setState(() { _all = docs; _shown = docs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = _all.where((d) {
      final specOk   = _selSpec.isEmpty || (d.specialty ?? '').contains(_selSpec);
      final qOk      = q.isEmpty || d.name.toLowerCase().contains(q) ||
                       (d.specialty ?? '').toLowerCase().contains(q);
      final priceOk  = (d.price ?? 0) <= _maxPrice;
      final locOk    = _selectedCity.isEmpty ||
          (d.city ?? '').contains(_selectedCity) ||
          (d.governorate ?? '').contains(_selectedCity) ||
          (d.address ?? '').contains(_selectedCity);
      // gender: infer from name - female Arabic names end with ة or contain فاطمة،سارة،هدى،نور،رنا،دينا،ريم etc.
      final isFemale = d.name.contains('ة ') || d.name.endsWith('ة') ||
          RegExp(r'فاطم|سارة|هدى|نور|رنا|دينا|ريم|منى|إيمان|مريم|سمر|ليلى|نهاد|شيماء|خلود|أميرة|دنيا').hasMatch(d.name);
      final genderOk = _filterGender.isEmpty ||
          (_filterGender == 'female' && isFemale) ||
          (_filterGender == 'male'   && !isFemale);
      final titleOk = true; // title filter removed
      return specOk && qOk && priceOk && locOk && genderOk && titleOk;
    }).toList();

    switch (_sortBy) {
      case 'rating':    list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0)); break;
      case 'priceAsc':  list.sort((a, b) => (a.price  ?? 0).compareTo(b.price  ?? 0)); break;
      case 'priceDesc': list.sort((a, b) => (b.price  ?? 0).compareTo(a.price  ?? 0)); break;
      default: break;
    }
    setState(() => _shown = list);
  }


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,   // ✅ RTL
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.only(top: 55, right: 6, left: 20, bottom: 16),
              decoration: const BoxDecoration(color: Color(0xFFCBEAEA)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Get.back(),
                      ),
                      Text(widget.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const Spacer(),
                      if (_loading)
                        const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF135B51))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search bar + filter/location buttons
                  Row(
                    children: [
                      // Filter Button
                      GestureDetector(
                        onTap: _showFilterSheet,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _hasActiveFilter ? const Color(0xFF135B51) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: _hasActiveFilter ? Colors.white : Colors.black54,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Search Field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 14),
                                child: Icon(Icons.search, color: Colors.grey),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  onChanged: (_) => _filter(),
                                  decoration: const InputDecoration(
                                    hintText: 'ابحث بالاسم أو التخصص...',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                ),
                              ),
                              if (_searchCtrl.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                  onPressed: () { _searchCtrl.clear(); _filter(); },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Location Button
                      GestureDetector(
                        onTap: _showLocationSheet,
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: _locationLabel.isNotEmpty ? const Color(0xFF135B51) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                          ),
                          child: Icon(
                            _locationLabel.isNotEmpty ? Icons.location_on : Icons.location_on_outlined,
                            color: _locationLabel.isNotEmpty ? Colors.white : Colors.black54,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Location label under search if set
                  if (_locationLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 13, color: Color(0xFF135B51)),
                          const SizedBox(width: 4),
                          Text(_locationLabel,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF135B51), fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() { _locationLabel = ''; _selectedCity = ''; _selectedGov = ''; });
                              _filter();
                            },
                            child: const Icon(Icons.close, size: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Recent Bookings Section (NEW) ──
            _buildRecentBookings(),

            // ── Category chips ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _cats.map((cat) {
                    final sel = _selSpec == cat.specialty;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selSpec = sel ? '' : cat.specialty);
                        _filter();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF135B51) : cat.color,
                          borderRadius: BorderRadius.circular(20),
                          border: sel ? null : Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 15, color: sel ? Colors.white : Colors.black54),
                            const SizedBox(width: 5),
                            Text(cat.label,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                                    color: sel ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Count bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selSpec.isEmpty ? 'كل الأطباء' : 'تخصص: $_selSpec',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  Text('${_shown.length} دكتور',
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // ── List ──
            Expanded(
              child: _error != null
                  ? _errorWidget()
                  : _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E8C78)))
                      : _shown.isEmpty
                          ? _emptyWidget()
                          : RefreshIndicator(
                              onRefresh: _loadDoctors,
                              color: const Color(0xFF1E8C78),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                                itemCount: _shown.length,
                                itemBuilder: (_, i) => _card(_shown[i], i),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorWidget() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
      const SizedBox(height: 12),
      Text(_error ?? 'خطأ', style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _loadDoctors,
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8C78)),
      ),
    ]),
  );

  // ══════════════════ FILTER BOTTOM SHEET ══════════════════
  void _showFilterSheet() {
    String tmpSort     = _sortBy;
    bool   tmpClinic   = _facilityClinic;
    bool   tmpHospital = _facilityHospital;
    double tmpPrice    = _maxPrice;
    String tmpGender   = _filterGender;
    String tmpTitle    = _filterTitle;
    String tmpAvail    = _filterAvail;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('تحديد بحثك',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        TextButton(
                          onPressed: () => setSheet(() {
                            tmpSort = ''; tmpClinic = false; tmpHospital = false;
                            tmpPrice = 3000; tmpGender = ''; tmpTitle = ''; tmpAvail = '';
                          }),
                          child: const Text('إلغاء الترشيحات',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // ── المنشأة ──
                    const Text('المنشأة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _filterToggleBtn(
                        label: 'مستشفى', icon: Icons.local_hospital_outlined,
                        active: tmpHospital,
                        onTap: () => setSheet(() => tmpHospital = !tmpHospital),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _filterToggleBtn(
                        label: 'عيادة', icon: Icons.medical_services_outlined,
                        active: tmpClinic,
                        onTap: () => setSheet(() => tmpClinic = !tmpClinic),
                      )),
                    ]),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // ── سعر الكشف ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('سعر الكشف', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                        Text('حتى ${tmpPrice.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(color: Color(0xFF135B51), fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Slider(
                      value: tmpPrice, min: 0, max: 3000, divisions: 30,
                      activeColor: const Color(0xFF135B51),
                      inactiveColor: const Color(0xFFCBEAEA),
                      onChanged: (v) => setSheet(() => tmpPrice = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('0 ج.م', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('3000 ج.م', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // ── المواعيد المتاحة ──
                    const Text('المواعيد المتاحة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _filterToggleBtn(
                        label: 'أي يوم', icon: Icons.calendar_today_outlined,
                        active: tmpAvail == 'any',
                        onTap: () => setSheet(() => tmpAvail = tmpAvail == 'any' ? '' : 'any'),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _filterToggleBtn(
                        label: 'اليوم', icon: Icons.today_outlined,
                        active: tmpAvail == 'today',
                        onTap: () => setSheet(() => tmpAvail = tmpAvail == 'today' ? '' : 'today'),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _filterToggleBtn(
                        label: 'غداً', icon: Icons.event_outlined,
                        active: tmpAvail == 'tomorrow',
                        onTap: () => setSheet(() => tmpAvail = tmpAvail == 'tomorrow' ? '' : 'tomorrow'),
                      )),
                    ]),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // ── النوع ──
                    const Text('النوع', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _filterToggleBtn(
                        label: 'دكتور', icon: Icons.male,
                        active: tmpGender == 'male',
                        onTap: () => setSheet(() => tmpGender = tmpGender == 'male' ? '' : 'male'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _filterToggleBtn(
                        label: 'دكتورة', icon: Icons.female,
                        active: tmpGender == 'female',
                        onTap: () => setSheet(() => tmpGender = tmpGender == 'female' ? '' : 'female'),
                      )),
                    ]),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // ── الترتيب ──
                    const Text('الترتيب', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    ...[
                      ('rating',    'الأعلى تقييماً', Icons.star_outline),
                      ('priceAsc',  'الأقل سعراً',    Icons.arrow_upward),
                      ('priceDesc', 'الأعلى سعراً',   Icons.arrow_downward),
                    ].map((t) => GestureDetector(
                      onTap: () => setSheet(() => tmpSort = tmpSort == t.$1 ? '' : t.$1),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: tmpSort == t.$1 ? const Color(0xFFEBF6F5) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: tmpSort == t.$1 ? const Color(0xFF135B51) : Colors.grey[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(t.$3, size: 18,
                                color: tmpSort == t.$1 ? const Color(0xFF135B51) : Colors.black54),
                            const SizedBox(width: 10),
                            Text(t.$2, style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: tmpSort == t.$1 ? const Color(0xFF135B51) : Colors.black87)),
                            const Spacer(),
                            if (tmpSort == t.$1)
                              const Icon(Icons.check_circle, color: Color(0xFF135B51), size: 18),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _sortBy          = tmpSort;
                            _facilityClinic  = tmpClinic;
                            _facilityHospital= tmpHospital;
                            _maxPrice        = tmpPrice;
                            _filterGender    = tmpGender;
                            _filterTitle     = tmpTitle;
                            _filterAvail     = tmpAvail;
                          });
                          _filter();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF135B51),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('موافق',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterToggleBtn({
    required String label, required IconData icon,
    required bool active, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF135B51) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? const Color(0xFF135B51) : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : Colors.black54),
            const SizedBox(width: 5),
            Flexible(child: Text(label, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: active ? Colors.white : Colors.black87,
            ), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  // ══════════════════ LOCATION BOTTOM SHEET ══════════════════
  void _showLocationSheet() {
    String tmpGov  = _selectedGov;
    String tmpCity = _selectedCity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('تحديد الموقع',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),

                  // GPS Button
                  GestureDetector(
                    onTap: () async {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      await _detectLocation();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF6F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF135B51)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.my_location, color: Color(0xFF135B51)),
                          SizedBox(width: 10),
                          Text('تحديد موقعي تلقائياً 📍',
                              style: TextStyle(
                                  color: Color(0xFF135B51),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(child: Text('أو', style: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 16),

                  // Governorate Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: tmpGov.isEmpty ? null : tmpGov,
                        hint: const Text('اختر المحافظة'),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: _govCities.keys.map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g, style: const TextStyle(fontWeight: FontWeight.w600)),
                        )).toList(),
                        onChanged: (v) => setSheet(() { tmpGov = v!; tmpCity = ''; }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // City Dropdown
                  if (tmpGov.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tmpCity.isEmpty ? null : tmpCity,
                          hint: const Text('اختر المدينة'),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: (_govCities[tmpGov] ?? []).map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
                          )).toList(),
                          onChanged: (v) => setSheet(() => tmpCity = v!),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Confirm
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: tmpGov.isEmpty ? null : () {
                        final label = tmpCity.isNotEmpty ? '$tmpGov - $tmpCity' : tmpGov;
                        setState(() {
                          _selectedGov  = tmpGov;
                          _selectedCity = tmpCity.isNotEmpty ? tmpCity : tmpGov;
                          _locationLabel = label;
                        });
                        _filter();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135B51),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('عرض النتائج',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _detectLocation() async {
    bool dialogOpen = false;
    try {
      // Check & request permission first before showing dialog
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('خطأ', 'يرجى تفعيل صلاحية الموقع من الإعدادات',
            backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
      // Only show dialog after permission is granted
      if (!mounted) return;
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Color(0xFF135B51))),
        barrierDismissible: false,
      );
      dialogOpen = true;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (dialogOpen && (Get.isDialogOpen ?? false)) { Get.back(); dialogOpen = false; }
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p     = placemarks.first;
        final city  = p.locality ?? p.subAdministrativeArea ?? '';
        final gov   = p.administrativeArea ?? '';
        final label = city.isNotEmpty ? '$gov - $city' : gov;
        setState(() {
          _selectedGov   = gov;
          _selectedCity  = city.isNotEmpty ? city : gov;
          _locationLabel = label.isNotEmpty ? 'موقعك: $label' : 'تم تحديد موقعك';
        });
        _filter();
        Get.snackbar('📍 تم التحديد', 'يتم عرض الأطباء الأقرب إليك',
            backgroundColor: const Color(0xFF135B51), colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (dialogOpen && (Get.isDialogOpen ?? false)) Get.back();
      if (mounted) {
        Get.snackbar('خطأ', 'تعذر تحديد الموقع. تأكد من تشغيل GPS',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }


  Widget _buildRecentBookings() {
    return Obx(() {
      final upcoming = _patientCtrl.myAppointments.where((a) =>
          (a.status == AppointmentStatus.pending || a.status == AppointmentStatus.approved) && 
          a.providerRole == widget.role).toList();

      if (upcoming.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(color: Color(0xFFEBF6F5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Text('حجوزاتك الحالية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF135B51))),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: upcoming.length,
                itemBuilder: (context, i) {
                  final app = upcoming[i];
                  return Container(
                    width: 250,
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: app.doctorImage.startsWith('http')
                              ? NetworkImage(app.doctorImage) as ImageProvider
                              : AssetImage(app.doctorImage),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(app.doctorName,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('${app.timeSlot}',
                                  style: const TextStyle(color: Color(0xFF1E8C78), fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(app.status == AppointmentStatus.approved ? 'مقبول' : 'قيد الانتظار',
                                    style: const TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _emptyWidget() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.search_off, size: 60, color: Colors.grey),
      const SizedBox(height: 12),
      const Text('لا يوجد أطباء بهذا البحث',
          style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextButton.icon(
        onPressed: () {
          _searchCtrl.clear();
          setState(() {
            _selSpec = '';
            _resetFilters();
            _selectedCity = '';
            _selectedGov  = '';
            _locationLabel = '';
          });
          _filter();
        },
        icon: const Icon(Icons.apps, color: Color(0xFF1E8C78)),
        label: const Text('عرض الكل',
            style: TextStyle(color: Color(0xFF1E8C78), fontWeight: FontWeight.bold)),
      ),
    ]),
  );

  Widget _card(UserModel doc, int index) {
    final img = doc.photoUrl ?? 'assets/doctor.png';
    final isAvail = index % 3 != 2;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F5F4), borderRadius: BorderRadius.circular(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            backgroundImage: img.startsWith('http')
                ? NetworkImage(img) as ImageProvider
                : AssetImage(img),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(doc.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (isAvail)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFFCBEAEA), borderRadius: BorderRadius.circular(10)),
                      child: const Text('متاح',
                          style: TextStyle(color: Color(0xFF1F6B62), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ]),
                const SizedBox(height: 3),
                Text(doc.specialty ?? 'طبيب عام',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(children: [
                  // ⭐ Favorite toggle: white outline → yellow filled
                  Obx(() {
                    final fav = _favCtrl.isFavorite(doc.uid);
                    return GestureDetector(
                      onTap: () => _favCtrl.toggleFavorite(doc.uid),
                      child: Icon(
                        fav ? Icons.star : Icons.star_border,
                        color: fav ? Colors.amber : Colors.white,
                        size: 24,
                        shadows: const [Shadow(color: Colors.grey, blurRadius: 4)],
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(doc.rating?.toStringAsFixed(1) ?? '4.9',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFD9EDFF), borderRadius: BorderRadius.circular(10)),
                    child: Text('${doc.price?.toStringAsFixed(0) ?? "200"} ج.م',
                        style: const TextStyle(color: Color(0xFF2365A3), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('اضغط للحجز', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ElevatedButton(
                      onPressed: () => Get.to(() => EtmanDoctorBookingScreen(doctorData: doc)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135B51),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        minimumSize: const Size(0, 36),
                        elevation: 0,
                      ),
                      child: const Text('احجز الآن',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
