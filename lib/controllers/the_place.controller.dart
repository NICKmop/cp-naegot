import 'package:flutter/cupertino.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/state_manager.dart';

class ThePlaceController extends GetxController {
  RxString searchText = "".obs;
  final searchController = TextEditingController();
  final topKeywords = RxList<String>([]);

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
