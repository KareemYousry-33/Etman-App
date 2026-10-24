import 'package:get/get.dart';

class EtmanMainWrapperController extends GetxController {
  var currentIndex = 0.obs;

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  void goToHome() {
    currentIndex.value = 0;
  }
}
