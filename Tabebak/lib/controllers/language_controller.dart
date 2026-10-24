import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageController extends GetxController {
  // Stuck to Arabic Only as per request
  var currentLocale = const Locale('ar', 'EG').obs;

  void changeLanguage(String langCode, String countryCode) {
    // Disabled language switching to keep it Arabic only
  }

  // Always true now for styling purposes
  bool get isArabic => true;
}
