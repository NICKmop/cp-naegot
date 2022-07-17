import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/controllers/home.controller.dart';
import 'package:naegot/controllers/navigation.controller.dart';
import 'package:naegot/models/place.model.dart';
import 'package:naegot/screens/place_detail.screen.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/services/place.service.dart';
import 'package:naegot/utils/logger.service.dart';

class ThePlaceScreen extends StatefulWidget {
  const ThePlaceScreen({Key? key, this.tag}) : super(key: key);
  final String? tag;

  @override
  State<ThePlaceScreen> createState() => _ThePlaceScreenState();
}

class _ThePlaceScreenState extends State<ThePlaceScreen> {
  String searchText = "";
  final searchController = TextEditingController();
  List<String> topKeywords = [];
  @override
  void initState() {
    if (widget.tag != null) {
      searchText = widget.tag!;
      searchController.text = widget.tag!;
    }
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.tag == null ? null : AppBar(),
      body: SafeArea(
        child: SizedBox(
          width: Get.size.width,
          height: Get.size.height,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            children: [
              CupertinoSearchTextField(
                controller: searchController,
                prefixIcon: const Icon(Icons.search),
                placeholder: "장소 혹은 키워드를 검색해보세요.",
                placeholderStyle:
                    const TextStyle(fontSize: 14, color: AppColors.hintText),
                onChanged: (value) {
                  searchText = value;
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseSerivce.getAllPlaceStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text("등록된 장소가 없습니다."),
                      );
                    }

                    final List<Place> places = snapshot.data!.docs
                        .map((doc) => Place.fromMap(doc.data()))
                        .toList();

                    var filteredPlaces = places;
                    if (searchText.isNotEmpty) {
                      filteredPlaces = filteredPlaces
                          .where((place) =>
                              place.address!.contains(searchText) ||
                              place.name.contains(searchText) ||
                              (place.keywords != null &&
                                  place.keywords!.contains(searchText)))
                          .toList();
                    }

                    final expandedKeywords = places
                        .where((element) =>
                            element.keywords != null &&
                            element.keywords!.isNotEmpty)
                        .map((e) => e.keywords)
                        .toList()
                        .expand((element) => element!)
                        .toList();
                    // .map((e) => topKeywords[e.trim()] =
                    //     topKeywords[e.trim()] ?? 0 + 1);

                    // logger.i(expandedKeywords);
                    Map<String, int> keywordsMap = {};

                    for (var k in expandedKeywords) {
                      keywordsMap[k] = (keywordsMap[k] ?? 0) + 1;
                    }

                    final sorted = SplayTreeMap<String, dynamic>.from(
                        keywordsMap,
                        (a, b) => keywordsMap[a]! > keywordsMap[b]! ? -1 : 1);
                    topKeywords = sorted.keys.take(3).toList();

                    if (filteredPlaces.isEmpty) {
                      return const Center(
                        child: Text("검색된 장소가 없습니다."),
                      );
                    }

                    return Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            alignment: WrapAlignment.start,
                            children: topKeywords
                                .map((e) => GestureDetector(
                                      onTap: () {
                                        searchText = e;
                                        searchController.text = e;
                                        setState(() {});
                                      },
                                      child: Container(
                                          margin: const EdgeInsets.only(
                                              right: 4, bottom: 4),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 10),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              // border: Border.all(
                                              //   color: AppColors.grey.withOpacity(0.2),
                                              // ),
                                              color: Colors.white,
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.grey,
                                                  offset: Offset(1, 1),
                                                  blurRadius: 1,
                                                )
                                              ]),
                                          child: Text("# $e")),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          itemCount: filteredPlaces.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                          physics: const ClampingScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final place = filteredPlaces[index];
                            return photoItem(place);
                          },
                        ),
                      ],
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget photoItem(Place place) {
    var clippedAddress = "";
    if (place.address == null) {
      clippedAddress = "-";
    } else if (place.address!.split(" ").length >= 2) {
      clippedAddress =
          "${place.address!.split(" ")[0]} ${place.address!.split(" ")[1]}";
    } else {
      clippedAddress = place.address!;
    }
    return GestureDetector(
      onTap: () {
        Get.to(() => PlaceDetailScreen(place: place));
        // NavigationController.to.currentBottomMenuIndex.value = 0;
        // if (PlaceService.to.myPlaces.value.firstWhereOrNull(
        //         (element) => element.createdAt == place.createdAt) ==
        //     null) {
        //   PlaceService.to.myPlaces.value.add(place);
        // }
        // HomeController.to.mapController.move(place.point!, 18);
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: place.photos.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: place.photos.first,
                    fit: BoxFit.cover,
                    width: Get.size.width / 2,
                    height: Get.size.width / 2,
                  )
                : Image.asset("assets/images/default_place.jpg"),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Text(
              clippedAddress,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 1.0,
                    color: Color.fromARGB(50, 0, 0, 0),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
