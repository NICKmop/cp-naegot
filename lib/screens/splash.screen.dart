import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/screens/login.screen.dart';
import 'package:naegot/screens/main.screen.dart';
import 'package:naegot/screens/permission.screen.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // FirebaseAuth.instance.signOut();
    // GoogleSignIn().signOut();
    checkPermissions();
    super.initState();
  }

  Future<void> checkPermissions() async {
    if ((await Permission.location.status != PermissionStatus.granted) ||
        (await Permission.camera.status != PermissionStatus.granted) ||
        (await Permission.photos.status != PermissionStatus.granted) ||
        (await Permission.notification.status != PermissionStatus.granted) ||
        (await Permission.storage.status != PermissionStatus.granted)) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        Get.to(() => const PermissionScreen());
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        FirebaseAuth.instance.currentUser != null
            ? Get.offAll(() => const MainScreen())
            : Get.offAll(() => const LoginScreen());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: SizedBox(
        height: Get.size.height,
        width: Get.size.width,
        child: Column(children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/logo.png",
                  width: Get.size.width / 3,
                ),
                const SizedBox(height: 20),
                const Text(
                  "내곳",
                  style: TextStyle(fontSize: 28, color: AppColors.primary),
                )
              ],
            ),
          ),
          const Text(
            "naegot",
            style: TextStyle(fontSize: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    ));
  }
}
