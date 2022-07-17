import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:naegot/utils/logger.service.dart';

class AppUser {
  final String email;
  final String provider;
  final String? nickname;
  final String? name;
  final String? phone;
  final String? ageSpan;
  final String? address;
  final DateTime createdAt;
  final DateTime loggedAt;
  final String? profileImage;
  final List<String> categories;
  final List<String> invisibleCategories;
  final List<String> subscribes;
  final bool showSubscribePlaces;

  AppUser(
      this.email,
      this.provider,
      this.nickname,
      this.name,
      this.phone,
      this.ageSpan,
      this.address,
      this.createdAt,
      this.loggedAt,
      this.profileImage,
      this.categories,
      this.invisibleCategories,
      this.subscribes,
      this.showSubscribePlaces);

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'provider': provider,
      'nickname': nickname,
      'name': name,
      'phone': phone,
      'ageSpan': ageSpan,
      'address': address,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'loggedAt': loggedAt.millisecondsSinceEpoch,
      'profileImage': profileImage,
      'categories': categories,
      'invisibleCategories': invisibleCategories,
      'subscribes': subscribes,
      'showSubscribePlaces': showSubscribePlaces,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      map['email'] ?? '',
      map['provider'] ?? '',
      map['nickname'],
      map['name'],
      map['phone'],
      map['ageSpan'],
      map['address'],
      (map['createdAt'] as Timestamp).toDate(),
      (map['loggedAt'] as Timestamp).toDate(),
      map['profileImage'],
      map['categories'] == null ? [] : List<String>.from(map['categories']),
      map['invisibleCategories'] == null
          ? []
          : List<String>.from(map['invisibleCategories']),
      map['subscribes'] == null ? [] : List<String>.from(map['subscribes']),
      map['showSubscribePlaces'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppUser.fromJson(String source) =>
      AppUser.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AppUser(email: $email, provider: $provider, nickname: $nickname, name: $name, phone: $phone, ageSpan: $ageSpan, address: $address, createdAt: $createdAt, loggedAt: $loggedAt, profileImage: $profileImage, categories: $categories, invisibleCategories: $invisibleCategories, subscribes: $subscribes, showSubscribePlaces: $showSubscribePlaces)';
  }
}
