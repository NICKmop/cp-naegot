import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naegot/constants/colors.constants.dart';

import '../widgets/app_button.widget.dart';

class AppDefaultDialog extends StatelessWidget {
  const AppDefaultDialog(
      {Key? key,
      required this.title,
      required this.subTitle,
      this.okText,
      this.cancelText,
      this.onOk,
      this.onCancel})
      : super(key: key);
  final String title;
  final String subTitle;
  final String? okText;
  final String? cancelText;
  final void Function()? onOk;
  final void Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.only(left: 31.7, right: 31.7),
      titlePadding: const EdgeInsets.only(top: 30, left: 24, bottom: 15),
      contentPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 25),
      buttonPadding: const EdgeInsets.all(0),
      actionsPadding:
          const EdgeInsets.only(left: 17, right: 17, bottom: 20, top: 0),
      title: Text(title,
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 23.3,
          ),
          textAlign: TextAlign.left),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(subTitle,
                style: const TextStyle(
                  height: 1.5,
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.3,
                ),
                textAlign: TextAlign.left),
          ],
        ),
      ),
      actions: [
        Column(
          children: [
            SizedBox(
              width: Get.size.width,
              child: AppButton(
                text: okText ?? "확인",
                onPressed: onOk ??
                    () {
                      Get.back();
                    },
              ),
            ),
            SizedBox(
              width: Get.size.width,
              child: AppButton(
                text: cancelText ?? "취소",
                onPressed: onCancel ??
                    () {
                      Get.back();
                    },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
