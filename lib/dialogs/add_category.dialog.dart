import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/widgets/app_button.widget.dart';
import 'package:naegot/widgets/app_text_field.widget.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({Key? key}) : super(key: key);

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final formKey = GlobalKey<FormState>();
  final categoryController = TextEditingController();

  @override
  void dispose() {
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.only(left: 31.7, right: 31.7),
      titlePadding: const EdgeInsets.only(top: 30, left: 24, bottom: 15),
      contentPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 25),
      buttonPadding: const EdgeInsets.all(0),
      actionsPadding:
          const EdgeInsets.only(left: 17, right: 17, bottom: 20, top: 0),
      title: const Text("카테고리 추가",
          style: TextStyle(
            // color: AppColors.dark,
            fontWeight: FontWeight.bold,
            fontSize: 23.3,
          ),
          textAlign: TextAlign.left),
      content: SingleChildScrollView(
          child: Form(
        key: formKey,
        child: Column(
          children: [
            AppTextField(controller: categoryController, hintText: "카테고리"),
            const SizedBox(height: 20),
            SizedBox(
              width: Get.size.width,
              child: AppButton(
                text: "추가",
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await FirebaseSerivce.addCategory(
                        categoryController.text.trim());
                    categoryController.clear();
                    Get.back();
                  }
                },
              ),
            ),
            SizedBox(
              width: Get.size.width,
              child: AppButton(
                text: "취소",
                onPressed: () {
                  Get.back();
                },
              ),
            ),
          ],
        ),
      )),
    );
  }
}
