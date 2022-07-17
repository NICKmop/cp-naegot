import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naegot/services/user.service.dart';

class EditProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final nicknameController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final ageSpan = "10대".obs;
  final addressController = TextEditingController();
  final isRegisterAgree = false.obs;
  final isPrivacyAgree = false.obs;

  final ImagePicker imagePicker = ImagePicker();

  @override
  void onInit() {
    nicknameController.text = UserService.to.currentUser.value!.nickname ?? "";
    nameController.text = UserService.to.currentUser.value!.name ?? "";
    phoneController.text = UserService.to.currentUser.value!.phone ?? "";
    ageSpan.value = UserService.to.currentUser.value!.ageSpan ?? "";
    addressController.text = UserService.to.currentUser.value!.address ?? "";
    super.onInit();
  }

  @override
  void dispose() {
    nicknameController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
