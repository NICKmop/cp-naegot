import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:naegot/utils/logger.service.dart';

class Place {
  String id;
  final String type;
  final String? category;
  final String name;
  final String color;
  final int icon;
  final List<String>? keywords;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userEmail;
  List<dynamic> photos;
  LatLng? point;
  List<LatLng>? polylines;
  List<LatLng>? polygons;
  int? radius;
  String? address;

  Place({
    required this.id,
    required this.type,
    this.category,
    required this.name,
    required this.color,
    required this.icon,
    this.keywords,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.userEmail,
    required this.photos,
    this.point,
    this.polylines,
    this.polygons,
    this.radius,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'name': name,
      'color': color,
      'icon': icon,
      'keywords': keywords,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'userEmail': userEmail,
      'photos': photos,
      'point': point == null ? null : "${point!.latitude},${point!.longitude}",
      'polylines': polylines == null
          ? []
          : polylines!
              .map((polyline) => "${polyline.latitude},${polyline.longitude}")
              .toList(),
      'polygons': polygons == null
          ? []
          : polygons!
              .map((polygon) => "${polygon.latitude},${polygon.longitude}")
              .toList(),
      'radius': radius,
      'address': address,
    };
  }

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      category: map['category'],
      name: map['name'] ?? '',
      color: map['color'] ?? '',
      icon: map['icon']?.toInt() ?? 0,
      keywords: List<String>.from(map['keywords']),
      description: map['description'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      userEmail: map['userEmail'] ?? '',
      photos: map['photos'] ?? [],
      point: getLatLngFromString(map['point']),
      polylines: map['polylines'] == null || map['polylines'].length == 0
          ? []
          : List<LatLng>.from(map['polylines']
              .map((polyline) => getLatLngFromString(polyline))),
      polygons: map['polygons'] == null || map['polygons'].length == 0
          ? []
          : List<LatLng>.from(
              map['polygons'].map((polygon) => getLatLngFromString(polygon))),
      radius: map['radius']?.toInt(),
      address: map['address'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Place.fromJson(String source) => Place.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Place(id: $id, type: $type, category: $category, name: $name, color: $color, icon: $icon, keywords: $keywords, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, userEmail: $userEmail, photos: $photos, point: $point, polylines: $polylines, polygons: $polygons, radius: $radius, address: $address)';
  }
}

getLatLngFromString(String? latLngString) {
  if (latLngString == null ||
      latLngString.isEmpty ||
      !latLngString.contains(",") ||
      latLngString.split(",").length < 2) {
    return null;
  }

  final splits = latLngString.split(",");
  return LatLng(double.parse(splits[0]), double.parse(splits[1]));
}
