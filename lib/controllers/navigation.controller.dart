import 'package:get/get.dart';

class NavigationController extends GetxController {
  static NavigationController get to => Get.find();
  RxInt currentBottomMenuIndex = 0.obs;
}
