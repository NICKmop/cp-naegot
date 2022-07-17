import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserProfileCircleImage extends StatelessWidget {
  const UserProfileCircleImage(
      {Key? key, required this.imageUrl, this.size = 43})
      : super(key: key);

  final String? imageUrl;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: imageUrl == null || imageUrl!.isEmpty
          ? Image.asset(
              "assets/images/default-profile.png",
              width: size,
            )
          : CachedNetworkImage(
              imageUrl: imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
    );
  }
}
