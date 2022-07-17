import 'package:flutter_map/plugin_api.dart';
import 'package:get/get.dart';
import 'package:naegot/models/place.model.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/services/user.service.dart';
import 'package:naegot/utils/logger.service.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();
  final mapController = MapController();
  final placeDetailMapController = MapController();

  RxBool hideBottomMenu = false.obs;

  Rx<List<Place>> subscribePlaces = Rx<List<Place>>([]);

  @override
  void onInit() {
    fetchSubscribePlaces();
    super.onInit();
  }

  Future<void> fetchSubscribePlaces() async {
    List<Place> places = [];
    for (var placeId in UserService.to.currentUser.value!.subscribes) {
      await FirebaseSerivce.getPlace(placeId).then((place) {
        if (place != null) {
          places.add(place);
        }
      });
    }
    subscribePlaces.value = places;
  }
}
