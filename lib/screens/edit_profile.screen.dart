import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/controllers/edit_profile.controller.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/services/user.service.dart';
import 'package:naegot/utils/logger.service.dart';
import 'package:naegot/widgets/app_button.widget.dart';
import 'package:naegot/widgets/app_text_field.widget.dart';
import 'package:naegot/widgets/user_profile_image.widget.dart';

class EditProfileScreen extends GetView<EditProfileController> {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(EditProfileController());

    return Scaffold(
      appBar: AppBar(title: const Text("내 프로필 수정")),
      bottomSheet: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
          width: Get.size.width,
          child: AppButton(
            text: "완료",
            onPressed: () async {
              if (controller.formKey.currentState!.validate()) {
                try {
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(UserService.to.currentUser.value!.email)
                      .update(({
                        "nickname": controller.nicknameController.text.trim(),
                        "name": controller.nameController.text.trim(),
                        "phone": controller.phoneController.text.trim(),
                        "ageSpan": controller.ageSpan.value,
                        "address": controller.addressController.text.trim(),
                      }));
                  EasyLoading.showSuccess("프로필 수정 완료");
                  await FirebaseSerivce.getCurrentUser();
                  Get.back();
                } catch (e) {
                  logger.e(e);
                  EasyLoading.showSuccess("프로필 수정 실패");
                }
              }
            },
          ),
        ),
      ),
      body: SafeArea(
        child: KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
          return KeyboardDismissOnTap(
            child: Form(
              key: controller.formKey,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            logger.d("hello");
                            try {
                              final selectedImage =
                                  await controller.imagePicker.pickImage(
                                source: ImageSource.gallery,
                                maxHeight: 500,
                                maxWidth: 500,
                              );
                              final downloadUrl =
                                  await FirebaseSerivce.uploadImage(
                                      selectedImage);
                              if (downloadUrl == null) {
                                return;
                              }
                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(UserService.to.currentUser.value!.email)
                                  .update({
                                "profileImage": downloadUrl,
                              });

                              await FirebaseSerivce.getCurrentUser();
                            } catch (e) {
                              logger.e(e);
                            } finally {
                              EasyLoading.dismiss();
                            }
                          },
                          child: Obx(
                            () => UserProfileCircleImage(
                              imageUrl: UserService
                                  .to.currentUser.value!.profileImage,
                              size: 66,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey.shade200,
                              child: const Icon(
                                Icons.edit,
                                color: AppColors.black,
                                size: 15,
                              )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "닉네임",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  AppTextField(
                    controller: controller.nicknameController,
                    hintText: "닉네임",
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "이름",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  AppTextField(
                    controller: controller.nameController,
                    hintText: "이름",
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "휴대폰 번호",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  AppTextField(
                    inputFormatters: [
                      MaskTextInputFormatter(
                          mask: '###-####-####',
                          filter: {"#": RegExp(r'[0-9]')},
                          type: MaskAutoCompletionType.lazy)
                    ],
                    controller: controller.phoneController,
                    hintText: "휴대폰 번호",
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "연령대",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 15,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.hintBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.hintBorder)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_drop_down),
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    hint: const Text("연령대",
                        style: TextStyle(
                          fontSize: 14,
                        )),
                    value: controller.ageSpan.value,
                    items: ["10대", "20대", "30대", "40대", "50대", "60대"]
                        .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(color: AppColors.black),
                            )))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.ageSpan.value = value;
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return "선택x";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "주소",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  AppTextField(
                    controller: controller.addressController,
                    hintText: "휴대폰 번호",
                  ),
                  isKeyboardVisible
                      ? SizedBox(height: Get.size.height * 0.3)
                      : Container()
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
