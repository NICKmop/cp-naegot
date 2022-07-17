import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naegot/constants/colors.constants.dart';
import 'package:naegot/controllers/home.controller.dart';
import 'package:naegot/controllers/navigation.controller.dart';
import 'package:naegot/models/place.model.dart';
import 'package:naegot/screens/place_detail.screen.dart';
import 'package:naegot/services/firebase.service.dart';
import 'package:naegot/services/place.service.dart';
import 'package:naegot/utils/logger.service.dart';

class crawlingScreen extends StatefulWidget {
  const crawlingScreen({Key? key}) : super(key: key);

  @override
  State<crawlingScreen> createState() => _crawlingScreenState();
}

class _crawlingScreenState extends State<crawlingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text("data"),
      ),
    );
  }
}
