import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_dragmarker/dragmarker.dart';
import 'package:flutter_map_line_editor/polyeditor.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:latlong2/latlong.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/constants/common.constants.dart';
import 'package:naegot/controllers/map.controller.dart';
import 'package:naegot/controllers/navigation.controller.dart';
import 'package:naegot/dialogs/app_default_dialog.dart';
import 'package:naegot/dialogs/share.dialog.dart';
import 'package:naegot/extensions/colors.extension.dart';
import 'package:naegot/models/app_user.model.dart';
import 'package:naegot/models/place.model.dart';
import 'package:naegot/screens/my_place.screen.dart';
import 'package:naegot/screens/the_place.screen.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/services/place.service.dart';
import 'package:naegot/services/user.service.dart';
import 'package:naegot/widgets/user_profile_image.widget.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

import 'my_place_detail.screen.dart';

enum MapPlaceType { marker, line, circle, polygon }

// ignore: non_constant_identifier_names
final MAP_INITIAL_CENTER_LOCATION = LatLng(37.5547125, 126.9707878);

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({Key? key, required this.place}) : super(key: key);
  final Place place;

  @override
  State<PlaceDetailScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<PlaceDetailScreen>
    with TickerProviderStateMixin {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  bool showMyPlace = true;
  bool showSavedPlace = true;

  bool isEditMode = false;
  var mapPlaceType = MapPlaceType.marker;

  late PolyEditor polyEditor;

  LatLng centerLocation = MAP_INITIAL_CENTER_LOCATION;
  LatLng? selectedMarkerPoint;

  String? selectedMarkerKey;
  // Place? selectedPlace;

  bool modalBottomSheetExpand = false;

  double currentImageCarouselIndex = 0;

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
    strokeCap: StrokeCap.square,
    points: [],
    strokeWidth: 5,
  );

  List<CircleMarker> circleMarkers = [];
  var testCircle = [];

  @override
  void initState() {
    super.initState();

    selectedMarkerKey = widget.place.createdAt.toString();

    polyEditor = PolyEditor(
      addClosePathMarker: true,
      points: [...testPolygon.points, ...testPolyline.points],
      pointIcon: Image.asset("assets/images/focus.png"),
      intermediateIcon: const Icon(Icons.lens, size: 150, color: Colors.grey),
      callbackRefresh: () => {setState(() {})},
    );
    polygons.add(testPolygon);
    polylines.add(testPolyline);

    Future.delayed(const Duration(milliseconds: 500), () {
      showPlaceInfo(widget.place);
    });
  }

  @override
  Widget build(BuildContext context) {
    polylines = [];
    polygons = [];
    circleMarkers = [];

    if (widget.place.type == "line") {
      var polyline = Polyline(
        color: HexColor.fromHex(widget.place.color),
        points: widget.place.polylines!,
        strokeWidth: 5,
        borderStrokeWidth: 5,
        borderColor: selectedMarkerKey == widget.place.createdAt.toString()
            ? Colors.white
            : Colors.transparent,
      );
      polylines.add(polyline);
    }

    if (widget.place.type == "polygon") {
      var polygon = Polygon(
        borderColor: selectedMarkerKey == widget.place.createdAt.toString()
            ? Colors.white
            : Colors.transparent,
        borderStrokeWidth: 3,
        color: HexColor.fromHex(widget.place.color).withOpacity(0.5),
        points: widget.place.polygons!,
        isFilled: true,
        label: widget.place.name,
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
    }

    if (widget.place.type == "circle") {
      circleMarkers.add(
        CircleMarker(
          point: widget.place.point!,
          color: HexColor.fromHex(widget.place.color).withOpacity(0.5),
          borderStrokeWidth: 5,
          borderColor: selectedMarkerKey == widget.place.createdAt.toString()
              ? Colors.white
              : Colors.transparent,
          useRadiusInMeter: true,
          radius: CIRCLE_RADIUS, // 2000, meters | 2 km
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: Row(
              children: [
                Text(widget.place.name),
              ],
            )),
        body: Stack(
          children: [
            Positioned(
              child: KeyboardDismissOnTap(
                child: FlutterMap(
                  mapController: MapController(),
                  options: MapOptions(
                    onTap: (tapPosition, point) {
                      selectedMarkerKey = null;
                      setState(() {});
                      for (var polygon in polygons) {
                        final isInside = mp.PolygonUtil.containsLocation(
                            mp.LatLng(point.latitude, point.longitude),
                            polygon.points
                                .map((point) =>
                                    mp.LatLng(point.latitude, point.longitude))
                                .toList(),
                            true);
                        if (isInside) {
                          selectedMarkerKey = widget.place.createdAt.toString();
                          showPlaceInfo(widget.place);
                          setState(() {});
                          return;
                        }
                      }

                      for (var polyline in polylines) {
                        final distance = mp.PolygonUtil.locationIndexOnPath(
                            mp.LatLng(point.latitude, point.longitude),
                            polyline.points
                                .map((point) =>
                                    mp.LatLng(point.latitude, point.longitude))
                                .toList(),
                            true,
                            tolerance: 10);
                        if (distance != -1) {
                          selectedMarkerKey = widget.place.createdAt.toString();
                          showPlaceInfo(widget.place);
                          setState(() {});
                          return;
                        }
                      }

                      for (var circleMarker in circleMarkers) {
                        final distance =
                            mp.SphericalUtil.computeDistanceBetween(
                          mp.LatLng(point.latitude, point.longitude),
                          mp.LatLng(circleMarker.point.latitude,
                              circleMarker.point.longitude),
                        );
                        if (distance <= CIRCLE_RADIUS) {
                          selectedMarkerKey = widget.place.createdAt.toString();
                          showPlaceInfo(widget.place);
                          setState(() {});
                          return;
                        }
                      }
                    },
                    allowPanningOnScrollingParent: false,
                    center: widget.place.point,
                    zoom: 15.0,
                    minZoom: 6,
                    maxZoom: MapService.to.mapType.value == MapType.normal
                        ? 17.4
                        : 15,
                    plugins: [
                      DragMarkerPlugin(),
                    ],
                  ),
                  layers: [
                    TileLayerOptions(
                      urlTemplate:
                          "http://{s}.google.com/vt/lyrs=${MapService.to.mapType.value == MapType.normal ? "m" : "s"}&hl=ko&gl=KR&x={x}&y={y}&z={z}",
                      subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
                      retinaMode: true,
                      tileProvider: NetworkTileProvider(),
                    ),
                    PolygonLayerOptions(polygons: polygons),
                    PolylineLayerOptions(polylines: polylines),
                    CircleLayerOptions(
                        circles:
                            !isEditMode ? [...circleMarkers] : [...testCircle]),
                    DragMarkerPluginOptions(markers: polyEditor.edit()),
                    MarkerLayerOptions(markers: makeMarkers([widget.place])),
                  ],
                ),
              ),
            ),
            // Positioned(
            //     top: 40,
            //     left: 20,
            //     child: IconButton(
            //       icon: const Icon(Icons.arrow_back_ios),
            //       onPressed: () {
            //         Get.back();
            //       },
            //     ))
          ],
        ));
  }

  List<Marker> makeMarkers(List<Place>? places) {
    // 편집모드 일경우
    // if (isEditMode) {
    // 추가된 포인트 마커가 있을경우
    // if (selectedMarkerPoint != null) {

    final pointMarkers =
        places!.where((marker) => marker.type == "marker").map((place) {
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
            // selectedPlace = place;
            selectedMarkerKey = place.createdAt.toString();
            setState(() {});
            showPlaceInfo(place);
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

  Future<dynamic> showPlaceInfo(Place place) async {
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
    // selectedPolyPoints = null;
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
      width: 10.0,
      height: 10.0,
      point: point,
      // anchorPos: AnchorPos.align(AnchorAlign.top),
      builder: (ctx) => Container(
        color: Colors.grey,
      ),
    );
  }

  Widget placeInfo(Place place) {
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
                                      case "share":
                                        handleSharePost(place);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) {
                                    return POPUP_MENU_ITEMS_OTHERS;
                                  },
                                )
                              ],
                            );
                          }),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      .toList()
                                  // [
                                  //   Text(place.keywords!.join("#"),
                                  //       style: const TextStyle(
                                  //           fontSize: 16, color: AppColors.primary)),
                                  // ],
                                  )
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
                          place.description == null ||
                                  place.description!.isEmpty
                              ? Container()
                              : const SizedBox(height: 15),
                          place.description == null ||
                                  place.description!.isEmpty
                              ? Container()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("상세 설명"),
                                    SizedBox(
                                      width: Get.size.width,
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(place.description ?? ""),
                                        ),
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
                    ],
                  )
                : ListView(
                    physics: const ClampingScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      buildModalIndicator(),
                      // const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: PopupMenuButton(
                          onSelected: (value) async {
                            switch (value) {
                              case "share":
                                handleSharePost(place);
                                break;
                            }
                          },
                          itemBuilder: (context) {
                            return POPUP_MENU_ITEMS_OTHERS;
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
        child: Image.asset("assets/images/default_place.jpg"),
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
          : AppColors.skyBlue,
      borderStrokeWidth: 0,
      useRadiusInMeter: true,
      radius: CIRCLE_RADIUS, // 2000, meters | 2 km
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

  void handleShareLocation(Place place) {
    Get.dialog(ShareDialog(
      place: place,
      shareLocationType: ShareLocationType.address,
    ));
  }
}
