import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/screens/intro.screen.dart';
import 'package:naegot/widgets/app_button.widget.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.storage,
    Permission.camera,
    Permission.photos,
    Permission.notification,
  ].request();

  if ((await Permission.location.status != PermissionStatus.granted) ||
      (await Permission.camera.status != PermissionStatus.granted) ||
      (await Permission.photos.status != PermissionStatus.granted) ||
      (await Permission.notification.status != PermissionStatus.granted) ||
      (await Permission.storage.status != PermissionStatus.granted)) {
    return Future.value(false);
  }
  // Get.defaultDialog(
  //     title: "권한 확인",
  //     content: Text("위치 권한을 허용해주세요."),
  //     confirm: AppButton(text: "설정 이동", onPressed: () {}),
  //     cancel: AppButton(text: "취소", onPressed: () {}),
  //     onConfirm: () {
  //       openAppSettings();
  //     });
  return Future.value(true);
}

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(),
      body: Scaffold(
          bottomSheet: Container(
            color: Colors.white,
            width: Get.size.width,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: AppButton(
                text: "확인",
                onPressed: () async {
                  final ok = await requestPermissions();
                  if (ok) {
                    Get.to(() => const IntroScreen());
                  } else {
                    openAppSettings();
                  }
                }),
          ),
          body: SafeArea(
            child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "원활한 서비스 이용을 위해\n다음 권한을 허용해 주세요",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 58),
                  buildPermissionItem(
                    imagePath: "assets/images/location.png",
                    title: "위치",
                    subTitle: "장소의 위치 등록",
                  ),
                  const SizedBox(height: 36),
                  buildPermissionItem(
                    imagePath: "assets/images/local-storage.png",
                    title: "저장공간",
                    subTitle: "데이터 및 리소스 저장",
                  ),
                  const SizedBox(height: 36),
                  buildPermissionItem(
                    imagePath: "assets/images/camera.png",
                    title: "카메라",
                    subTitle: "장소 사진 업로드",
                  ),
                  const SizedBox(height: 36),
                  buildPermissionItem(
                    imagePath: "assets/images/photo.png",
                    title: "사진/갤러리",
                    subTitle: "장소 사진 업로드",
                  ),
                  const SizedBox(height: 36),
                  buildPermissionItem(
                    imagePath: "assets/images/alarm.png",
                    title: "알림",
                    subTitle: "푸시알림 등록 및 수신",
                  ),
                ]),
          )),
    );
  }

  Row buildPermissionItem({
    required String imagePath,
    required String title,
    required String subTitle,
  }) {
    return Row(
      children: [
        Image.asset(
          imagePath,
          width: 41,
          height: 41,
        ),
        const SizedBox(width: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                  text: "$title ",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  children: const [
                    TextSpan(
                        text: "(필수)",
                        style: TextStyle(fontSize: 16, color: AppColors.red))
                  ]),
            ),
            Text(
              subTitle,
              style: const TextStyle(fontSize: 15, color: AppColors.grey),
            )
          ],
        )
      ],
    );
  }
}
