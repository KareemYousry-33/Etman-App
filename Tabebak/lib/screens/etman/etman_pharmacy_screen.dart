import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'etman_colors.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/pharmacy_controller.dart';
import '../../controllers/medical_record_controller.dart';
import '../../models/pharmacy_model.dart';
import 'etman_pharmacy_details_screen.dart';

class EtmanPharmacyScreen extends StatefulWidget {
  const EtmanPharmacyScreen({Key? key}) : super(key: key);

  @override
  State<EtmanPharmacyScreen> createState() => _EtmanPharmacyScreenState();
}

class _EtmanPharmacyScreenState extends State<EtmanPharmacyScreen> {
  final LanguageController langController = Get.find<LanguageController>();
  final PharmacyController pharmacyController = Get.put(PharmacyController());
  final MedicalRecordController recordController = Get.put(MedicalRecordController());
  String _activeFilter = 'كل';
  String _searchQuery = '';
  String _currentLocationName = "تحديد موقعي للبحث بالأقرب";

  Future<void> _handleConsultantCall() async {
    final Uri telUrl = Uri.parse('tel:01013558197'); // WhatsApp/Phone number
    if (await canLaunchUrl(telUrl)) {
      await launchUrl(telUrl);
    } else {
      Get.snackbar('Error', 'Could not launch dialer');
    }
  }

  List<PharmacyModel> get _filteredPharmacies {
    List<PharmacyModel> filtered = pharmacyController.pharmacies.where((p) {
      final nameMatches = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      bool categoryMatches = true;
      if (_activeFilter != 'كل') {
        categoryMatches = p.specialty?.contains(_activeFilter) ?? false;
      }
      return nameMatches && categoryMatches;
    }).toList();

    // Sort by physical distance if available
    if (filtered.any((p) => p.distanceInMeters != null)) {
      filtered.sort((a, b) {
        if (a.distanceInMeters == null && b.distanceInMeters == null) return 0;
        if (a.distanceInMeters == null) return 1;
        if (b.distanceInMeters == null) return -1;
        return a.distanceInMeters!.compareTo(b.distanceInMeters!);
      });
    }
    
    return filtered;
  }

  Future<void> _fetchRealLocation() async {
    Get.dialog(const Center(child: CircularProgressIndicator(color: EtmanColors.primaryTeal)), barrierDismissible: false);
    
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.back();
      Get.snackbar('خطأ', 'يرجى تفعيل خدمات الموقع الجغرافي للجهاز', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.back();
        Get.snackbar('تحذير', 'تم رفض إذن الوصول للموقع!', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.back();
      Get.snackbar('خطأ', 'تم حظر صلاحيات الموقع نهائياً من الإعدادات', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          _currentLocationName = "موقعك: ${place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'الحي الحالي'}";
        }
      } catch (e) {
        _currentLocationName = "تم تحديد الموقع الجغرافي";
      }

      // Calculate distances mapping logic
      for (var pharmacy in pharmacyController.pharmacies) {
        if (pharmacy.latitude != 0.0 || pharmacy.longitude != 0.0) {
          pharmacy.distanceInMeters = Geolocator.distanceBetween(
             position.latitude, position.longitude, 
             pharmacy.latitude, pharmacy.longitude
          );
        }
      }

      setState(() {});
      Get.back();
      Get.snackbar(
        "تم تحديد الموقع 📍", 
        "تم جلب موقعك الفعلي ويتم الآن عرض الصيدليات الأقرب إليك بالمسافات",
        backgroundColor: EtmanColors.primaryTeal,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.back();
      Get.snackbar('خطأ', 'تعذر جلب الموقع الجغرافي حالياً', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  void initState() {
    super.initState();
    pharmacyController.fetchAllPharmacies();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Get.back(),
          ),
          title: GestureDetector(
            onTap: _fetchRealLocation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF00695C), size: 20),
                const SizedBox(width: 4),
                Text(
                  _currentLocationName.contains("تحديد") ? 'تحديد موقعي' : _currentLocationName.split(': ').last,
                  style: const TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.w900, fontSize: 16, decoration: TextDecoration.underline, decorationColor: Color(0xFF00695C)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---------- Search & Quick Actions Row ----------
                    Container(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25, top: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF5F3), // Light mint full block
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[400]!, width: 1.2),
                            ),
                            child: TextField(
                              textAlign: TextAlign.right,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: const InputDecoration(
                                hintText: "ابحث عن صيدليتك",
                                hintStyle: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                                prefixIcon: Icon(Icons.search, color: Colors.black54),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildActionItem(Icons.phone_in_talk_outlined, "تواصل معنا", onTap: _handleConsultantCall),
                              _buildActionItem(Icons.camera_alt_outlined, "صورة المنتج", onTap: () => _handleUpload(ImageSource.camera, "صورة المنتج")),
                              _buildActionItem(Icons.receipt_long_outlined, "روشتة/\nموافقة طبية", onTap: () => _handleUpload(ImageSource.gallery, "الروشتة")),
                            ],
                          ),
                        ],
                      ),
                    ),
    
                    const SizedBox(height: 25),
    
                    // ---------- Offers Carousel ----------
                    _buildOffersCarousel(),
    
                    const SizedBox(height: 25),
    
                    // ---------- Filters ----------
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("الصيدليات القريبة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildFilterChip("كل"),
                          const SizedBox(width: 10),
                          _buildFilterChip("صيدليات"),
                          const SizedBox(width: 10),
                          _buildFilterChip("مستحضرات تجميل"),
                        ],
                      ),
                    ),
    
                    const SizedBox(height: 15),
    
                    // ---------- Pharmacies List (Real Data) ----------
                    Obx(() {
                      if (pharmacyController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_filteredPharmacies.isEmpty) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('لا توجد صيدليات تطابق بحثك'),
                        ));
                      }
                      return Column(
                        children: _filteredPharmacies.map((p) => _buildPharmacyCard(p)).toList(),
                      );
                    }),
    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        height: 105, // Make them nice squares
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5F3), // same mint
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF00695C), width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00695C), size: 28),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF00695C))),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload(ImageSource source, String type) async {
    final file = await recordController.pickImage(source);
    if (file != null) {
      Get.snackbar('تم بنجاح', 'تم رفع $type بنجاح وسيتم إرسالها لأقرب صيدلية', backgroundColor: EtmanColors.primaryTeal, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _buildOffersCarousel() {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildOfferCard(
            "عرض 25%", 
            "على جميع مكملات الفيتامينات",
            "assets/medicine_vitamins_offer_1775718755238.png",
            const Color(0xFFFFD600),
          ),
          const SizedBox(width: 15),
          _buildOfferCard(
            "توصيل مجاني", 
            "على منتجات العنايه بالبشره اليوم", 
            "assets/skincare_medicine_offer_1775718789559.png",
            const Color(0xFF00B0FF),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(String badge, String title, String img, Color badgeColor) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: Colors.black.withOpacity(0.2))),
          Positioned(
            top: 15, right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          Positioned(
            bottom: 20, right: 20, left: 20,
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00695C) : Colors.white,
          borderRadius: BorderRadius.circular(25), // Pill shape
          border: Border.all(color: const Color(0xFF00695C), width: 1.2),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF00695C), fontWeight: FontWeight.w900, fontSize: 12)),
      ),
    );
  }

  Widget _buildPharmacyCard(PharmacyModel p) {
    return GestureDetector(
      onTap: () => Get.to(() => EtmanPharmacyDetailsScreen(pharmacy: p)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 75, height: 75,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: p.getImageWidget(fit: BoxFit.cover),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // starts right in RTL
                children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87), overflow: TextOverflow.ellipsis),
                  Text('${p.governorate} - ${p.city}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  if (p.distanceInMeters != null)
                    Text('تبعد ${(p.distanceInMeters! / 1000).toStringAsFixed(1)} كم عنك', style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text("Phone: ${p.phoneNumber}", style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold), textDirection: TextDirection.ltr),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_border, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(p.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft, // Left in RTL means physical Left side
                    child: ElevatedButton(
                      onPressed: () => Get.to(() => EtmanPharmacyDetailsScreen(pharmacy: p)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB2DFDB),
                        foregroundColor: const Color(0xFF00695C),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
                        minimumSize: const Size(60, 32),
                      ),
                      child: const Text("اطلب الان", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
