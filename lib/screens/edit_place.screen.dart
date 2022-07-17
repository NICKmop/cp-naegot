import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/dialogs/add_category.dialog.dart';
import 'package:naegot/extensions/colors.extension.dart';
import 'package:naegot/models/place.model.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/services/place.service.dart';
import 'package:naegot/services/user.service.dart';
import 'package:naegot/utils/get_xfile_from_url.dart';
import 'package:naegot/utils/logger.service.dart';
import 'package:naegot/widgets/app_hashtag_text_field.widget.dart';
import 'package:naegot/widgets/app_text_field.widget.dart';

class EditPlaceScreen extends StatefulWidget {
  const EditPlaceScreen({
    Key? key,
    required this.place,
    // required this.circleMarker,
  }) : super(key: key);

  final Place place;

  @override
  State<EditPlaceScreen> createState() => _AddPlaceState();
}

class _AddPlaceState extends State<EditPlaceScreen> {
  final formKey = GlobalKey<FormState>();
  String? category;
  final nameController = TextEditingController();
  final keywordController = TextEditingController();
  final descriptionController = TextEditingController();
  var markerColor = MarkerColors.red;
  IconData markerIcon = Icons.star_rate;

  final imagePicker = ImagePicker();
  List<XFile> markerImages = [];

  bool loading = false;
  bool showIconContainer = false;

  @override
  void initState() {
    category = widget.place.category;
    nameController.text = widget.place.name;
    markerColor = widget.place.color;
    markerIcon = IconData(
      widget.place.icon,
      fontFamily: "MaterialIcons",
    );
    keywordController.text =
        widget.place.keywords?.map((keyword) => "#$keyword").join(" ") ?? "";
    descriptionController.text = widget.place.description ?? "";
    fetchImages();
    super.initState();
  }

  fetchImages() async {
    List<XFile> images = [];
    for (var imageUrl in widget.place.photos) {
      final imageXFile = await getXfileFromImageUrl(imageUrl);
      images.add(imageXFile);
    }
    markerImages = images;
    setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    keywordController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Form(
        key: formKey,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              TextButton(
                onPressed: () async {
                  if (loading) return;
                  if (formKey.currentState!.validate()) {
                    if (keywordController.text.trim().isNotEmpty &&
                        keywordController.text
                            .trim()
                            .split(" ")
                            .every((e) => !e.startsWith("#"))) {
                      EasyLoading.showError("해시태그는 앞에 #을 붙여주세요.");
                      return;
                    }

                    if (keywordController.text
                            .trim()
                            .split(" ")
                            .where((keyword) => keyword.startsWith("#"))
                            .length >
                        3) {
                      EasyLoading.showError("해시태그는 3개 이하로 입력해주세요.");
                      return;
                    }

                    List<String> photos = [];
                    if (markerImages.isNotEmpty) {
                      for (var markerImage in markerImages) {
                        final photoUrl =
                            await FirebaseSerivce.uploadImage(markerImage);
                        if (photoUrl != null) {
                          photos.add(photoUrl);
                        }
                      }
                    }
                    try {
                      EasyLoading.show(status: "장소를 수정중입니다.");

                      var data = {
                        "category": category,
                        "name": nameController.text.trim(),
                        "color": markerColor,
                        "icon": markerIcon.codePoint,
                        "keywords": keywordController.text
                            .trim()
                            .split("#")
                            .where(
                              (keyword) => keyword.trim().isNotEmpty,
                            )
                            .toList(),
                        "description": descriptionController.text.trim(),
                        "updatedAt": DateTime.now().millisecondsSinceEpoch,
                        "photos": photos,
                      };

                      loading = true;
                      setState(() {});
                      FirebaseSerivce.updatePlace(widget.place.id, data);
                      EasyLoading.showSuccess("장소를 수정하였습니다.");
                      await PlaceService.to.fetchMyPlaces();
                      Get.back();
                      Get.back();
                    } catch (e) {
                      logger.e(e);
                    } finally {
                      loading = false;
                      setState(() {});
                    }
                  }
                },
                child: const Text(
                  "수정",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            ],
          ),
          body: Container(
              color: Colors.white,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("카테고리 선택"),
                      TextButton(
                        onPressed: () {
                          Get.dialog(const AddCategoryDialog());
                        },
                        child: const Text("+ 카테고리 추가"),
                      )
                    ],
                  ),
                  // const SizedBox(height: 10),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 15,
                        ),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide:
                                const BorderSide(color: AppColors.hintBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide:
                                const BorderSide(color: AppColors.hintBorder)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                      hint: const Text("카테고리",
                          style: TextStyle(
                            fontSize: 14,
                          )),
                      value: category,
                      items: UserService.to.currentUser.value!.categories
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: const TextStyle(color: AppColors.black),
                              )))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          category = value;
                          // controller.ageSpan.value = value;
                        }
                      },
                      validator: (value) {
                        // if (value == null) {
                        //   return "선택x";
                        // }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("장소 이름"),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: nameController,
                    hintText: "장소의 이름을 입력해주세요.",
                    maxLength: 10,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "장소의 이름을 입력해주세요.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text("나의 아이콘"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      buildMarkerIconContainer(),
                      GestureDetector(
                        onTap: () {
                          showIconContainer = !showIconContainer;
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3.0),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade400,
                                  offset: const Offset(1, 1),
                                )
                              ]),
                          child: Icon(
                            markerIcon,
                            color: AppColors.black.withOpacity(0.7),
                            size: 16,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  showIconContainer ? buildIconContainer() : Container(),
                  const SizedBox(height: 20),
                  const Text("사진"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      markerImages.length < 3
                          ? GestureDetector(
                              onTap: () async {
                                if (markerImages.length < 3) {
                                  final markerImage =
                                      await imagePicker.pickImage(
                                    source: ImageSource.gallery,
                                    maxHeight: 1000,
                                    maxWidth: 1000,
                                  );
                                  if (markerImage != null) {
                                    markerImages.add(markerImage);
                                    setState(() {});
                                  }
                                } else {
                                  EasyLoading.showError("사진은 최대 3장까지 등록가능합니다.");
                                }
                              },
                              child: const Card(
                                elevation: 3,
                                child: SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                      child: Text(
                                        "+",
                                        style: TextStyle(
                                            color: AppColors.grey,
                                            fontSize: 40),
                                      ),
                                    )),
                              ),
                            )
                          : Container(),
                      markerImages.isEmpty
                          ? Container()
                          : Row(
                              children:
                                  markerImages.asMap().entries.map((entry) {
                                int index = entry.key;
                                var markerImage = entry.value;

                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(left: 5),
                                      padding: const EdgeInsets.all(2),
                                      width: 100,
                                      height: 100,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: Image.file(
                                          File(markerImage.path),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            markerImages.remove(markerImage);
                                            setState(() {});
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.grey,
                                                  offset: Offset(1, 1),
                                                  blurRadius: 2,
                                                )
                                              ],
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                            ),
                                          ),
                                        )),
                                    index == 0
                                        ? Positioned(
                                            bottom: 2,
                                            left: 7,
                                            right: 2,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  3),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  3)),
                                                  color: Colors.black
                                                      .withOpacity(0.7)),
                                              child: const Text(
                                                "대표사진",
                                                style: TextStyle(
                                                  color: AppColors.white,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ))
                                        : Container()
                                  ],
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("키워드"),
                  const SizedBox(height: 10),
                  AppHashTagTextField(
                    controller: keywordController,
                    hintText: "#해시태그를 입력해주세요.",
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("GPS 좌표"),
                      const SizedBox(height: 10),
                      Text("위도: ${widget.place.point!.latitude}"),
                      const SizedBox(height: 10),
                      Text("경도: ${widget.place.point!.longitude}"),
                      const SizedBox(height: 20),
                    ],
                  ),
                  const Text("상세 설명"),
                  const SizedBox(height: 10),
                  AppTextField(
                    textInputType: TextInputType.multiline,
                    controller: descriptionController,
                    hintText: "장소의 설명을 적어주세요.",
                    maxLines: 3,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    validator: (value) {
                      return null;
                    },
                  )
                ],
              )),
        ),
      ),
    );
  }

  SingleChildScrollView buildMarkerIconContainer() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: [
        MarkerColors.red,
        MarkerColors.orange,
        MarkerColors.yellow,
        MarkerColors.lightGreen,
        MarkerColors.green,
        MarkerColors.blue,
        MarkerColors.pink,
        MarkerColors.purple,
      ]
              .map((e) => GestureDetector(
                    onTap: () {
                      setState(() {
                        markerColor = e;
                        setState(() {});
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.only(right: 5.0),
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        border: markerColor == e
                            ? Border.all(color: AppColors.primary, width: 3)
                            : null,
                        // borderRadius: BorderRadius.circular(100),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: HexColor.fromHex(e),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        // child: Icon(
                        //   markerIcon,
                        //   color: AppColors.black.withOpacity(0.7),
                        //   size: 18,
                        // ),
                      ),
                    ),
                  ))
              .toList()),
    );
  }

  SingleChildScrollView buildIconContainer() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: [
        Icons.star_rate,
        Icons.groups,
        Icons.remove_red_eye,
        Icons.camera_alt,
        Icons.thumb_up,
        Icons.restaurant_menu,
        Icons.waves,
        Icons.favorite,
        Icons.forest,
        Icons.local_florist,
      ]
              .map((e) => GestureDetector(
                    onTap: () {
                      markerIcon = e;
                      showIconContainer = false;
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 3.0),
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        border: markerIcon == e
                            ? Border.all(color: AppColors.primary, width: 3)
                            : null,
                        // borderRadius: BorderRadius.circular(100),
                      ),
                      child: Icon(e, color: AppColors.black.withOpacity(0.7)),
                    ),
                  ))
              .toList()),
    );
  }
}
