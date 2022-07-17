import 'package:get/get.dart';
import 'package:naegot/models/place.model.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/utils/logger.service.dart';

class PlaceService extends GetxService {
  static PlaceService get to => Get.find();
  final myPlaces = Rx<List<Place>>([]);
  final allPlaces = Rx<List<Place>>([]);

  @override
  void onInit() {
    fetchMyPlaces();
    fetchAllPlaces();
    super.onInit();
  }

  Future<void> fetchMyPlaces() async {
    // logger.i("fetchMyPlaces");
    myPlaces.value = await FirebaseSerivce.getMyPlaces();
  }

  Future<void> fetchAllPlaces() async {
    // logger.i("fetchAllPlaces");
    allPlaces.value = await FirebaseSerivce.getAllPlaces();
  }
}
