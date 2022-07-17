import 'package:get/get.dart';

enum MapType { normal, satelite }

class MapService extends GetxController {
  static MapService get to => Get.find();

  final mapType = Rx<MapType>(MapType.normal);
}
