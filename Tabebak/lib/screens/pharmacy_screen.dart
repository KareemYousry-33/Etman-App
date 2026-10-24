import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({Key? key}) : super(key: key);

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPharmacies();
  }

  Future<void> _fetchPharmacies() async {
    setState(() => _isLoading = true);
    try {
      // Fetch from users collection (pharmacies added by admin)
      final QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'pharmacy')
          .get();

      final List<Map<String, dynamic>> fromUsers = usersSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'address': data['location'] ?? '${data['city'] ?? ''}, ${data['governorate'] ?? ''}',
          'phoneNumber': data['phoneNumber'],
          'imageUrl': data['photoUrl'] ?? data['imageUrl'],
          'googleMapsLink': data['googleMapsLink'],
          'facebookUrl': data['facebookUrl'],
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
          'bio': data['bio'] ?? '',
          'governorate': data['governorate'],
          'city': data['city'],
          'source': 'users',
        };
      }).toList();

      // Merge with hard-coded pharmacies that don't exist in users yet
      final List<Map<String, dynamic>> hardCoded = _getHardCodedPharmacies();
      
      // Add hard-coded ones that don't have an equivalent in users
      final userNames = fromUsers.map((p) => p['name'].toString().toLowerCase()).toSet();
      final uniqueHardCoded = hardCoded.where((p) => 
        !userNames.contains(p['name'].toString().toLowerCase())).toList();

      setState(() {
        _pharmacies = [...fromUsers, ...uniqueHardCoded];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _pharmacies = _getHardCodedPharmacies();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getHardCodedPharmacies() {
    return [
      {
        'id': 'hc_1',
        'name': 'El Ezaby Pharmacy',
        'address': 'برج الفيروز - ش دكتور طلبة عويضة - بجوار رنين, شيبة النكارية، قسم ثان',
        'phoneNumber': '02 35317347',
        'imageUrl': 'https://lh3.googleusercontent.com/p/AF1QipO9_GYHFO0GRjF6qp1_RHt9OjiT6QyEmq6Q27Dt=s1360-w1360-h1020-rw',
        'facebookUrl': 'https://www.facebook.com/share/15BpuN5qar/',
        'googleMapsLink': 'https://maps.google.com/?q=31.2057,29.9244',
        'rating': 4.9,
        'bio': 'أكبر سلسلة صيدليات في مصر، نقدم خدمة متميزة على مدار الساعة.',
        'source': 'local',
      },
      {
        'id': 'hc_2',
        'name': 'صيدلية د/ إيمان العزب',
        'address': 'شارع كلية الطب، شيبة النكارية، مركز الزقازيق، محافظة الشرقية',
        'phoneNumber': '2356592',
        'imageUrl': 'https://lh3.googleusercontent.com/gps-cs-s/AC9h4nqXUVYKc3p-U4GO1hND-oxZR6XCVWLjbkXfqGryZmodRu42DjjYAsLOV29uGYjjVDjhq5hj6TKOuBgJ6vgFUaqOBRgvd6BSdetO6bjv6ytlhDpm52f7GcXBZj6Rg91DleFawKOSvQ=s1360-w1360-h1020-rw',
        'facebookUrl': 'https://www.facebook.com/p/%D8%B5%D9%8A%D8%AF%D9%84%D9%8A%D9%87-%D8%AF-%D8%A7%D9%8A%D9%85%D8%A7%D9%86-100064013800861/',
        'googleMapsLink': 'https://maps.google.com/?q=31.2196,29.9426',
        'rating': 4.8,
        'bio': 'رعاية صحية متكاملة وأدوية ومستحضرات تجميل عالمية.',
        'source': 'local',
      },
      {
        'id': 'hc_3',
        'name': 'صيدلية طيبة',
        'address': 'شارع أحمد ماهر، يوسف، قسم ثان الزقازيق، محافظة الشرقية',
        'phoneNumber': '010 60616209',
        'imageUrl': 'https://lh3.googleusercontent.com/p/AF1QipMCLE6faOwzhjJ0GMd3YwHWkS1rT85kvKf223ah=s1360-w1360-h1020-rw',
        'facebookUrl': 'https://www.facebook.com/groups/Ehab.Ghareeb/',
        'googleMapsLink': 'https://maps.google.com/?q=31.2060,29.9401',
        'rating': 4.7,
        'bio': 'صيدلية محلية موثوقة في خدمة المنطقة.',
        'source': 'local',
      },
      {
        'id': 'hc_4',
        'name': 'صيدلية أسامة عثمان',
        'address': 'شارع بيتزا اسكندرية - بجوار نور الشام',
        'phoneNumber': '055 2377330',
        'imageUrl': 'https://lh3.googleusercontent.com/gps-cs-s/AC9h4nq4q7uR-Xbz_OxyGzDvq7qROqP5tgYMGv8L87V1kzKn0CLjwEOjQK4ZNZlqSU5KXFWH1RxyDjZ7HR7eWgWon7N7Mtdx6G2M0RmUyc3UXhKCVu3-VyBEL1kRN0Lybx9dGatAcl7e=s1360-w1360-h1020-rw',
        'googleMapsLink': 'https://maps.google.com/?q=31.2099,29.9319',
        'rating': 4.7,
        'bio': 'نسعى دائماً لتوفير احتياجاتكم الدوائية بأسرع وقت.',
        'source': 'local',
      },
      {
        'id': 'hc_5',
        'name': 'صيدلية السعد الكبرى',
        'address': 'ميدان القومية، الصيادين، قسم ثان الزقازيق، محافظة الشرقية',
        'phoneNumber': '010 33033045',
        'imageUrl': 'https://lh3.googleusercontent.com/gps-cs-s/AC9h4nrvOKo4EM6HzwWCGQZgB_7gFtWd6mNMflsFg32-A-Y3gHVE7RBNnLZwihr1NF3uvIOM0TOOdcH3qgb5JDlAmk_aB_kp2he9HoC6wZAHfG92NT0NjeIC3SrPd_CkZ8ajy7caLAcgFQ=s1360-w1360-h1020-rw',
        'facebookUrl': 'https://www.facebook.com/ElSa3dPharmacy/?locale=ar_AR',
        'googleMapsLink': 'https://maps.google.com/?q=31.2125,29.9153',
        'rating': 4.8,
        'bio': 'الصيدلية الكبرى في خدمتكم.',
        'source': 'local',
      },
    ];
  }

  Future<void> _openMap(String? mapsLink, double? lat, double? lng) async {
    String urlStr;
    if (mapsLink != null && mapsLink.isNotEmpty) {
      urlStr = mapsLink;
    } else if (lat != null && lng != null) {
      urlStr = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    } else {
      return;
    }
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openFacebook(String? facebookUrl) async {
    if (facebookUrl == null || facebookUrl.isEmpty) return;
    final uri = Uri.parse(facebookUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        appBar: AppBar(
          title: const Text('الصيدليات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF135B51),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _fetchPharmacies,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E8C78)))
            : _pharmacies.isEmpty
                ? const Center(child: Text('لا توجد صيدليات متاحة حالياً'))
                : RefreshIndicator(
                    onRefresh: _fetchPharmacies,
                    color: const Color(0xFF1E8C78),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pharmacies.length,
                      itemBuilder: (context, index) {
                        final pharmacy = _pharmacies[index];
                        return _buildPharmacyCard(pharmacy);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildPharmacyCard(Map<String, dynamic> pharmacy) {
    final imageUrl = pharmacy['imageUrl'] as String?;
    final rating = (pharmacy['rating'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(),
                  )
                : _buildImageFallback(),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pharmacy['name'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (rating > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          Text(' ${rating.toStringAsFixed(1)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if ((pharmacy['address'] as String?)?.isNotEmpty == true)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF1E8C78)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pharmacy['address'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                if ((pharmacy['phoneNumber'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF1E8C78)),
                      const SizedBox(width: 4),
                      Text(pharmacy['phoneNumber'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
                if ((pharmacy['bio'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(pharmacy['bio'] ?? '',
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.location_on, size: 16, color: Colors.white),
                        label: const Text('الخريطة', style: TextStyle(color: Colors.white, fontSize: 13)),
                        onPressed: () => _openMap(pharmacy['googleMapsLink'], null, null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF135B51),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if ((pharmacy['facebookUrl'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.facebook, size: 16, color: Colors.white),
                          label: const Text('فيسبوك', style: TextStyle(color: Colors.white, fontSize: 13)),
                          onPressed: () => _openFacebook(pharmacy['facebookUrl']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B5998),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      width: double.infinity,
      height: 160,
      color: const Color(0xFFE8F5F3),
      child: const Center(
        child: Icon(Icons.local_pharmacy_rounded, size: 60, color: Color(0xFF1E8C78)),
      ),
    );
  }
}
