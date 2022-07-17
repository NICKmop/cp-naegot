import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/constants/common.constants.dart';
import 'package:naegot/screens/main.screen.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/services/user.service.dart';
import 'package:naegot/utils/logger.service.dart';

final googleSignIn = GoogleSignIn(
  scopes: ['email'],
);

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
                ),
                const SizedBox(height: 20),
                SignInButton(
                  Buttons.Google,
                  text: "구글 로그인",
                  onPressed: () async {
                    try {
                      EasyLoading.show(status: "로그인...");
                      final account = await googleSignIn.signIn();
                      if (account == null) {
                        // EasyLoading.showError("not found google account");
                        // setState(() {});
                        return;
                      }
                      final auth = await account.authentication;
                      final idToken = auth.idToken;

                      if (idToken == null) {
                        EasyLoading.showError("not found idToken");
                        return;
                      }

                      final credential = GoogleAuthProvider.credential(
                        accessToken: auth.accessToken,
                        idToken: auth.idToken,
                      );
                      // controller.oAuthCredential.value = credential;
                      final user = await FirebaseAuth.instance
                          .signInWithCredential(credential);
                      if (user.user == null) {
                        throw "handleGoogleLogin signInWithCredential errror";
                      }

                      var currentUser = await FirebaseSerivce.findUserByEmail(
                          user.user!.email!);

                      if (currentUser == null) {
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(user.user!.email)
                            .set({
                          "email": user.user!.email,
                          "provider": "google",
                          "createdAt": DateTime.now(),
                          "loggedAt": DateTime.now(),
                          "name": user.user!.displayName,
                          "profileImage": user.user!.photoURL,
                          'categories': [NO_CATEGORY_TEXT]
                        });
                        currentUser = await FirebaseSerivce.findUserByEmail(
                            user.user!.email!);
                        if (currentUser == null) {
                          EasyLoading.showError("가입 실패");
                        }
                      }

                      UserService.to.currentUser.value = currentUser;
                      Get.offAll(() => const MainScreen());
                    } catch (error) {
                      logger.e(error);
                    } finally {
                      EasyLoading.dismiss();
                    }
                  },
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
