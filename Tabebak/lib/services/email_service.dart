import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sends emails via EmailJS — no backend required.
/// Sign up at https://www.emailjs.com/ to get your credentials.
/// Currently configured with Etman's account details.
class EmailService {
  // ── EmailJS credentials ──────────────────────────────────────────────────
  static const _serviceId   = 'service_etman';    // Replace with your service ID
  static const _templateId  = 'template_booking'; // Replace with your template ID
  static const _publicKey   = 'YOUR_PUBLIC_KEY';  // Replace with your public key
  // ─────────────────────────────────────────────────────────────────────────

  static const _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Send a booking notification to the doctor's email.
  /// All patient profile fields are included so the doctor sees full context.
  static Future<void> sendBookingToDoctorEmail({
    required String doctorEmail,
    required String doctorName,
    required String patientName,
    required String patientEmail,
    required String patientPhone,
    required String patientAge,
    required String patientAddress,
    required String patientHistory,
    required String appointmentDate,
    required String appointmentTime,
    String? notes,
  }) async {
    try {
      final body = json.encode({
        'service_id':  _serviceId,
        'template_id': _templateId,
        'user_id':     _publicKey,
        'template_params': {
          'to_email':        doctorEmail,
          'to_name':         doctorName,
          'patient_name':    patientName,
          'patient_email':   patientEmail,
          'patient_phone':   patientPhone,
          'patient_age':     patientAge,
          'patient_address': patientAddress,
          'patient_history': patientHistory,
          'appointment_date': appointmentDate,
          'appointment_time': appointmentTime,
          'notes':           notes ?? 'لا توجد ملاحظات',
        },
      });

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        print('[EmailService] Failed to send email: ${response.body}');
      } else {
        print('[EmailService] Email sent to $doctorEmail ✅');
      }
    } catch (e) {
      // Silent fail — email is a nice-to-have and should never break booking
      print('[EmailService] Error: $e');
    }
  }
}
