import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naegot/screens/login.screen.dart';
import 'package:naegot/screens/main.screen.dart';
import 'package:naegot/widgets/app_button.widget.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
          height: Get.size.height,
          width: Get.size.width,
          child: Column(
              // shrinkWrap: true,
              // padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "나만의 장소를\n저장하고 공유해 보세요",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                // const SizedBox(height: 20),
                Image.asset(
                  "assets/images/intro.png",
                  height: Get.size.height * 0.7,
                ),
                // const SizedBox(height: 20),
                SizedBox(
                  width: Get.size.width,
                  child: AppButton(
                    text: "완료",
                    onPressed: () {
                      FirebaseAuth.instance.currentUser == null
                          ? Get.offAll(() => const LoginScreen())
                          : Get.offAll(() => const MainScreen());
                    },
                  ),
                )
              ]),
        ),
      ),
    );
  }
}
