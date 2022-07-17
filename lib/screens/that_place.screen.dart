import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_dragmarker/dragmarker.dart';
import 'package:flutter_map_line_editor/polyeditor.dart';
import 'package:latlong2/latlong.dart';

class ThhatPlaceScreen extends StatefulWidget {
  const ThhatPlaceScreen({Key? key}) : super(key: key);

  @override
  State<ThhatPlaceScreen> createState() => _ThhatPlaceScreenState();
}

class _ThhatPlaceScreenState extends State<ThhatPlaceScreen> {
  late PolyEditor polyEditor;

  List<Polygon> polygons = [];
  var testPolygon = Polygon(color: Colors.deepOrange, points: []);

  @override
  void initState() {
    polyEditor = PolyEditor(
      addClosePathMarker: true,
      points: testPolygon.points,
      pointIcon: const Icon(Icons.crop_square, size: 23),
      intermediateIcon: const Icon(Icons.lens, size: 15, color: Colors.grey),
      callbackRefresh: () => {setState(() {})},
    );

    polygons.add(testPolygon);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("저곳")),
      body: const Center(
        child: Text("저곳"),
      ),
    );
  }
}
