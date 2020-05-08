/*This file is part of Medito App.

Medito App is free software: you can redistribute it and/or modify
it under the terms of the Affero GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Medito App is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Affero GNU General Public License for more details.

You should have received a copy of the Affero GNU General Public License
along with Medito App. If not, see <https://www.gnu.org/licenses/>.*/

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:Medito/data/page.dart';
import 'package:Medito/utils/colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Container getAttrWidget(BuildContext context, licenseTitle, sourceUrl,
    licenseName, String licenseURL) {
  return Container(
    padding: EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
    child: new RichText(
      textAlign: TextAlign.center,
      text: new TextSpan(
        children: [
          new TextSpan(
            text: 'From ',
            style: Theme.of(context).textTheme.display4,
          ),
          new TextSpan(
            text: licenseTitle ?? '',
            style: Theme.of(context).textTheme.body2,
            recognizer: new TapGestureRecognizer()
              ..onTap = () {
                launch(sourceUrl);
              },
          ),
          new TextSpan(
            text: ' / License: ',
            style: Theme.of(context).textTheme.display4,
          ),
          new TextSpan(
            text: licenseName ?? '',
            style: Theme.of(context).textTheme.body2,
            recognizer: new TapGestureRecognizer()
              ..onTap = () {
                launch(licenseURL);
              },
          ),
        ],
      ),
    ),
  );
}

Future<dynamic> checkFileExists(Files currentFile) async {
  String dir = (await getApplicationSupportDirectory()).path;
  var name = currentFile.filename;
  File file = new File('$dir/$name.mp3');
  var exists = await file.exists();
  return exists;
}

Future<dynamic> downloadFile(Files currentFile) async {
  String dir = (await getApplicationSupportDirectory()).path;
  var name = currentFile.filename;
  File file = new File('$dir/$name.mp3');

  if (await file.exists()) return null;

  var request = await http.get(
    currentFile.url,
  );
  var bytes = request.bodyBytes;
  await file.writeAsBytes(bytes);

  saveFileToDownloadedFilesList(currentFile);
}

Future<void> saveFileToDownloadedFilesList(Files file) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var list = prefs.getStringList('listOfSavedFiles') ?? [];
  list.add(file?.toJson()?.toString() ?? '');
  await prefs.setStringList('listOfSavedFiles', list);
}

Future<void> removeFileFromDownloadedFilesList(Files file) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var list = prefs.getStringList('listOfSavedFiles') ?? [];
  list.remove(file?.toJson()?.toString() ?? '');
  await prefs.setStringList('listOfSavedFiles', list);
}

Future<dynamic> removeFile(Files currentFile) async {
  String dir = (await getApplicationSupportDirectory()).path;
  var name = currentFile.filename;
  File file = new File('$dir/$name.mp3');

  if (await file.exists()) {
    removeFileFromDownloadedFilesList(currentFile);
    return file.delete();
  }
}

Future<dynamic> getDownload(String filename) async {
  var path = (await getApplicationSupportDirectory()).path;
  File file = new File('$path/$filename.mp3');
  if (await file.exists())
    return file.absolute.path;
  else
    return null;
}

/// Generates a 200x200 png, with randomized colors, to use as art for the
/// notification/lockscreen.
Future<Uint8List> generateImageBytes() async {
// Random color generation methods: pick contrasting hues.
  final HSLColor bgHslColor = HSLColor.fromColor(MeditoColors.darkBGColor);
  final HSLColor fgHslColor = HSLColor.fromColor(MeditoColors.lightColor);

  final Size size = const Size(200.0, 200.0);
  final Offset center = const Offset(100.0, 100.0);
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Rect rect = Offset.zero & size;
  final Canvas canvas = Canvas(recorder, rect);
  final Paint bgPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = bgHslColor.toColor();
  final Paint fgPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = bgHslColor.toColor()
    ..strokeWidth = 8;
// Draw background color.
  canvas.drawRect(rect, bgPaint);
// Draw 5 inset squares around the center.
  canvas.drawRect(
      Rect.fromCenter(center: center, width: 40.0, height: 40.0), fgPaint);
// Render to image, then compress to PNG ByteData, then return as Uint8List.
  final ui.Image image = await recorder
      .endRecording()
      .toImage(size.width.toInt(), size.height.toInt());
  final ByteData encodedImageData =
      await image.toByteData(format: ui.ImageByteFormat.png);
  return encodedImageData.buffer.asUint8List();
}
