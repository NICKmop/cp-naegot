import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/controllers/home.controller.dart';
import 'package:naegot/controllers/navigation.controller.dart';
import 'package:naegot/controllers/the_place.controller.dart';
import 'package:naegot/screens/home.screen.dart';
import 'package:naegot/screens/my_place.screen.dart';
import 'package:naegot/screens/that_place.screen.dart';
import 'package:naegot/screens/the_place.screen.dart';

import 'package:naegot/screens/crawling.screen.dart';

import 'package:naegot/services/place.service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Get.put(PlaceService());
    Get.put(NavigationController());
    Get.put(HomeController());
    Get.put(ThePlaceController());

    final navigationController = Get.find<NavigationController>();

    // FirebaseAuth.instance.signOut();
    return Scaffold(
      bottomNavigationBar: Obx(
        () => Offstage(
          offstage: HomeController.to.hideBottomMenu.value,
          child: ListView(
            shrinkWrap: true,
            children: [
              BottomNavigationBar(
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(color: Colors.red),
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.grey,
                currentIndex: navigationController.currentBottomMenuIndex.value,
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(
                    icon: Image.asset(
                      "assets/images/bottom-menu-home.png",
                      height: 30,
                      color:
                          navigationController.currentBottomMenuIndex.value == 0
                              ? AppColors.primary
                              : AppColors.grey,
                    ),
                    label: "이곳",
                  ),
                  BottomNavigationBarItem(
                    icon: Image.asset(
                      "assets/images/bottom-menu-this.png",
                      height: 30,
                      color:
                          navigationController.currentBottomMenuIndex.value == 1
                              ? AppColors.primary
                              : AppColors.grey,
                    ),
                    label: "그곳",
                  ),
                  BottomNavigationBarItem(
                    icon: Image.asset(
                      "assets/images/bottom-menu-that.png",
                      height: 30,
                      color:
                          navigationController.currentBottomMenuIndex.value == 2
                              ? AppColors.primary
                              : AppColors.grey,
                    ),
                    label: "저곳",
                  ),
                  BottomNavigationBarItem(
                    icon: Image.asset(
                      "assets/images/bottom-menu-my.png",
                      height: 30,
                      color:
                          navigationController.currentBottomMenuIndex.value == 3
                              ? AppColors.primary
                              : AppColors.grey,
                    ),
                    label: "내곳",
                  ),
                  BottomNavigationBarItem(
                    icon: Image.asset(
                      "assets/images/bottom-menu-my.png",
                      height: 30,
                      color:
                      navigationController.currentBottomMenuIndex.value == 4
                          ? AppColors.primary
                          : AppColors.grey,
                    ),
                    label: "크롤링 페이지",
                  ),
                ],
                onTap: (index) {
                  navigationController.currentBottomMenuIndex.value = index;
                  setState(() {});
                  if (index == 1) {
                    PlaceService.to.fetchAllPlaces();
                  }

                  if (index == 3) {
                    PlaceService.to.fetchMyPlaces();
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: Obx(
        () => IndexedStack(
          index: navigationController.currentBottomMenuIndex.value,
          children: const [
            HomeScreen(),
            ThePlaceScreen(),
            ThhatPlaceScreen(),
            MyPlaceScreen(),
            crawlingScreen(),
          ],
        ),
      ),
    );
  }
}
