import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naegot/constants/common.constants.dart';
import 'package:naegot/models/app_user.model.dart';
import 'package:naegot/models/place.model.dart';
import 'package:naegot/services/user.service.dart';
import 'package:naegot/utils/logger.service.dart';

class FirebaseSerivce {
  static Future<AppUser?> findUserByEmail(String email) async {
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(email).get();
    if (!doc.exists) {
      return null;
    }
    final currentUser = AppUser.fromMap(doc.data() as Map<String, dynamic>);
    UserService.to.currentUser.value = currentUser;
    return currentUser;
  }

  static Future<AppUser?> getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    return findUserByEmail(user.email!);
  }

  static Future<bool> addCategory(String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.email)
        .update({
      "categories": FieldValue.arrayUnion([category])
    });
    final appUser = await findUserByEmail(user.email!);
    UserService.to.currentUser.value = appUser;
    return true;
  }

  static Future<String?> deleteCategory(String category) async {
    if (category == NO_CATEGORY_TEXT) {
      return "기본 폴더는 삭제할 수 없습니다.";
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return "유저 정보를 찾을 수 없습니다.";
    }
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.email)
        .update({
      "categories": FieldValue.arrayRemove([category])
    });
    final appUser = await findUserByEmail(user.email!);
    UserService.to.currentUser.value = appUser;
    final snapshot = await FirebaseFirestore.instance
        .collection("places")
        .where("userEmail", isEqualTo: appUser!.email)
        .where("category", isEqualTo: category)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    return null;
  }

  static Future<bool> editCategory(
      String beforeCategory, String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.email)
        .update({
      "categories": FieldValue.arrayRemove([beforeCategory])
    });
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.email)
        .update({
      "categories": FieldValue.arrayUnion([category])
    });
    final appUser = await findUserByEmail(user.email!);
    UserService.to.currentUser.value = appUser;
    final snapshot = await FirebaseFirestore.instance
        .collection("places")
        .where("userEmail", isEqualTo: appUser!.email)
        .where("category", isEqualTo: beforeCategory)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({"category": category});
    }
    return true;
  }

  static DocumentReference<Map<String, dynamic>> getDoc(
      {String collection = "places"}) {
    return FirebaseFirestore.instance.collection(collection).doc();
  }

  static Future<Place?> getPlace(String placeId) async {
    final doc = await FirebaseFirestore.instance
        .collection("places")
        .doc(placeId)
        .get();
    return doc.exists ? Place.fromMap(doc.data()!) : null;
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getPlaceData(
      String placeId) async {
    return await FirebaseFirestore.instance
        .collection("places")
        .doc(placeId)
        .get();
  }

  static Future<bool> addPlace(Place place) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }
      final data = place.toMap();
      logger.i(data);

      await FirebaseFirestore.instance
          .collection("places")
          .doc(data["id"])
          .set(data);
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  static Future<bool> updatePlace(String id, Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      await FirebaseFirestore.instance
          .collection("places")
          .doc(id)
          .update(data);
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  // TODO: no need
  static Future<bool> addPlaceFromOthers(Place place) async {
    if (place.userEmail == UserService.to.currentUser.value!.email) {
      // EasyLoading.showError("이미 등록된 장소입니다.");
      return false;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }
      final data = place.toMap();
      final snapshot = await FirebaseFirestore.instance
          .collection("places")
          .where("userEmail",
              isEqualTo: UserService.to.currentUser.value!.email)
          .where("point", isEqualTo: data["point"])
          .get();
      if (snapshot.docs.isEmpty) {
        final doc = FirebaseFirestore.instance.collection("places").doc();
        await doc.set({
          ...data,
          "id": doc.id,
          "userEmail": UserService.to.currentUser.value!.email,
          "createdAt": DateTime.now().millisecondsSinceEpoch,
          "updatedAt": DateTime.now().millisecondsSinceEpoch,
        });
        await addCategory(data["category"]);
        // EasyLoading.showSuccess("장소가 저장되었습니다.");
      } else {
        // EasyLoading.showError("이미 등록된 장소입니다.");
        return false;
      }

      return true;
    } catch (e) {
      EasyLoading.showError(e.toString());
      logger.e(e);
      return false;
    }
  }

  static Future<bool> subscribePlace(Place place, bool isSubscribe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      if (place.userEmail == FirebaseAuth.instance.currentUser!.email) {
        return false;
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.email)
          .update({
        "subscribes": isSubscribe
            ? FieldValue.arrayUnion([place.id])
            : FieldValue.arrayRemove([place.id])
      });
      return true;
    } catch (e) {
      EasyLoading.showError(e.toString());
      logger.e(e);
      return false;
    }
  }

  static Future<List<Place>> getAllPlaces() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return [];
      }
      final snapshot = await FirebaseFirestore.instance
          .collection("places")
          .orderBy("createdAt", descending: true)
          .get();
      if (snapshot.docs.isEmpty) {
        return [];
      }

      final places =
          snapshot.docs.map((doc) => Place.fromMap(doc.data())).toList();
      return places;
    } catch (e) {
      logger.e(e);
      return [];
    }
  }

  static Future<List<Place>> getMyPlaces() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return [];
      }
      final snapshot = await FirebaseFirestore.instance
          .collection("places")
          .where("userEmail", isEqualTo: user.email)
          .get();
      if (snapshot.docs.isEmpty) {
        return [];
      }

      final places =
          snapshot.docs.map((doc) => Place.fromMap(doc.data())).toList();
      return places;
    } catch (e) {
      logger.e(e);
      return [];
    }
  }

  static Future<String?> uploadImage(XFile? selectedImage) async {
    if (selectedImage == null) {
      EasyLoading.showError("이미지 선택 실패");
      return null;
    }

    EasyLoading.show(status: "업로드 중입니다");

    var storageRef = FirebaseStorage.instance
        .ref(DateTime.now().toString() + selectedImage.name);
    await storageRef.putFile(File(selectedImage.path));
    final downloadUrl = await storageRef.getDownloadURL();
    logger.d(downloadUrl);

    return downloadUrl;
  }

  static Future<void> deletePlace(Place place) async {
    EasyLoading.show(status: "삭제중입니다.");
    await FirebaseFirestore.instance
        .collection("places")
        .doc(place.id)
        .delete();
    EasyLoading.dismiss();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> getCurrentUserStream() {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.email)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyPlaceStream() {
    return FirebaseFirestore.instance
        .collection("places")
        .where("userEmail", isEqualTo: FirebaseAuth.instance.currentUser!.email)
        .snapshots();
  }

  static Future<List<Place>> getSubscribePlaces() async {
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.email)
        .get();
    if (!userDoc.exists) {
      return [];
    }

    final user = AppUser.fromMap(userDoc.data()!);

    List<Place> places = [];

    for (var placeId in user.subscribes) {
      final place = await getPlace(placeId);
      if (place != null) {
        places.add(place);
      }
    }
    return places;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyPlaceStreamByCategory(
      String category) {
    return FirebaseFirestore.instance
        .collection("places")
        .where("userEmail", isEqualTo: FirebaseAuth.instance.currentUser!.email)
        .where("category", isEqualTo: category)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllPlaceStream() {
    return FirebaseFirestore.instance
        .collection("places")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  static Future<void> changeCategoryVisible(String category, bool bool) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.email)
        .update({
      "invisibleCategories": bool
          ? FieldValue.arrayRemove([category])
          : FieldValue.arrayUnion([category])
    });
  }

  static Future<void> changeShowSubscribePlaces(bool bool) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.email)
        .update({"showSubscribePlaces": bool});
  }
}
