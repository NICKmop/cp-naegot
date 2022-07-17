import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/controllers/map.controller.dart';
import 'package:naegot/screens/login.screen.dart';
import 'package:naegot/services/user.service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final mapController = Get.find<MapService>();

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
          child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: const [
                Icon(Icons.settings),
                SizedBox(width: 10),
                Text(
                  "설정",
                  style: TextStyle(fontSize: 18),
                )
              ],
            ),
          ),
          buildCategoryContainer("지도 유형"),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      mapController.mapType.value = MapType.normal;
                    },
                    child: Row(
                      children: [
                        Container(
                          decoration:
                              mapController.mapType.value == MapType.normal
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 4,
                                      ),
                                    )
                                  : null,
                          child: Image.asset(
                            "assets/images/map-regular.png",
                            width: 60,
                            height: 60,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text("일반지도")
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      mapController.mapType.value = MapType.satelite;
                    },
                    child: Row(
                      children: [
                        Container(
                          decoration:
                              mapController.mapType.value == MapType.satelite
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 4,
                                      ),
                                    )
                                  : null,
                          child: Image.asset(
                            "assets/images/map-satelite.png",
                            width: 60,
                            height: 60,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text("위성지도")
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          buildCategoryContainer("약관 및 정책"),
          buildMenuListTile("서비스 이용약관", () {}),
          const Divider(height: 1),
          buildMenuListTile("위치기반 서비스 이용약관", () {}),
          const Divider(height: 1),
          buildMenuListTile("개인정보 처리방침", () {}),
          const Divider(height: 1),
          buildMenuListTile("정보 제공처", () {}),
          const Divider(height: 1),
          buildMenuListTile("법적 공지", () {}),
          const Divider(height: 1),
          buildMenuListTile("운영 정책", () {}),
          const Divider(height: 1),
          buildCategoryContainer("앱 정보"),
          buildMenuListTile("버전 정보", () {}),
          buildCategoryContainer("기타"),
          buildMenuListTile("도움말", () {}),
          const Divider(height: 1),
          buildMenuListTile("문의하기", () {}),
          const Divider(height: 1),
          buildMenuListTile("로그아웃", () async {
            await GoogleSignIn().signOut();
            await FirebaseAuth.instance.signOut();
            Get.offAll(() => const LoginScreen());
            UserService.to.currentUser.value = null;
          }),
          const Divider(height: 1),
        ],
      )),
    );
  }

  ListTile buildMenuListTile(String text, void Function()? onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 40),
      title: Text(text),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Container buildCategoryContainer(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      color: Colors.grey.shade200,
      child: Text(text),
    );
  }
}
