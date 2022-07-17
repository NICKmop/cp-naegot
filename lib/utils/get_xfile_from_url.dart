import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:naegot/utils/logger.service.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:path_provider/path_provider.dart';

Future<XFile> getXfileFromImageUrl(String imageUrl) async {
  var file = await DefaultCacheManager().getSingleFile(imageUrl);
  return XFile(file.path);

  // Directory dir = await getApplicationDocumentsDirectory();
  // String pathName = p.join(dir.path, filename);
  // final response = await http.get(Uri.parse(imageUrl));
  // return XFile.fromData(response.bodyBytes);
}
