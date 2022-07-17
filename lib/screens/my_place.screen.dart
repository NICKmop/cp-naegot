import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:group_list_view/group_list_view.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/constants/common.constants.dart';
import 'package:naegot/dialogs/add_category.dialog.dart';
import 'package:naegot/dialogs/app_default_dialog.dart';
import 'package:naegot/dialogs/edit_category_dialog.dart';
import 'package:naegot/extensions/colors.extension.dart';
import 'package:naegot/models/app_user.model.dart';
import 'package:naegot/models/place.model.dart';
import 'package:naegot/screens/my_place_detail.screen.dart';
import 'package:naegot/screens/place_detail.screen.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/services/user.service.dart';
import 'package:naegot/utils/logger.service.dart';

class MyPlaceScreen extends StatefulWidget {
  const MyPlaceScreen({Key? key}) : super(key: key);

  @override
  State<MyPlaceScreen> createState() => _MyPlaceScreenState();
}

class _MyPlaceScreenState extends State<MyPlaceScreen> {
  String orderBy = "createdAt";
  @override
  Widget build(BuildContext context) {
    final userService = Get.find<UserService>();

    return Scaffold(
        appBar: AppBar(
          leading: Container(),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: TextButton(
                onPressed: () {
                  Get.dialog(const AddCategoryDialog());
                },
                child: const Text(
                  "+ 카테고리 추가",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseSerivce.getCurrentUserStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text("유저 정보를 찾을 수 없습니다.");
                }
                final user = AppUser.fromMap(snapshot.data!.data()!);
                return ListView(
                  shrinkWrap: true,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        children: [
                          const Text("폴더"),
                          const SizedBox(width: 4),
                          Text(
                            user.categories.length.toString(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
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
                    const Padding(
                      padding: EdgeInsets.only(left: 30.0, top: 10),
                      child: Text("내 장소"),
                    ),
                    buildCategoryGroupListView(
                        user.categories, user.invisibleCategories),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, top: 20),
                      child: Row(
                        children: [
                          Checkbox(
                              value: user.showSubscribePlaces,
                              onChanged: (value) async {
                                if (value != null) {
                                  FirebaseSerivce.changeShowSubscribePlaces(
                                      value);
                                }
                              }),
                          const Text("저장한 장소"),
                        ],
                      ),
                    ),
                    user.subscribes.isEmpty
                        ? const Center(
                            child: Padding(
                            padding: EdgeInsets.only(top: 20.0),
                            child: Text("저장한 장소가 없습니다."),
                          ))
                        : ListView.separated(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            separatorBuilder: (context, index) =>
                                const Divider(height: 0),
                            shrinkWrap: true,
                            itemCount: user.subscribes.length,
                            itemBuilder: (context, index) {
                              List<String> subscribes = [];
                              var placeId = "";
                              if (orderBy == "createdAt") {
                                subscribes = user.subscribes.reversed.toList();
                                placeId = subscribes[index];
                              } else {
                                subscribes = [...user.subscribes];
                                subscribes.sort();
                                placeId = subscribes[index];
                              }
                              return FutureBuilder<Place?>(
                                  future: FirebaseSerivce.getPlace(placeId),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Container();
                                    }
                                    final place = snapshot.data!;
                                    return ListTile(
                                      dense: true,
                                      contentPadding:
                                          const EdgeInsets.only(left: 20),
                                      onTap: () {
                                        Get.to(() =>
                                            PlaceDetailScreen(place: place));
                                      },
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          padding: const EdgeInsets.all(0),
                                          decoration: BoxDecoration(
                                              color:
                                                  HexColor.fromHex(place.color),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 2)),
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
                                      title: Text(
                                        place.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        place.address ?? '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: PopupMenuButton(
                                        itemBuilder: (context) {
                                          return [
                                            PopupMenuItem(
                                                value: "share",
                                                child: TextButton.icon(
                                                  icon: const Icon(
                                                    Icons.share,
                                                    color: Colors.black54,
                                                  ),
                                                  label: const Text(
                                                    "공유",
                                                    style: TextStyle(
                                                        color: Colors.black54),
                                                  ),
                                                  onPressed: null,
                                                )),
                                            PopupMenuItem(
                                                value: "delete",
                                                child: TextButton.icon(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.black54,
                                                  ),
                                                  label: const Text(
                                                    "삭제",
                                                    style: TextStyle(
                                                        color: Colors.black54),
                                                  ),
                                                  onPressed: null,
                                                ))
                                          ];
                                        },
                                        onSelected: (value) {
                                          switch (value) {
                                            case "share":
                                              break;
                                            case "delete":
                                              Get.dialog(
                                                AppDefaultDialog(
                                                  title: "저장한 장소 삭제",
                                                  subTitle:
                                                      "저장한 장소에서 삭제하시겠습니까?",
                                                  okText: "삭제",
                                                  onOk: () async {
                                                    EasyLoading.show(
                                                        status:
                                                            "저장한 장소 삭제 중입니다.");
                                                    await FirebaseSerivce
                                                        .subscribePlace(
                                                            place, false);
                                                    setState(() {});
                                                    EasyLoading.dismiss();
                                                    Get.back();
                                                  },
                                                  cancelText: "취소",
                                                ),
                                              );
                                              break;
                                            default:
                                          }
                                        },
                                      ),
                                    );
                                  });
                            },
                          )
                  ],
                );
              }),
        ));
  }

  Widget buildCategoryGroupListView(
      List<String> categories, List<String> invisibleCategories) {
    if (orderBy == "createdAt") {
      categories = [...categories];
    } else {
      categories.sort();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseSerivce.getMyPlaceStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Text("등록된 장소가 없습니다."),
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

          return GroupListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 0),
            shrinkWrap: true,
            countOfItemInSection: (index) {
              return places
                  .where((place) => place.category == categories[index])
                  .length;
            },
            sectionsCount: categories.length,
            groupHeaderBuilder: (context, index) {
              return ListTile(
                onTap: () {
                  Get.to(() =>
                      MyPlaceDetailScreen(categoryName: categories[index]));
                },
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 0,
                ),
                title: Row(
                  children: [
                    Checkbox(
                        value: !invisibleCategories.contains(categories[index]),
                        onChanged: (value) async {
                          if (value == null) return;
                          await FirebaseSerivce.changeCategoryVisible(
                              categories[index], value);
                        }),
                    Image.asset("assets/images/folder.png", width: 30),
                    const SizedBox(width: 12),
                    Text(categories[index]),
                    const SizedBox(width: 4),
                    Text(
                      "(${places.where((place) => place.category == categories[index]).length})",
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                          value: "edit",
                          child: TextButton.icon(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.black54,
                            ),
                            label: const Text(
                              "편집",
                              style: TextStyle(color: Colors.black54),
                            ),
                            onPressed: null,
                          )),
                      PopupMenuItem(
                          value: "delete",
                          child: TextButton.icon(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.black54,
                            ),
                            label: const Text(
                              "삭제",
                              style: TextStyle(color: Colors.black54),
                            ),
                            onPressed: null,
                          ))
                    ];
                  },
                  onSelected: (value) {
                    switch (value) {
                      case "edit":
                        Get.dialog(EditCategoryDialog(
                            categoryText: categories[index]));
                        break;
                      case "share":
                        break;
                      case "delete":
                        Get.dialog(
                          AppDefaultDialog(
                            title: "카테고리 삭제",
                            subTitle: "카테고리와 등록된 장소가 삭제 됩니다.\n정말로 삭제 하시겠습니까?",
                            okText: "삭제",
                            onOk: () async {
                              EasyLoading.show(status: "카테고리 삭제중입니다.");
                              final errorMessage =
                                  await FirebaseSerivce.deleteCategory(
                                      categories[index]);
                              EasyLoading.dismiss();
                              if (errorMessage != null) {
                                EasyLoading.showError(errorMessage);
                              }
                              Get.back();
                            },
                            cancelText: "취소",
                          ),
                        );
                        break;
                      default:
                    }
                  },
                ),
              );
            },
            itemBuilder: (context, index) {
              return Container();
            },
            // separatorBuilder: (context, index) => const Divider(height: 1),
            sectionSeparatorBuilder: (context, index) =>
                const Divider(height: 1),
          );
        });
  }
}
