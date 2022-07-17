import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_dragmarker/dragmarker.dart';
import 'package:flutter_map_line_editor/polyeditor.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:latlong2/latlong.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/constants/common.constants.dart';
import 'package:naegot/controllers/home.controller.dart';
import 'package:naegot/controllers/map.controller.dart';
import 'package:naegot/dialogs/app_default_dialog.dart';
import 'package:naegot/dialogs/share.dialog.dart';
import 'package:naegot/extensions/colors.extension.dart';
import 'package:naegot/models/app_user.model.dart';
import 'package:naegot/models/place.model.dart';
import 'package:naegot/screens/add_place.screen.dart';
import 'package:naegot/screens/edit_place.screen.dart';
import 'package:naegot/screens/edit_profile.screen.dart';
import 'package:naegot/screens/my_place_detail.screen.dart';
import 'package:naegot/screens/permission.screen.dart';
import 'package:naegot/screens/settings.screen.dart';
import 'package:naegot/screens/the_place.screen.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/services/place.service.dart';
import 'package:naegot/services/user.service.dart';
import 'package:naegot/utils/logger.service.dart';
import 'package:naegot/widgets/user_profile_image.widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

import '../controllers/navigation.controller.dart';

enum MapPlaceType { marker, line, circle, polygon }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, this.place}) : super(key: key);
  final Place? place;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  bool showMyPlace = true;
  bool showSavedPlace = true;

  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double?> _centerCurrentLocationStreamController;
  bool isEditMode = false;
  var mapPlaceType = MapPlaceType.marker;

  late PolyEditor polyEditor;

  LatLng centerLocation = MAP_INITIAL_CENTER_LOCATION;
  LatLng? selectedMarkerPoint;
  List<LatLng>? selectedPolyPoints;

  String? selectedMarkerKey;
  // Place? selectedPlace;

  bool modalBottomSheetExpand = false;

  double currentImageCarouselIndex = 0;

  double circleRadius = 50.0;

  List<Polygon> polygons = [];
  var testPolygon = Polygon(
    color: AppColors.skyBlue,
    points: [],
    borderColor: AppColors.skyBlue,
    isFilled: true,
  );

  List<Polyline> polylines = [];
  var testPolyline = Polyline(
    color: AppColors.skyBlue,
    strokeCap: StrokeCap.round,
    points: [],
    strokeWidth: 5,
  );

  List<CircleMarker> circleMarkers = [];
  var testCircle = [];

  void clearMapMarkers() {
    selectedMarkerPoint = null;
    testCircle = [];
    circleMarkers = [];
    testPolyline.points.clear();
    testPolygon.points.clear();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // _centerOnLocationUpdate = CenterOnLocationUpdate.once;
    //TODO: 임시
    _centerOnLocationUpdate = CenterOnLocationUpdate.never;
    _centerCurrentLocationStreamController = StreamController<double?>();

    polyEditor = PolyEditor(
      addClosePathMarker: true,
      points: [...testPolygon.points, ...testPolyline.points],
      pointIcon: Image.asset("assets/images/focus.png"),
      intermediateIcon: const Icon(Icons.lens, size: 150, color: Colors.grey),
      callbackRefresh: () => {setState(() {})},
    );

    polygons.add(testPolygon);
    polylines.add(testPolyline);
  }

  @override
  void dispose() {
    _centerCurrentLocationStreamController.close().then((value) => null);
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final latTween = Tween<double>(
        begin: HomeController.to.mapController.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: HomeController.to.mapController.center.longitude,
        end: destLocation.longitude);
    final zoomTween = Tween<double>(
        begin: HomeController.to.mapController.zoom, end: destZoom);

    // Create a animation controller that has a duration and a TickerProvider.
    var controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      HomeController.to.mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseSerivce.getCurrentUserStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }

          final user = AppUser.fromMap(snapshot.data!.data()!);

          return Scaffold(
            appBar: widget.place == null ? null : AppBar(),
            key: scaffoldKey,
            drawer: Drawer(
              child: SafeArea(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "내 정보",
                          style: TextStyle(fontSize: 18),
                        ),
                        IconButton(
                          onPressed: () {
                            Get.to(() => const EditProfileScreen());
                          },
                          icon: const Icon(
                            Icons.edit,
                            color: AppColors.grey,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        UserProfileCircleImage(
                          imageUrl: user.profileImage,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name ?? "-",
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 10),
                            Text(user.nickname ?? "-"),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: user.categories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == user.categories.length) {
                          return CheckboxListTile(
                            value: user.showSubscribePlaces,
                            onChanged: (value) async {
                              if (value == null) return;
                              await FirebaseSerivce.changeShowSubscribePlaces(
                                  value);
                            },
                            title: const Text("저장한 장소"),
                            activeColor: AppColors.primary,
                          );
                        }
                        final category = user.categories[index];

                        return CheckboxListTile(
                          value: !user.invisibleCategories.contains(category),
                          onChanged: (value) async {
                            if (value == null) return;
                            await FirebaseSerivce.changeCategoryVisible(
                                category, value);
                          },
                          title: Text(category),
                          activeColor: AppColors.primary,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "공지/이벤트",
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    Image.asset("assets/images/banner.png"),
                    const Divider(height: 40),
                    ListTile(
                      title: const Text("설정"),
                      trailing: const Icon(Icons.settings),
                      onTap: () {
                        Get.to(() => const SettingsScreen());
                      },
                    )
                  ],
                ),
              ),
            ),
            body: FutureBuilder<List<Place>>(
                future: FirebaseSerivce.getSubscribePlaces(),
                builder: (context, snapshot) {
                  final subscribedPlaces = snapshot.data;
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseSerivce.getMyPlaceStream(),
                      builder: (context, snapshot) {
                        List<Place> places = [];
                        if (snapshot.hasData) {
                          places = snapshot.data!.docs
                              .map((e) => Place.fromMap(e.data()))
                              .toList();
                        }

                        polylines = [];
                        polygons = [];
                        circleMarkers = [];
                        selectedPolyPoints = [];

                        places = places
                            .where((element) => !user.invisibleCategories
                                .contains(element.category))
                            .toList();

                        if (user.showSubscribePlaces) {
                          places = [...places, ...subscribedPlaces ?? []];
                        }

                        places
                            .where((marker) => marker.type == "line")
                            .forEach((place) {
                          // final polyline = Polyline(points: place.polylines!);
                          var polyline = Polyline(
                            color: HexColor.fromHex(place.color),
                            points: place.polylines!,
                            strokeWidth: 5,
                            borderStrokeWidth: 5,
                            borderColor:
                                selectedMarkerKey == place.createdAt.toString()
                                    ? Colors.white
                                    : Colors.transparent,
                          );
                          polylines.add(polyline);
                        });

                        places
                            .where((marker) => marker.type == "polygon")
                            .forEach((place) {
                          var polygon = Polygon(
                            borderColor:
                                selectedMarkerKey == place.createdAt.toString()
                                    ? Colors.white
                                    : Colors.transparent,
                            borderStrokeWidth: 3,
                            color:
                                HexColor.fromHex(place.color).withOpacity(0.5),
                            points: place.polygons!,
                            isFilled: true,
                            label: HomeController.to.mapController.zoom <
                                    ZOOM_FOR_SHOW_MARKER_NAME
                                ? null
                                : place.name,
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              shadows: [
                                Shadow(
                                  color: Colors.grey,
                                  offset: Offset(1, 1),
                                )
                              ],
                            ),
                          );
                          polygons.add(polygon);
                        });

                        places
                            .where((marker) => marker.type == "circle")
                            .forEach((place) {
                          return circleMarkers.add(
                            CircleMarker(
                              point: place.point!,
                              color: HexColor.fromHex(place.color)
                                  .withOpacity(0.5),
                              borderStrokeWidth: 0,
                              borderColor: selectedMarkerKey ==
                                      place.createdAt.toString()
                                  ? Colors.white
                                  : Colors.transparent,
                              useRadiusInMeter: true,
                              radius: place.radius!
                                  .toDouble(), // 2000, meters | 2 km
                            ),
                          );
                        });
                        // } else {
                        if (testPolyline.points.isNotEmpty) {
                          testPolyline.points
                              .map(
                                (polyline) => Marker(
                                  width: 50.0,
                                  height: 50.0,
                                  point: polyline,
                                  builder: (ctx) =>
                                      Image.asset("assets/images/focus.png"),
                                ),
                              )
                              .toList();

                          selectedPolyPoints = testPolyline.points;
                        }
                        polylines.add(testPolyline);
                        //  polyEditor.add(testPolyline.points, centerLocation);

                        if (testPolygon.points.isNotEmpty) {
                          testPolygon.points
                              .map(
                                (polygon) => Marker(
                                  width: 50.0,
                                  height: 50.0,
                                  point: polygon,
                                  builder: (ctx) =>
                                      Image.asset("assets/images/focus.png"),
                                ),
                              )
                              .toList();
                          selectedPolyPoints = testPolyline.points;
                        }
                        polygons.add(testPolygon);

                        if (mapPlaceType == MapPlaceType.circle &&
                            selectedMarkerPoint != null) {
                          testCircle = [
                            defaultCircleMarker(selectedMarkerPoint!, null)
                          ];
                        }

                        return Stack(
                          children: [
                            Positioned(
                              child: KeyboardDismissOnTap(
                                child: FlutterMap(
                                  mapController:
                                      HomeController.to.mapController,
                                  options: MapOptions(
                                    onPositionChanged: onMapPostionChange,
                                    onTap: (tapPosition, point) {
                                      HomeController.to.hideBottomMenu.value =
                                          !HomeController
                                              .to.hideBottomMenu.value;
                                      selectedMarkerKey = null;
                                      selectedMarkerPoint = null;
                                      selectedPolyPoints = null;
                                      setState(() {});
                                      for (var polygon in polygons) {
                                        final isInside =
                                            mp.PolygonUtil.containsLocation(
                                                mp.LatLng(point.latitude,
                                                    point.longitude),
                                                polygon.points
                                                    .map((point) => mp.LatLng(
                                                        point.latitude,
                                                        point.longitude))
                                                    .toList(),
                                                true);
                                        if (isInside) {
                                          var place = places.firstWhereOrNull(
                                              (place) =>
                                                  place.polygons ==
                                                  polygon.points);
                                          if (place != null) {
                                            selectedMarkerKey =
                                                place.createdAt.toString();
                                            // selectedPlace = place;
                                            showPlaceInfo(place);
                                            setState(() {});
                                            return;
                                          }
                                        }
                                      }

                                      for (var polyline in polylines) {
                                        final distance =
                                            mp.PolygonUtil.locationIndexOnPath(
                                                mp.LatLng(point.latitude,
                                                    point.longitude),
                                                polyline.points
                                                    .map((point) => mp.LatLng(
                                                        point.latitude,
                                                        point.longitude))
                                                    .toList(),
                                                true,
                                                tolerance: 10);
                                        if (distance != -1) {
                                          var place = places.firstWhereOrNull(
                                              (place) =>
                                                  place.polylines ==
                                                  polyline.points);
                                          if (place != null) {
                                            selectedMarkerKey =
                                                place.createdAt.toString();
                                            // selectedPlace = place;
                                            showPlaceInfo(place);
                                            setState(() {});
                                            return;
                                          }
                                        }
                                      }

                                      for (var circleMarker in circleMarkers) {
                                        final distance = mp.SphericalUtil
                                            .computeDistanceBetween(
                                          mp.LatLng(
                                              point.latitude, point.longitude),
                                          mp.LatLng(circleMarker.point.latitude,
                                              circleMarker.point.longitude),
                                        );
                                        if (distance <= circleMarker.radius) {
                                          var place = places.firstWhereOrNull(
                                              (place) =>
                                                  place.point ==
                                                  circleMarker.point);
                                          if (place != null) {
                                            selectedMarkerKey =
                                                place.createdAt.toString();
                                            // selectedPlace = place;
                                            showPlaceInfo(place);
                                            setState(() {});
                                            return;
                                          }
                                        }
                                      }
                                    },
                                    onLongPress: (tapPosition, point) {
                                      selectedMarkerKey = null;
                                      selectedMarkerPoint = null;
                                      selectedPolyPoints = null;
                                      setState(() {});
                                      for (var polygon in polygons) {
                                        final isInside =
                                            mp.PolygonUtil.containsLocation(
                                                mp.LatLng(point.latitude,
                                                    point.longitude),
                                                polygon.points
                                                    .map((point) => mp.LatLng(
                                                        point.latitude,
                                                        point.longitude))
                                                    .toList(),
                                                true);
                                        if (isInside) {
                                          var place = places.firstWhereOrNull(
                                              (place) =>
                                                  place.polygons ==
                                                  polygon.points);
                                          if (place != null) {
                                            selectedMarkerKey =
                                                place.createdAt.toString();
                                            Get.to(
                                                EditPlaceScreen(place: place));
                                            setState(() {});
                                            return;
                                          }
                                        }
                                      }

                                      for (var polyline in polylines) {
                                        final distance =
                                            mp.PolygonUtil.locationIndexOnPath(
                                                mp.LatLng(point.latitude,
                                                    point.longitude),
                                                polyline.points
                                                    .map((point) => mp.LatLng(
                                                        point.latitude,
                                                        point.longitude))
                                                    .toList(),
                                                true,
                                                tolerance: 10);
                                        if (distance != -1) {
                                          var place = places.firstWhereOrNull(
                                              (place) =>
                                                  place.polylines ==
                                                  polyline.points);
                                          if (place != null) {
                                            selectedMarkerKey =
                                                place.createdAt.toString();
                                            Get.to(
                                                EditPlaceScreen(place: place));
                                            setState(() {});
                                            return;
                                          }
                                        }
                                      }

                                      for (var circleMarker in circleMarkers) {
                                        final distance = mp.SphericalUtil
                                            .computeDistanceBetween(
                                          mp.LatLng(
                                              point.latitude, point.longitude),
                                          mp.LatLng(circleMarker.point.latitude,
                                              circleMarker.point.longitude),
                                        );
                                        if (distance <= circleMarker.radius) {
                                          var place = places.firstWhereOrNull(
                                              (place) =>
                                                  place.point ==
                                                  circleMarker.point);
                                          if (place != null) {
                                            selectedMarkerKey =
                                                place.createdAt.toString();
                                            Get.to(
                                                EditPlaceScreen(place: place));

                                            setState(() {});
                                            return;
                                          }
                                        }
                                      }
                                    },
                                    allowPanningOnScrollingParent: false,
                                    center: LatLng(37.5547125, 126.9707878),
                                    zoom: 15.0,
                                    minZoom: 6,
                                    maxZoom: MapService.to.mapType.value ==
                                            MapType.normal
                                        ? 17.4
                                        : 15,
                                    // interactiveFlags:
                                    //     InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                                    plugins: [
                                      LocationMarkerPlugin(
                                        centerCurrentLocationStream:
                                            _centerCurrentLocationStreamController
                                                .stream,
                                        centerOnLocationUpdate:
                                            _centerOnLocationUpdate,
                                      ),
                                      DragMarkerPlugin(),
                                    ],
                                  ),
                                  nonRotatedChildren: [
                                    buildMenuButton(),
                                    Positioned(
                                      left: 20,
                                      bottom: 20,
                                      child: FloatingActionButton(
                                        heroTag: "currentLocation",
                                        backgroundColor: Colors.white,
                                        elevation: 2,
                                        onPressed: onMapCurrentLocation,
                                        child: const Icon(
                                          Icons.my_location,
                                          color: AppColors.black,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 20,
                                      bottom: 20,
                                      child: FloatingActionButton(
                                        backgroundColor: Colors.white,
                                        elevation: 2,
                                        onPressed: () async {
                                          if (isEditMode) {
                                            if (mapPlaceType !=
                                                    MapPlaceType.marker &&
                                                testPolygon.points.isEmpty &&
                                                testPolyline.points.isEmpty &&
                                                testCircle.isEmpty) {
                                              EasyLoading.showError(
                                                  "설정된 마커가 없습니다.");
                                              return;
                                            }

                                            if (mapPlaceType ==
                                                    MapPlaceType.line &&
                                                testPolyline.points.length <
                                                    2) {
                                              EasyLoading.showError(
                                                  "라인은 2개 이상의 등록 장소가 필요합니다.");
                                              return;
                                            }

                                            if (mapPlaceType ==
                                                    MapPlaceType.polygon &&
                                                testPolygon.points.length < 3) {
                                              EasyLoading.showError(
                                                  "도형은 3개 이상의 등록 장소가 필요합니다.");
                                              return;
                                            }

                                            if (mapPlaceType ==
                                                MapPlaceType.marker) {
                                              selectedMarkerPoint =
                                                  HomeController
                                                      .to.mapController.center;
                                              setState(() {});
                                            }

                                            final result =
                                                await showModalBottomSheet<
                                                        bool>(
                                                    // isDismissible: false,
                                                    // enableDrag: false,
                                                    isScrollControlled: true,
                                                    context: context,
                                                    builder: (context) {
                                                      return StatefulBuilder(
                                                          builder: (context,
                                                              setState) {
                                                        return SizedBox(
                                                          height:
                                                              Get.size.height *
                                                                  0.8,
                                                          child: AddPlaceScreen(
                                                            marker:
                                                                selectedMarkerPoint,
                                                            polygones:
                                                                testPolygon
                                                                    .points,
                                                            polylines:
                                                                testPolyline
                                                                    .points,
                                                            // circleMarker: circleMarkers,
                                                            mapPlaceType:
                                                                mapPlaceType,
                                                            circleRadius:
                                                                circleRadius,
                                                          ),
                                                        );
                                                      });
                                                    });

                                            if (result != null && result) {
                                              clearMapMarkers();
                                              isEditMode = false;
                                              setState(() {});
                                            }
                                          } else {
                                            isEditMode = !isEditMode;
                                            setState(() {});
                                          }
                                        },
                                        child: isEditMode
                                            ? const Text(
                                                "확인",
                                                style: TextStyle(
                                                    color: AppColors.black,
                                                    fontSize: 16),
                                              )
                                            : Image.asset(
                                                "assets/images/logo.png",
                                                width: 35,
                                                height: 35,
                                              ),
                                      ),
                                    ),
                                    isEditMode
                                        ? Positioned(
                                            right: 20,
                                            bottom: 90,
                                            child: FloatingActionButton(
                                              heroTag: "currentLocation",
                                              backgroundColor: Colors.white,
                                              elevation: 2,
                                              onPressed: onCancelMapEdit,
                                              child: const Text(
                                                "취소",
                                                style: TextStyle(
                                                    color: AppColors.black,
                                                    fontSize: 16),
                                              ),
                                            ),
                                          )
                                        : Container(),
                                    isEditMode
                                        ? Positioned(
                                            right: 80,
                                            bottom: 20,
                                            child: Row(
                                              children: [
                                                buildEditButton(
                                                    MapPlaceType.marker,
                                                    "assets/images/edit-type-marker.png"),
                                                buildEditButton(
                                                    MapPlaceType.line,
                                                    "assets/images/edit-type-line.png"),
                                                buildEditButton(
                                                    MapPlaceType.circle,
                                                    "assets/images/edit-type-circle.png"),
                                                buildEditButton(
                                                    MapPlaceType.polygon,
                                                    "assets/images/edit-type-polygon.png"),
                                              ],
                                            ),
                                          )
                                        : Container(),
                                    isEditMode &&
                                            mapPlaceType == MapPlaceType.circle
                                        ? Positioned(
                                            right: 80,
                                            bottom: 80,
                                            child: Column(
                                              children: [
                                                Text("$circleRadius M"),
                                                Slider(
                                                  onChanged: (value) {
                                                    circleRadius = value;
                                                    setState(() {});
                                                  },
                                                  value: circleRadius,
                                                  divisions: 10,
                                                  min: 50,
                                                  max: 200,
                                                ),
                                              ],
                                            ),
                                          )
                                        : Container(),
                                    isEditMode &&
                                            mapPlaceType != MapPlaceType.marker
                                        ? Positioned(
                                            right: 20,
                                            bottom: Get.size.height / 2 - 70,
                                            child: Column(
                                              children: [
                                                GestureDetector(
                                                  onTap: addMarker,
                                                  child: const Card(
                                                    margin: EdgeInsets.only(
                                                        bottom: 2),
                                                    elevation: 1,
                                                    child: Padding(
                                                        padding:
                                                            EdgeInsets.all(10),
                                                        child: Icon(Icons.add)),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                GestureDetector(
                                                  onTap: removeMarker,
                                                  child: const Card(
                                                    margin: EdgeInsets.all(0),
                                                    elevation: 1,
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      child: Icon(Icons.remove),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Container(),
                                  ],
                                  layers: [
                                    TileLayerOptions(
                                      urlTemplate:
                                          "http://{s}.google.com/vt/lyrs=${MapService.to.mapType.value == MapType.normal ? "m" : "s"}&hl=ko&gl=KR&x={x}&y={y}&z={z}",
                                      subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
                                      retinaMode: true,
                                      tileProvider: NetworkTileProvider(),
                                      tileBounds: LatLngBounds(
                                        LatLng(43.241775, 131.006844),
                                        LatLng(31.842202, 123.967484),
                                      ),
                                    ),
                                    PolygonLayerOptions(polygons: polygons),
                                    PolylineLayerOptions(polylines: polylines),
                                    CircleLayerOptions(circles: [
                                      ...circleMarkers,
                                      ...testCircle
                                    ]),
                                    DragMarkerPluginOptions(
                                        markers: polyEditor.edit()),
                                    LocationMarkerLayerOptions(),
                                    MarkerLayerOptions(
                                        markers: makeMarkers(places)),
                                  ],
                                ),
                              ),
                            ),
                            isEditMode
                                ? Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    bottom: mapPlaceType == MapPlaceType.circle
                                        ? 0
                                        : 50,
                                    child: Center(
                                      child: mapPlaceType == MapPlaceType.circle
                                          ? Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                color: AppColors.skyBlue
                                                    .withOpacity(0.5),
                                              ),
                                            )
                                          : Image.asset(
                                              "assets/images/focus.png",
                                              width: 50,
                                              height: 50,
                                            ),
                                    ))
                                : Container()
                          ],
                        );
                      });
                }),
          );
        });
  }

  void onCancelMapEdit() async {
    isEditMode = false;
    clearMapMarkers();
  }

  void onMapCurrentLocation() async {
    final ok = await requestPermissions();
    if (!ok) {
      await EasyLoading.showError("위치 권한을 허용해주세요");
      Future.delayed(const Duration(milliseconds: 1500), () {
        openAppSettings();
      });
    }
    setState(
      () => _centerOnLocationUpdate = CenterOnLocationUpdate.once,
    );
    _centerCurrentLocationStreamController.add(16);
  }

  Positioned buildMenuButton() {
    return Positioned(
      left: 10,
      top: 40,
      child: IconButton(
        onPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
        icon: Icon(
          Icons.menu,
          color: AppColors.black.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }

  onMapPostionChange(position, hasGesture) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  void removeMarker() {
    if (!isEditMode) return;
    selectedMarkerPoint = null;
    switch (mapPlaceType) {
      case MapPlaceType.marker:
        setState(() {});
        break;
      case MapPlaceType.circle:
        testCircle = [];
        setState(() {});
        break;
      case MapPlaceType.line:
        if (testPolyline.points.isEmpty) return;
        testPolyline.points.removeLast();
        setState(() {});
        break;
      case MapPlaceType.polygon:
        if (testPolygon.points.isEmpty) return;
        testPolygon.points.removeLast();
        setState(() {});
    }
  }

  void addMarker() {
    if (!isEditMode) return;
    switch (mapPlaceType) {
      case MapPlaceType.marker:
        EasyLoading.showError("마커 등록은 확인 버튼을 눌러주세요.");
        // selectedMarkerPoint =HomeController.to.mapController.center;
        // setState(() {});
        break;
      case MapPlaceType.circle:
        selectedMarkerPoint = HomeController.to.mapController.center;
        setState(() {});
        testCircle = [
          defaultCircleMarker(HomeController.to.mapController.center, null)
        ];
        setState(() {});
        break;
      case MapPlaceType.line:
        polyEditor.add(
            testPolyline.points, HomeController.to.mapController.center);
        break;
      case MapPlaceType.polygon:
        polyEditor.add(
            testPolygon.points, HomeController.to.mapController.center);
    }
  }

  FloatingActionButton buildEditButton(
      MapPlaceType thisEditType, String imagePath) {
    return FloatingActionButton(
      mini: true,
      heroTag: imagePath,
      backgroundColor:
          mapPlaceType == thisEditType ? AppColors.primary : AppColors.white,
      elevation: 2,
      onPressed: () {
        clearMapMarkers();
        mapPlaceType = thisEditType;
        setState(() {});
      },
      child: Image.asset(
        imagePath,
        width: 20,
        height: 20,
        color: mapPlaceType == thisEditType ? AppColors.white : AppColors.black,
      ),
    );
  }

  List<Marker> makeMarkers(List<Place> places) {
    // 편집모드 일경우
    // if (isEditMode) {
    // 추가된 포인트 마커가 있을경우
    // if (selectedMarkerPoint != null) {

    final pointMarkers =
        places.where((marker) => marker.type == "marker").map((place) {
      return Marker(
        key: Key(place.createdAt.toString()),
        anchorPos: AnchorPos.align(
          selectedMarkerKey != place.createdAt.toString()
              ? AnchorAlign.center
              : AnchorAlign.center,
        ),
        width: Get.size.width / 2,
        height: selectedMarkerKey != place.createdAt.toString() ? 60 : 80,
        point: place.point!,
        builder: (ctx) => GestureDetector(
          onTap: () {
            selectedMarkerKey = place.createdAt.toString();
            setState(() {});
            showPlaceInfo(place);
          },
          onLongPress: () {
            selectedMarkerKey = place.createdAt.toString();
            setState(() {});
            Get.to(EditPlaceScreen(place: place));
          },
          child: selectedMarkerKey != place.createdAt.toString()
              ? Stack(
                  children: [
                    Positioned(
                      left: 0, right: 0,
                      // top: 8,
                      // left: 9,
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Container(
                          width: 32,
                          height: 32,
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                              color: HexColor.fromHex(place.color),
                              borderRadius: BorderRadius.circular(100),
                              border:
                                  Border.all(color: Colors.white, width: 2)),
                          child: Icon(
                            IconData(
                              place.icon,
                              fontFamily: "MaterialIcons",
                            ),
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    HomeController.to.mapController.zoom <
                            ZOOM_FOR_SHOW_MARKER_NAME
                        ? Container()
                        : Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                                child: Stack(
                              children: [
                                Text(
                                  place.name,
                                  style: TextStyle(
                                    // color: HexColor.fromHex(place.color),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 3
                                      ..color = Colors.white,
                                  ),
                                ),
                                Text(
                                  place.name,
                                  style: TextStyle(
                                    color: HexColor.fromHex(place.color),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            )))
                  ],
                )
              : Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        "assets/images/placeholder.png",
                        color: HexColor.fromHex(place.color),
                        width: 40,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Icon(
                            IconData(
                              place.icon,
                              fontFamily: "MaterialIcons",
                            ),
                            size: 20,
                            color: HexColor.fromHex(place.color),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                            child: Stack(
                          children: [
                            Text(
                              place.name,
                              style: TextStyle(
                                // color: HexColor.fromHex(place.color),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 3
                                  ..color = Colors.white,
                              ),
                            ),
                            Text(
                              place.name,
                              style: TextStyle(
                                color: HexColor.fromHex(place.color),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        )))
                  ],
                ),
        ),
      );
    }).toList();
    // return pointMarkers;

    switch (mapPlaceType) {
      case MapPlaceType.line:
        return [
          ...pointMarkers,
          ...testPolyline.points
              .map((point) =>
                  defaultPolyMarker(LatLng(point.latitude, point.longitude)))
              .toList(),
        ];
      case MapPlaceType.polygon:
        return [
          ...pointMarkers,
          ...testPolygon.points
              .map((point) =>
                  defaultPolyMarker(LatLng(point.latitude, point.longitude)))
              .toList()
        ];
      case MapPlaceType.circle:
        return [...pointMarkers];
      default:
        return selectedMarkerPoint == null
            ? [...pointMarkers]
            : [...pointMarkers, defaultPointMarker(selectedMarkerPoint!)];
    }
    // }
    // return [];
    // }
  }

  Future<void> showPlaceInfo(Place place) async {
    await showCupertinoModalBottomSheet(
      barrierColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) {
        return placeInfo(place);
      },
    );
    selectedMarkerKey = null;
    selectedMarkerPoint = null;
    selectedPolyPoints = null;
  }

  Marker defaultPointMarker(LatLng point) {
    return Marker(
      width: 100.0,
      height: 100.0,
      point: point,
      // anchorPos: AnchorPos.align(AnchorAlign.top),
      builder: (ctx) => Stack(
        children: [
          Positioned(
            bottom: 50,
            left: 25,
            child: Image.asset(
              "assets/images/focus.png",
              width: 50,
              height: 50,
            ),
          ),
        ],
      ),
    );
  }

  Marker defaultPolyMarker(LatLng point) {
    return Marker(
      width: 20.0,
      height: 20.0,
      point: point,
      // anchorPos: AnchorPos.align(AnchorAlign.top),
      builder: (ctx) => Container(
        // width: 20,
        // height: 20,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryDark, width: 4),
          borderRadius: BorderRadius.circular(100),
          color: Colors.white,
        ),
      ),
    );
  }

  Widget placeInfo(Place place) {
    switch (place.type) {
      case "marker":
        _animatedMapMove(place.point!, HomeController.to.mapController.zoom);
        break;
      case "polygon":
        final centerZoom = HomeController.to.mapController
            .centerZoomFitBounds(LatLngBounds.fromPoints(place.polygons!));
        _animatedMapMove(centerZoom.center, centerZoom.zoom);
        break;
      case "line":
        final centerZoom = HomeController.to.mapController
            .centerZoomFitBounds(LatLngBounds.fromPoints(place.polylines!));
        _animatedMapMove(centerZoom.center, centerZoom.zoom);
        break;

      case "circle":
        _animatedMapMove(place.point!, HomeController.to.mapController.zoom);
        break;
      default:
    }
    return WillPopScope(
      onWillPop: () {
        modalBottomSheetExpand = false;
        setState(() {});
        return Future.value(true);
      },
      child: StatefulBuilder(builder: (context, setState) {
        final infoPlaceBottomSheetScollController = ScrollController();

        // Setup the listener.
        infoPlaceBottomSheetScollController.addListener(() {
          // logger
          //     .i(infoPlaceBottomSheetScollController.position.minScrollExtent);
          if (infoPlaceBottomSheetScollController.position.atEdge) {
            bool isTop =
                infoPlaceBottomSheetScollController.position.pixels == 0;
            if (isTop) {
              modalBottomSheetExpand = false;
              setState(() {});
            }
          }
        });

        return GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 5) {
              modalBottomSheetExpand = false;
              setState(() {});
            } else if (details.delta.dy < -5) {
              modalBottomSheetExpand = true;
              if (infoPlaceBottomSheetScollController.hasClients) {
                infoPlaceBottomSheetScollController.animateTo(1,
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut);
              }
              setState(() {});
            }
          },
          child: Container(
            width: Get.size.width,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: const BoxDecoration(),
            child: modalBottomSheetExpand
                // 확장
                ? ListView(
                    controller: infoPlaceBottomSheetScollController,
                    physics: const ClampingScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      buildModalIndicator(),
                      const SizedBox(height: 30),
                      FutureBuilder<AppUser?>(
                          future:
                              FirebaseSerivce.findUserByEmail(place.userEmail),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Container();
                            }
                            final user = snapshot.data!;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    UserProfileCircleImage(
                                        imageUrl: user.profileImage),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name ?? "",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(user.nickname ?? ""),
                                      ],
                                    )
                                  ],
                                ),
                                PopupMenuButton(
                                  onSelected: (value) async {
                                    switch (value) {
                                      case "edit":
                                        handleEditPost(place);
                                        break;
                                      case "share":
                                        handleSharePost(place);
                                        break;
                                      case "delete":
                                        handleDeletePost(place);
                                        break;
                                      default:
                                    }
                                  },
                                  itemBuilder: (context) {
                                    return POPUP_MENU_ITEMS;
                                  },
                                )
                              ],
                            );
                          }),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          place.name,
                          style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.text,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      buildImageCarousel(place, setState),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => handleShareLocation(place),
                        child: Row(
                          children: [
                            Text(
                              place.address ?? "-",
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.text),
                            ),
                            const SizedBox(width: 4),
                            Image.asset(
                              "assets/images/marker.png",
                              width: 17,
                              height: 17,
                            ),
                          ],
                        ),
                      ),
                      place.point != null
                          ? GestureDetector(
                              onTap: () => handleShareLocation(place),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 5),
                                      Text("위도: ${place.point!.latitude}",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.text)),
                                      const SizedBox(height: 5),
                                      Text("경도: ${place.point!.longitude}",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.text)),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  Image.asset(
                                    "assets/images/marker.png",
                                    width: 17,
                                    height: 17,
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      const SizedBox(height: 8),
                      place.keywords != null && place.keywords!.isNotEmpty
                          ? Wrap(
                              children: place.keywords!
                                  .map((keyword) => GestureDetector(
                                        onTap: () {
                                          Get.to(() =>
                                              ThePlaceScreen(tag: keyword));
                                        },
                                        child: Text(
                                          "#$keyword",
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.primary),
                                        ),
                                      ))
                                  .toList())
                          : Container(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.asset(
                                "assets/images/button-heart.png",
                                width: 25,
                                height: 25,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.asset(
                                "assets/images/button-comment.png",
                                width: 25,
                                height: 25,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.asset(
                                "assets/images/button-bookmark.png",
                                width: 25,
                                height: 25,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              handleSavePost(place);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.asset(
                                "assets/images/button-folder.png",
                                width: 25,
                                height: 25,
                              ),
                            ),
                          ),
                        ],
                      ),
                      place.description == null || place.description!.isEmpty
                          ? Container()
                          : const SizedBox(height: 15),
                      place.description == null || place.description!.isEmpty
                          ? Container()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("상세 설명"),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(place.description ?? ""),
                                  ),
                                )
                              ],
                            ),
                      const SizedBox(height: 15),
                      const Text("저장 날짜"),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                              DateFormat("yyyy-MM-dd HH:mm")
                                  .format(place.updatedAt),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.text)),
                        ),
                      )
                    ],
                  )
                : ListView(
                    physics: const ClampingScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      buildModalIndicator(),
                      // const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: PopupMenuButton(
                          onSelected: (value) async {
                            switch (value) {
                              case "edit":
                                handleEditPost(place);
                                break;
                              case "share":
                                handleSharePost(place);
                                break;
                              case "delete":
                                handleDeletePost(place);
                                break;
                              default:
                            }
                          },
                          itemBuilder: (context) {
                            return POPUP_MENU_ITEMS;
                          },
                        ),
                      ),
                      // const SizedBox(height: 10),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: Get.size.width / 3,
                              height: Get.size.width / 3,
                              child: buildImageCarousel(place, setState),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: AppColors.text,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => handleShareLocation(place),
                                  child: Row(
                                    children: [
                                      Text(
                                        place.address ?? "-",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.text),
                                      ),
                                      const SizedBox(width: 4),
                                      Image.asset(
                                        "assets/images/marker.png",
                                        width: 17,
                                        height: 17,
                                      ),
                                    ],
                                  ),
                                ),
                                place.point != null
                                    ? GestureDetector(
                                        onTap: () => handleShareLocation(place),
                                        child: Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 5),
                                                Text(
                                                    "위도: ${place.point?.latitude.toPrecision(5) ?? ""}",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.text)),
                                                const SizedBox(height: 5),
                                                Text(
                                                    "경도: ${place.point?.longitude.toPrecision(5) ?? ""}",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.text)),
                                              ],
                                            ),
                                            const SizedBox(width: 4),
                                            Image.asset(
                                              "assets/images/marker.png",
                                              width: 17,
                                              height: 17,
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(),
                                const SizedBox(height: 8),
                                place.keywords != null &&
                                        place.keywords!.isNotEmpty
                                    ? Wrap(
                                        children: place.keywords!
                                            .map((keyword) => GestureDetector(
                                                  onTap: () {
                                                    Get.to(() => ThePlaceScreen(
                                                        tag: keyword));
                                                  },
                                                  child: Text(
                                                    "#$keyword",
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            AppColors.primary),
                                                  ),
                                                ))
                                            .toList()
                                        // [
                                        //   Text(place.keywords!.join("#"),
                                        //       style: const TextStyle(
                                        //           fontSize: 16, color: AppColors.primary)),
                                        // ],
                                        )
                                    : Container(),
                                const SizedBox(height: 8),
                                // Text(place.description ?? "",
                                //     style: const TextStyle(
                                //         fontSize: 16,
                                //         color: AppColors.text)),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        EasyLoading.showInfo("heart");
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Image.asset(
                                          "assets/images/button-heart.png",
                                          width: 30,
                                          height: 30,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        EasyLoading.showInfo("comment");
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Image.asset(
                                          "assets/images/button-comment.png",
                                          width: 30,
                                          height: 30,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        EasyLoading.showInfo("bookmark");
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Image.asset(
                                          "assets/images/button-bookmark.png",
                                          width: 30,
                                          height: 30,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        handleSavePost(place);
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Image.asset(
                                          "assets/images/button-folder.png",
                                          width: 30,
                                          height: 30,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ]),
                    ],
                  ),
          ),
        );
      }),
    );
    // });
    // });
  }

  Widget buildImageCarousel(
      Place place, void Function(void Function()) setState) {
    if (place.photos.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          "assets/images/default_place.jpg",
          // height: Get.size.width / 2,
          // width: Get.size.width,
          // fit: BoxFit.contain,
        ),
      );
    }

    if (place.photos.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
            width: Get.size.width,
            height: Get.size.width,
            margin: const EdgeInsets.symmetric(horizontal: 5.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: place.photos.first,
                fit: BoxFit.cover,
              ),
            )),
      );
    }

    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
              enlargeCenterPage: false,
              aspectRatio: 1,
              viewportFraction: 1,
              onPageChanged: (value, reason) {
                currentImageCarouselIndex = value.toDouble();
                setState(() {});
              }),
          items: place.photos.map((image) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                    width: Get.size.width,
                    height: Get.size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                      ),
                    ));
              },
            );
          }).toList(),
        ),
        place.photos.length <= 1
            ? Container()
            : Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: DotsIndicator(
                  decorator: DotsDecorator(
                    color: Colors.grey.shade400,
                    activeColor: Colors.white,
                  ),
                  dotsCount: place.photos.length,
                  position: currentImageCarouselIndex,
                ),
              )
      ],
    );
  }

  Center buildModalIndicator() {
    return Center(
      child: Container(
        width: 30,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.grey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  CircleMarker defaultCircleMarker(LatLng point, String? color) {
    return CircleMarker(
      point: point,
      color: color != null
          ? HexColor.fromHex(color).withOpacity(0.5)
          : AppColors.skyBlue.withOpacity(0.5),
      borderStrokeWidth: 0,
      useRadiusInMeter: true,
      radius: circleRadius,
    );
  }

  Future<void> handleDeletePost(Place place) async {
    if (place.userEmail != UserService.to.currentUser.value?.email) {
      EasyLoading.showError("본인의 글만 삭제 가능합니다.");
      return;
    }
    Get.dialog(
      AppDefaultDialog(
        title: "삭제 확인",
        subTitle: "정말로 삭제하시겠습니까?",
        onOk: () async {
          await FirebaseSerivce.deletePlace(place);
          await PlaceService.to.fetchMyPlaces();
          Get.back();
          Get.back();
          modalBottomSheetExpand = false;
        },
      ),
    );
  }

  Future<void> handleSavePost(Place place) async {
    await FirebaseSerivce.subscribePlace(place, true);
    if (place.userEmail == FirebaseAuth.instance.currentUser!.email) {
      Get.to(() => MyPlaceDetailScreen(categoryName: place.category ?? "없음"));
    } else {
      Get.back();
      Get.back();
      NavigationController.to.currentBottomMenuIndex.value = 3;
    }
  }

  Future<void> handleSharePost(Place place) async {
    try {
      final LocationTemplate defaultLocation = LocationTemplate(
        address: place.address!,
        content: Content(
          title: place.name,
          description: place.description,
          imageUrl: place.photos.isEmpty
              ? Uri.parse(
                  "https://firebasestorage.googleapis.com/v0/b/naegot-9e987.appspot.com/o/default_place.jpg?alt=media&token=24194207-3cc1-4295-9d73-de19a504eaf9")
              : Uri.parse(place.photos.first),
          link: Link(
            webUrl: Uri.parse(
                'https://map.naver.com/appLink.naver?app=Y&pinType=site&lng=${place.point!.longitude}&appMenu=location&menu=location&title=${place.name}&version=2&lat=${place.point!.latitude}#applink'),
            mobileWebUrl: Uri.parse(
                'https://m.map.naver.com/appLink.naver?app=Y&pinType=site&lng=${place.point!.longitude}&appMenu=location&menu=location&title=${place.name}&version=2&lat=${place.point!.latitude}#applink'),
          ),
        ),
      );

      Uri uri =
          await ShareClient.instance.shareDefault(template: defaultLocation);
      await ShareClient.instance.launchKakaoTalk(uri);
      print('카카오톡 공유 완료');
    } catch (error) {
      print('카카오톡 공유 실패 $error');
    }
  }

  Future<void> handleEditPost(Place place) async {
    if (place.userEmail != UserService.to.currentUser.value?.email) {
      EasyLoading.showError("본인의 글만 수정 가능합니다.");
      return;
    }
    await showModalBottomSheet<bool>(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return SizedBox(
              height: Get.size.height * 0.8,
              child: EditPlaceScreen(place: place),
            );
          });
        });
    PlaceService.to.fetchMyPlaces();
    setState(() {});
  }

  void handleShareLocation(Place place) {
    Get.dialog(ShareDialog(
      place: place,
      shareLocationType: ShareLocationType.address,
    ));
  }
}
