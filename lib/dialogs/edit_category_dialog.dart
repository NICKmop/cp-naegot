import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/widgets/app_text_form_field.widget.dart';

import '../widgets/app_button.widget.dart';

class EditCategoryDialog extends StatefulWidget {
  const EditCategoryDialog({Key? key, required this.categoryText})
      : super(key: key);
  final String categoryText;

  @override
  State<EditCategoryDialog> createState() => _AppDefaultDialogState();
}

class _AppDefaultDialogState extends State<EditCategoryDialog> {
  final formKey = GlobalKey<FormState>();
  String catergoryText = "";
  final categoryController = TextEditingController();

  @override
  void initState() {
    catergoryText = widget.categoryText;
    categoryController.text = widget.categoryText;
    super.initState();
  }

  @override
  void dispose() {
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AlertDialog(
        insetPadding: const EdgeInsets.only(left: 31.7, right: 31.7),
        titlePadding: const EdgeInsets.only(top: 30, left: 24, bottom: 15),
        contentPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 25),
        buttonPadding: const EdgeInsets.all(0),
        actionsPadding:
            const EdgeInsets.only(left: 17, right: 17, bottom: 20, top: 0),
        title: const Text("내 폴더 수정",
            style: TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 23.3,
            ),
            textAlign: TextAlign.left),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              AppTextFormField(
                controller: categoryController,
                hintText: "폴더 이름을 입력하세요.",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "폴더 이름을 입력하세요";
                  }
                  return null;
                },
              )
            ],
          ),
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: Get.size.width,
                child: AppButton(
                  text: "확인",
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await FirebaseSerivce.editCategory(
                          widget.categoryText, categoryController.text.trim());
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
        ],
      ),
    );
  }
}
