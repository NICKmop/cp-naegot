import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naegot/extensions/colors.extension.dart';
import 'package:naegot/models/place.model.dart';
import 'package:naegot/screens/place_detail.screen.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/services/user.service.dart';

class MyPlaceDetailScreen extends StatefulWidget {
  const MyPlaceDetailScreen({Key? key, required this.categoryName})
      : super(key: key);
  final String categoryName;

  @override
  State<MyPlaceDetailScreen> createState() => _MyPlaceScreenState();
}

class _MyPlaceScreenState extends State<MyPlaceDetailScreen> {
  String orderBy = "createdAt";
  @override
  Widget build(BuildContext context) {
    final userService = Get.find<UserService>();

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
          child: Obx(
        () => userService.currentUser.value == null
            ? Container()
            : ListView(
                shrinkWrap: true,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Text(
                          "폴더 [${widget.categoryName}]",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 12),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            items: const [
                              DropdownMenuItem(
                                value: "createdAt",
                                child: Text("등록순"),
                              ),
                              DropdownMenuItem(
                                value: "abc",
                                child: Text("이름순"),
                              ),
                            ],
                            value: orderBy,
                            onChanged: (value) {
                              if (value != null) {
                                orderBy = value;
                                setState(() {});
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  buildPlacesByCategory(),
                ],
              ),
      )),
    );
  }

  Widget buildPlacesByCategory() {
    var categories = UserService.to.currentUser.value!.categories;

    if (orderBy == "createdAt") {
      UserService.to.getCurrentUser();
      categories = UserService.to.currentUser.value!.categories;
    } else {
      categories.sort();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseSerivce.getMyPlaceStreamByCategory(widget.categoryName),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.size == 0) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text("등록된 장소가 없습니다."),
              ),
            );
          }

          final List<Place> places = snapshot.data!.docs
              .map((doc) => Place.fromMap(doc.data()))
              .toList();

          if (orderBy == "createdAt") {
            places.sort((a, b) => a.createdAt.isBefore(b.createdAt) ? -1 : 1);
          } else {
            places.sort((a, b) => a.name.compareTo(b.name));
          }

          return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final place = places[index];
                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                          color: HexColor.fromHex(place.color),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white, width: 2)),
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
                  title: Text(place.name),
                  subtitle: Text(place.address ?? ""),
                  onTap: () {
                    Get.back();
                    Get.to(() => PlaceDetailScreen(place: place));
                    // NavigationController.to.currentBottomMenuIndex.value = 0;
                    // HomeController.to.mapController.move(place.point!, 16);
                  },
                );
              },
              separatorBuilder: (context, index) => const Divider(),
              itemCount: places.length);
        });
  }
}
