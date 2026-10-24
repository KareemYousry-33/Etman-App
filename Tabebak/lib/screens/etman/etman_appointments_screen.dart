import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'etman_colors.dart';
import '../../controllers/patient_controller.dart';
import '../../controllers/etman_main_wrapper_controller.dart';
import '../../models/appointment_model.dart';
import 'etman_doctor_booking_screen.dart';

class EtmanAppointmentsScreen extends StatelessWidget {
  const EtmanAppointmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PatientController patientController = Get.isRegistered<PatientController>()
        ? Get.find<PatientController>()
        : Get.put(PatientController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: EtmanColors.primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            // Switch back to Home Tab
            Get.find<EtmanMainWrapperController>().changeIndex(0);
          },
        ),
        title: const Text(
          'معاملاتي',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (patientController.myAppointments.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(color: const Color(0xFFF1FAF9), shape: BoxShape.circle),
                      child: Icon(Icons.calendar_today_rounded, size: 70, color: const Color(0xFF1E8C78).withOpacity(0.5)),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'مستنيينك تحجز يا بطل! 🏥',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: Color(0xFF333333), fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'لا يوجد مواعيد حالياً، ابدأ رحلة صحتك واحجز مع أفضل الأطباء الآن.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.find<EtmanMainWrapperController>().changeIndex(0),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8C78),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('استكشف الأطباء الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: patientController.myAppointments.length,
          itemBuilder: (context, index) {
            final appointment = patientController.myAppointments[index];
            return _buildAppointmentCard(appointment, patientController);
          },
        );
      }),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, PatientController controller) {
    bool isCancelled = appointment.status == AppointmentStatus.cancelled;
    String statusText = isCancelled ? 'ملغي' : 'قادم';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.white : EtmanColors.primary,
        borderRadius: BorderRadius.circular(22),
        border: isCancelled ? Border.all(color: Colors.redAccent.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: isCancelled ? Colors.red.withOpacity(0.05) : EtmanColors.primary.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: AssetImage(appointment.doctorImage),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCancelled ? EtmanColors.textDark : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.doctorSpecialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: isCancelled ? Colors.grey[600] : Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCancelled ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: isCancelled ? Colors.red : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: isCancelled ? Colors.grey[50] : Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, color: isCancelled ? Colors.grey[600] : Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(appointment.date),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCancelled ? EtmanColors.textDark : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 25),
                      Icon(Icons.access_time, color: isCancelled ? Colors.grey[600] : Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        appointment.timeSlot,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCancelled ? EtmanColors.textDark : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCancelled) ...[
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showCancelDialog(appointment.id ?? '', controller),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('إلغاء الموعد', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Reorder: Navigate to booking screen with same doctor data
                            Get.to(() => EtmanDoctorBookingScreen(
                              doctorData: {
                                'name': appointment.doctorName,
                                'specialty': appointment.doctorSpecialty,
                                'image': appointment.doctorImage,
                              },
                            ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: EtmanColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('إعادة حجز', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EtmanColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('حجز جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(String id, PatientController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('إلغاء الحجز'),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الموعد؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('لا')),
          TextButton(
            onPressed: () {
              controller.cancelAppointment(id);
              Get.back();
            },
            child: const Text('نعم، إلغاء', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
