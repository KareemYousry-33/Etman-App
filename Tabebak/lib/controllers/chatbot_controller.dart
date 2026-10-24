import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Message Model ────────────────────────────────────────────────────────────
class Message {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  /// Optional list of doctor/lab cards to display inline
  final List<Map<String, dynamic>>? cards;

  Message({
    required this.text,
    required this.isUserMessage,
    DateTime? timestamp,
    this.cards,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ─── Symptom → Specialty Knowledge Base ──────────────────────────────────────
class _SymptomKnowledge {
  // كل كلمة مفتاحية (عربي/إنجليزي) → قائمة تخصصات
  static const Map<String, List<String>> symptomToSpecialties = {
    // ─ قلب وأوعية
    'قلب': ['قلب وأوعية دموية', 'قلب'],
    'صدر': ['قلب وأوعية دموية', 'صدر وحساسية'],
    'ضغط': ['قلب وأوعية دموية'],
    'heart': ['قلب وأوعية دموية'],
    'chest': ['قلب وأوعية دموية', 'صدر وحساسية'],
    'ضربات': ['قلب وأوعية دموية'],
    'خفقان': ['قلب وأوعية دموية'],

    // ─ مخ وأعصاب
    'صداع': ['مخ وأعصاب'],
    'دوخة': ['مخ وأعصاب'],
    'دوار': ['مخ وأعصاب'],
    'نسيان': ['مخ وأعصاب', 'نفسية وعلاج نفسي'],
    'شلل': ['مخ وأعصاب'],
    'رعشة': ['مخ وأعصاب'],
    'headache': ['مخ وأعصاب'],
    'migraine': ['مخ وأعصاب'],
    'نصف رأس': ['مخ وأعصاب'],
    'تنميل': ['مخ وأعصاب', 'عظام ومفاصل'],

    // ─ عيون
    'عين': ['رمد', 'عيون'],
    'عيون': ['رمد', 'عيون'],
    'نظر': ['رمد', 'عيون'],
    'بصر': ['رمد', 'عيون'],
    'eye': ['رمد', 'عيون'],

    // ─ أذن وأنف وحنجرة
    'أذن': ['أنف وأذن وحنجرة'],
    'انف': ['أنف وأذن وحنجرة'],
    'أنف': ['أنف وأذن وحنجرة'],
    'حلق': ['أنف وأذن وحنجرة'],
    'بلع': ['أنف وأذن وحنجرة'],
    'صوت': ['أنف وأذن وحنجرة'],
    'سمع': ['أنف وأذن وحنجرة'],

    // ─ جلدية
    'جلد': ['جلدية وتجميل', 'جلدية'],
    'حبوب': ['جلدية وتجميل', 'جلدية'],
    'طفح': ['جلدية وتجميل', 'جلدية'],
    'حكة': ['جلدية وتجميل', 'جلدية'],
    'شعر': ['جلدية وتجميل', 'جلدية'],
    'skin': ['جلدية وتجميل', 'جلدية'],
    'acne': ['جلدية وتجميل', 'جلدية'],

    // ─ باطنة / معدة
    'معدة': ['باطنة', 'جهاز هضمي'],
    'بطن': ['باطنة', 'جهاز هضمي'],
    'قولون': ['جهاز هضمي'],
    'اسهال': ['باطنة'],
    'إسهال': ['باطنة'],
    'امساك': ['باطنة', 'جهاز هضمي'],
    'غثيان': ['باطنة'],
    'كبد': ['باطنة', 'جهاز هضمي'],
    'حرقة': ['باطنة', 'جهاز هضمي'],
    'stomach': ['باطنة', 'جهاز هضمي'],
    'اكل': ['باطنة'],
    'هضم': ['باطنة', 'جهاز هضمي'],

    // ─ عظام ومفاصل
    'عظام': ['عظام ومفاصل'],
    'مفاصل': ['عظام ومفاصل'],
    'ظهر': ['عظام ومفاصل'],
    'ركبة': ['عظام ومفاصل'],
    'كتف': ['عظام ومفاصل'],
    'bone': ['عظام ومفاصل'],
    'كسر': ['عظام ومفاصل'],
    'خلع': ['عظام ومفاصل'],

    // ─ أطفال
    'طفل': ['أطفال وحديثي الولادة', 'أطفال'],
    'رضيع': ['أطفال وحديثي الولادة', 'أطفال'],
    'ولادة': ['أطفال وحديثي الولادة', 'نساء وتوليد'],
    'children': ['أطفال وحديثي الولادة', 'أطفال'],

    // ─ نساء وتوليد
    'نساء': ['نساء وتوليد'],
    'حمل': ['نساء وتوليد'],
    'دورة': ['نساء وتوليد'],
    'رحم': ['نساء وتوليد'],
    'مبيض': ['نساء وتوليد'],

    // ─ صدر وحساسية
    'سعال': ['صدر وحساسية'],
    'كحة': ['صدر وحساسية'],
    'ربو': ['صدر وحساسية'],
    'تنفس': ['صدر وحساسية'],
    'حساسية': ['صدر وحساسية', 'جلدية'],
    'cough': ['صدر وحساسية'],

    // ─ سكري
    'سكر': ['باطنة', 'سكري وغدد'],
    'سكري': ['سكري وغدد'],
    'انسولين': ['سكري وغدد'],
    'diabetes': ['سكري وغدد'],

    // ─ تحاليل / معامل
    'تحليل': ['تحاليل'],
    'تحاليل': ['تحاليل'],
    'دم': ['تحاليل'],
    'هرمون': ['تحاليل', 'سكري وغدد'],
    'بول': ['تحاليل'],
    'أشعة': ['أشعة'],
    'اشعة': ['أشعة'],
    'سونار': ['أشعة'],
    'رنين': ['أشعة'],
    'xray': ['أشعة'],

    // ─ نفسية
    'قلق': ['نفسية وعلاج نفسي'],
    'اكتئاب': ['نفسية وعلاج نفسي'],
    'توتر': ['نفسية وعلاج نفسي'],
    'نوم': ['نفسية وعلاج نفسي'],
    'anxiety': ['نفسية وعلاج نفسي'],

    // ─ كلى / مسالك
    'كلى': ['مسالك بولية', 'كلى'],
    'بروستاتا': ['مسالك بولية'],
    'مثانة': ['مسالك بولية'],
    'kidney': ['مسالك بولية', 'كلى'],
  };

  // تخصص → وصف + نصيحة
  static const Map<String, String> specialtyInfo = {
    'قلب وأوعية دموية': 'يُعالج أمراض القلب والأوعية الدموية وضغط الدم.',
    'مخ وأعصاب': 'يُعالج الصداع والدوخة والأمراض العصبية.',
    'رمد': 'يُعالج أمراض العيون ومشاكل الرؤية.',
    'عيون': 'يُعالج أمراض العيون ومشاكل الرؤية.',
    'أنف وأذن وحنجرة': 'يُعالج مشاكل الأذن والأنف والحنجرة والسمع.',
    'جلدية وتجميل': 'يُعالج أمراض الجلد والشعر والأظافر.',
    'جلدية': 'يُعالج أمراض الجلد والشعر والأظافر.',
    'باطنة': 'يُعالج الأمراض الداخلية والجهاز الهضمي.',
    'جهاز هضمي': 'متخصص في الجهاز الهضمي والكبد.',
    'عظام ومفاصل': 'يُعالج الكسور وآلام المفاصل والعظام.',
    'أطفال وحديثي الولادة': 'متخصص في صحة الأطفال من الولادة.',
    'أطفال': 'متخصص في صحة الأطفال.',
    'نساء وتوليد': 'يُعالج أمراض النساء والحمل والولادة.',
    'صدر وحساسية': 'يُعالج أمراض الجهاز التنفسي والحساسية.',
    'سكري وغدد': 'يُعالج مرض السكري والغدد الصماء.',
    'نفسية وعلاج نفسي': 'يُعالج القلق والاكتئاب والاضطرابات النفسية.',
    'مسالك بولية': 'يُعالج أمراض الكلى والمسالك البولية.',
    'كلى': 'متخصص في أمراض الكلى.',
    'تحاليل': 'معمل تحاليل متكامل لجميع الفحوصات.',
    'أشعة': 'مركز أشعة وتصوير طبي.',
  };

  /// يحلل النص ويرجع قائمة التخصصات المناسبة
  static List<String> analyze(String input) {
    final lower = input.toLowerCase();
    final found = <String>{};
    for (final entry in symptomToSpecialties.entries) {
      if (lower.contains(entry.key)) {
        found.addAll(entry.value);
      }
    }
    return found.toList();
  }

  /// هل يحتاج تحاليل/أشعة؟
  static bool needsLab(String input) {
    final lower = input.toLowerCase();
    return lower.contains('تحليل') ||
        lower.contains('تحاليل') ||
        lower.contains('أشعة') ||
        lower.contains('اشعة') ||
        lower.contains('سونار') ||
        lower.contains('رنين') ||
        lower.contains('دم') ||
        lower.contains('هرمون') ||
        lower.contains('بول');
  }
}

// ─── Chatbot Controller ───────────────────────────────────────────────────────
class ChatbotController extends GetxController {
  final RxList<Message> messages = <Message>[].obs;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool _isProcessing = false.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _addBot(
      'مرحباً! 👋 أنا مساعدك الطبي الذكي.\n\n'
      'أخبرني بأعراضك أو ما تشعر به، وسأرشّحك لأفضل الأطباء المتاحين في التطبيق حسب حالتك.\n\n'
      '💡 مثلاً: "عندي صداع وعيوني بتوجعوني" أو "بعاني من ضغط وقلبي بيخفق"',
    );
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _addBot(String text, {List<Map<String, dynamic>>? cards}) {
    messages.add(Message(text: text, isUserMessage: false, cards: cards));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    messages.add(Message(text: text, isUserMessage: true));
    messageController.clear();
    _scrollToBottom();
    _processUserMessage(text);
  }

  void addSuggestion(String text) {
    messageController.text = text;
    sendMessage();
  }

  Future<void> _processUserMessage(String input) async {
    _isProcessing.value = true;

    await Future.delayed(const Duration(milliseconds: 600)); // typing feel

    try {
      final specialties = _SymptomKnowledge.analyze(input);
      final needsLab = _SymptomKnowledge.needsLab(input);

      if (specialties.isEmpty && !needsLab) {
        _addBot(
          'فهمت سؤالك! 😊\n\n'
          'حتى أقدر أساعدك أكثر، ممكن تخبرني بأعراض محددة؟\n'
          'مثلاً: صداع، ألم في الصدر، مشكلة في العيون، ألم في المفاصل، إلخ.',
        );
        return;
      }

      // ── بناء الرد النصي
      final sb = StringBuffer();

      if (specialties.isNotEmpty) {
        // خذ أول تخصصين مختلفين فقط
        final uniqueSpecialties = specialties.toSet().take(2).toList();

        sb.writeln('بناءً على ما ذكرته، يبدو أن أعراضك قد تتعلق بـ:');
        for (final sp in uniqueSpecialties) {
          final desc = _SymptomKnowledge.specialtyInfo[sp] ?? '';
          sb.writeln('\n🏥 *$sp*');
          if (desc.isNotEmpty) sb.writeln('   $desc');
        }
        sb.writeln('\nإليك أفضل الأطباء المتاحين في التطبيق:');
      }

      if (needsLab) {
        sb.writeln('\n🔬 بحالتك دي ممكن تحتاج تحاليل أو أشعة. إليك أقرب المعامل:');
      }

      _addBot(sb.toString().trim());

      // ── جلب الأطباء من Firestore
      if (specialties.isNotEmpty) {
        final doctors = await _fetchDoctors(specialties);
        if (doctors.isNotEmpty) {
          _addBot('', cards: doctors);
        } else {
          _addBot('لم أجد أطباء مسجلين في هذا التخصص حالياً في التطبيق. جرّب التواصل مع الدعم أو تصفح صفحة الأطباء.');
        }
      }

      // ── جلب المعامل من Firestore
      if (needsLab) {
        final labs = await _fetchLabs();
        if (labs.isNotEmpty) {
          _addBot('', cards: labs);
        }
      }

      _addBot(
        'هل تريد مزيداً من المعلومات أو الحجز عند أحد الأطباء؟ 😊\n'
        'تذكّر: هذه توصيات عامة ولا تُغني عن الفحص الطبي المتخصص.',
      );
    } catch (e) {
      _addBot('عذراً، حدث خطأ أثناء البحث. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.');
    } finally {
      _isProcessing.value = false;
    }
  }

  /// إعادة تعيين المحادثة
  void reset() {
    messages.clear();
    messageController.clear();
    _addBot(
      'مرحباً! 👋 أنا مساعدك الطبي الذكي.\n\n'
      'أخبرني بأعراضك أو ما تشعر به، وسأرشّحك لأفضل الأطباء المتاحين في التطبيق حسب حالتك.\n\n'
      '💡 مثلاً: "عندي صداع وعيوني بتوجعوني" أو "بعاني من ضغط وقلبي بيخفق"',
    );
  }

  /// جلب أطباء من Firestore مرتبين بالتقييم الأعلى
  Future<List<Map<String, dynamic>>> _fetchDoctors(List<String> specialties) async {
    try {
      // جلب جميع الدكاترة والفلترة والترتيب محلياً لتجنب مشاكل الـ Index في الفايربيس
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      final all = snap.docs.map((d) {
        final data = d.data();
        return {
          'uid': d.id,
          'name': data['name'] ?? 'دكتور',
          'specialty': data['specialty'] ?? '',
          'rating': (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
          'price': data['price'],
          'photoUrl': data['photoUrl'] ?? data['imageUrl'],
          'governorate': data['governorate'] ?? '',
          'city': data['city'] ?? '',
          'type': 'doctor',
        };
      }).toList();

      // صفي بالتخصص المطلوب (جزئي)
      final filtered = all.where((d) {
        final sp = (d['specialty'] as String).toLowerCase();
        return specialties.any((s) =>
          sp.contains(s.toLowerCase()) || s.toLowerCase().contains(sp));
      }).toList();

      // ترتيب محلي حسب التقييم
      filtered.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
      all.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));

      // لو ما فيش ← رجّع الكل مرتب بالتقييم (أفضل 3)
      final result = filtered.isNotEmpty ? filtered : all;
      return result.take(3).toList();
    } catch (e) {
      print("Error fetching doctors: $e");
      return [];
    }
  }

  /// جلب معامل من Firestore
  Future<List<Map<String, dynamic>>> _fetchLabs() async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'lab')
          .limit(3)
          .get();

      if (snap.docs.isEmpty) {
        // Demo labs if none registered yet
        return [
          {'name': 'معمل الدكتور إسلام', 'specialty': 'تحاليل طبية شاملة', 'rating': 4.8, 'governorate': 'القاهرة', 'type': 'lab'},
          {'name': 'معامل كلير', 'specialty': 'تحاليل هرمونات', 'rating': 4.9, 'governorate': 'القاهرة', 'type': 'lab'},
        ];
      }

      return snap.docs.map((d) {
        final data = d.data();
        return {
          'uid': d.id,
          'name': data['name'] ?? 'معمل',
          'specialty': data['specialty'] ?? 'تحاليل',
          'rating': (data['rating'] is num) ? (data['rating'] as num).toDouble() : 4.5,
          'governorate': data['governorate'] ?? '',
          'type': 'lab',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  bool get isProcessing => _isProcessing.value;
}
