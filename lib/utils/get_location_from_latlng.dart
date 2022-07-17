import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:naegot/models/place.model.dart';
import 'package:naegot/utils/logger.service.dart';

Future<String?> getLocationFromLatlng(Place place) async {
  LatLng? latLng;

  if (place.type == "marker" || place.type == "circle") {
    latLng = place.point!;
  } else if (place.type == "line") {
    latLng = place.polylines!.first;
  } else if (place.type == "polygon") {
    latLng = place.polygons!.first;
  }

  if (latLng == null) {
    return null;
  }

  try {
    Dio dio = Dio();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["authorization"] =
        "KakaoAK af632a971d3fbb7a04bb90a6df839397";
    final response = await dio.get(
      "https://dapi.kakao.com/v2/local/geo/coord2regioncode.json?x=${latLng.longitude}&y=${latLng.latitude}",
    );

    // logger.i(response.data);
    return (response.data as Map<String, dynamic>)["documents"][0]
        ["address_name"];
  } catch (e) {
    if (e is DioError) {
      logger.e(e.response);
    } else {
      logger.e(e);
    }
    return null;
  }
}
