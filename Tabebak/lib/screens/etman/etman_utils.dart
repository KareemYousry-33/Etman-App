import 'package:get/get.dart';

class EtmanUtils {
  /// Safely converts dynamic value to double. 
  /// Handles String, int, and double types.
  static double toDouble(dynamic value, {double defaultValue = 5.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }
}
