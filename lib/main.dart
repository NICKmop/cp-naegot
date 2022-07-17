import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:naegot/constants/common.constants.dart';
import 'package:naegot/controllers/map.controller.dart';
import 'package:naegot/screens/splash.screen.dart';
import 'package:naegot/services/user.service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: KAKAO_NATIVE_APP_KEY);
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Place',
      builder: EasyLoading.init(),
      theme: ThemeData(
        fontFamily: "NanumSquare",
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
      initialBinding: BindingsBuilder(() {
        Get.put(UserService());
        Get.put(MapService());
      }),
    );
  }
}
