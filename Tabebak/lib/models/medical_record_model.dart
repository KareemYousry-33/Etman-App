import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordModel {
  final String uid;
  final String? bloodType;
  final double? height;
  final double? weight;
  final String? phoneNumber;
  
  final List<ChronicDisease>? chronicDiseases;
  final List<Medication>? currentMedications;
  final List<Allergy>? allergies;
  final List<Surgery>? surgeries;
  final Lifestyle? lifestyle;
  final CurrentSymptoms? currentSymptoms;
  final List<TestResult>? testResults;
  final List<String>? prescriptions; // List of image URLs

  MedicalRecordModel({
    required this.uid,
    this.bloodType,
    this.height,
    this.weight,
    this.phoneNumber,
    this.chronicDiseases,
    this.currentMedications,
    this.allergies,
    this.surgeries,
    this.lifestyle,
    this.currentSymptoms,
    this.testResults,
    this.prescriptions,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'bloodType': bloodType,
      'height': height,
      'weight': weight,
      'phoneNumber': phoneNumber,
      'chronicDiseases': chronicDiseases?.map((e) => e.toMap()).toList(),
      'currentMedications': currentMedications?.map((e) => e.toMap()).toList(),
      'allergies': allergies?.map((e) => e.toMap()).toList(),
      'surgeries': surgeries?.map((e) => e.toMap()).toList(),
      'lifestyle': lifestyle?.toMap(),
      'currentSymptoms': currentSymptoms?.toMap(),
      'testResults': testResults?.map((e) => e.toMap()).toList(),
      'prescriptions': prescriptions,
    };
  }

  factory MedicalRecordModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MedicalRecordModel(
      uid: data['uid'] ?? '',
      bloodType: data['bloodType'],
      height: (data['height'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      phoneNumber: data['phoneNumber'],
      chronicDiseases: (data['chronicDiseases'] as List?)
          ?.map((e) => ChronicDisease.fromMap(e))
          .toList(),
      currentMedications: (data['currentMedications'] as List?)
          ?.map((e) => Medication.fromMap(e))
          .toList(),
      allergies: (data['allergies'] as List?)
          ?.map((e) => Allergy.fromMap(e))
          .toList(),
      surgeries: (data['surgeries'] as List?)
          ?.map((e) => Surgery.fromMap(e))
          .toList(),
      lifestyle: data['lifestyle'] != null ? Lifestyle.fromMap(data['lifestyle']) : null,
      currentSymptoms: data['currentSymptoms'] != null 
          ? CurrentSymptoms.fromMap(data['currentSymptoms']) : null,
      testResults: (data['testResults'] as List?)
          ?.map((e) => TestResult.fromMap(e))
          .toList(),
      prescriptions: (data['prescriptions'] as List?)?.cast<String>(),
    );
  }
}

class ChronicDisease {
  final String name;
  final DateTime? diagnosisDate;
  final bool isStable;

  ChronicDisease({required this.name, this.diagnosisDate, this.isStable = true});

  Map<String, dynamic> toMap() => {
    'name': name,
    'diagnosisDate': diagnosisDate != null ? Timestamp.fromDate(diagnosisDate!) : null,
    'isStable': isStable,
  };

  factory ChronicDisease.fromMap(Map<String, dynamic> map) => ChronicDisease(
    name: map['name'],
    diagnosisDate: (map['diagnosisDate'] as Timestamp?)?.toDate(),
    isStable: map['isStable'] ?? true,
  );
}

class Medication {
  final String name;
  final String? dose;
  final String? frequency;
  final bool adheresToSchedule;
  final String? sideEffects;

  Medication({required this.name, this.dose, this.frequency, this.adheresToSchedule = true, this.sideEffects});

  Map<String, dynamic> toMap() => {
    'name': name,
    'dose': dose,
    'frequency': frequency,
    'adheresToSchedule': adheresToSchedule,
    'sideEffects': sideEffects,
  };

  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
    name: map['name'],
    dose: map['dose'],
    frequency: map['frequency'],
    adheresToSchedule: map['adheresToSchedule'] ?? true,
    sideEffects: map['sideEffects'],
  );
}

class Allergy {
  final String name;
  final String? type; // 'food', 'medication'
  final String? reaction;

  Allergy({required this.name, this.type, this.reaction});

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'reaction': reaction,
  };

  factory Allergy.fromMap(Map<String, dynamic> map) => Allergy(
    name: map['name'],
    type: map['type'],
    reaction: map['reaction'],
  );
}

class Surgery {
  final String type;
  final DateTime? date;
  final String? complications;

  Surgery({required this.type, this.date, this.complications});

  Map<String, dynamic> toMap() => {
    'type': type,
    'date': date != null ? Timestamp.fromDate(date!) : null,
    'complications': complications,
  };

  factory Surgery.fromMap(Map<String, dynamic> map) => Surgery(
    type: map['type'],
    date: (map['date'] as Timestamp?)?.toDate(),
    complications: map['complications'],
  );
}

class Lifestyle {
  final bool isSmoking;
  final int? cigarettesPerDay;
  final bool isDrinking;
  final String? activityLevel; // 'High', 'Moderate', 'Low'
  final String? dietType;

  Lifestyle({this.isSmoking = false, this.cigarettesPerDay, this.isDrinking = false, this.activityLevel, this.dietType});

  Map<String, dynamic> toMap() => {
    'isSmoking': isSmoking,
    'cigarettesPerDay': cigarettesPerDay,
    'isDrinking': isDrinking,
    'activityLevel': activityLevel,
    'dietType': dietType,
  };

  factory Lifestyle.fromMap(Map<String, dynamic> map) => Lifestyle(
    isSmoking: map['isSmoking'] ?? false,
    cigarettesPerDay: map['cigarettesPerDay'],
    isDrinking: map['isDrinking'] ?? false,
    activityLevel: map['activityLevel'],
    dietType: map['dietType'],
  );
}

class CurrentSymptoms {
  final String complaint;
  final String? onset;
  final int? painScale; // 1 to 10
  final String? triggers;
  final String? trend; // 'improving', 'stable', 'worsening'

  CurrentSymptoms({required this.complaint, this.onset, this.painScale, this.triggers, this.trend});

  Map<String, dynamic> toMap() => {
    'complaint': complaint,
    'onset': onset,
    'painScale': painScale,
    'triggers': triggers,
    'trend': trend,
  };

  factory CurrentSymptoms.fromMap(Map<String, dynamic> map) => CurrentSymptoms(
    complaint: map['complaint'] ?? '',
    onset: map['onset'],
    painScale: map['painScale'],
    triggers: map['triggers'],
    trend: map['trend'],
  );
}

class TestResult {
  final String testName;
  final DateTime? date;
  final String? resultImageUrl;

  TestResult({required this.testName, this.date, this.resultImageUrl});

  Map<String, dynamic> toMap() => {
    'testName': testName,
    'date': date != null ? Timestamp.fromDate(date!) : null,
    'resultImageUrl': resultImageUrl,
  };

  factory TestResult.fromMap(Map<String, dynamic> map) => TestResult(
    testName: map['testName'],
    date: (map['date'] as Timestamp?)?.toDate(),
    resultImageUrl: map['resultImageUrl'],
  );
}
