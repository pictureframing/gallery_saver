import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/files.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GallerySaver {
  static const String channelName = 'gallery_saver';
  static const String methodSaveImage = 'saveImage';
  static const String methodSaveVideo = 'saveVideo';

  static const String pleaseProvidePath = 'Please provide valid file path.';
  static const String fileIsNotVideo = 'File on path is not a video.';
  static const String fileIsNotImage = 'File on path is not an image.';
  static const String failedToParseFileName =
      'Failed to determine the file’s file-name. File on path is not an image or video.';
  static const MethodChannel _channel = const MethodChannel(channelName);

  ///saves video from provided temp path and optional album name in gallery
  static Future<bool?> saveVideo(
    String path, {
    String? albumName,
    bool toDcim = false,
    Map<String, String>? headers,
  }) async {
    File? tempFile;
    if (path.isEmpty) {
      throw ArgumentError(pleaseProvidePath);
    }

    /// Expect local files to consist of a valid videofile-extension.
    if (isLocalFilePath(path) && !isVideo(path)) {
      throw ArgumentError(fileIsNotVideo);
    }

    if (!isLocalFilePath(path)) {
      tempFile = await _downloadFile(path, headers: headers);
      path = tempFile.path;
    }

    bool? result = await _channel.invokeMethod(
      methodSaveVideo,
      <String, dynamic>{'path': path, 'albumName': albumName, 'toDcim': toDcim},
    );
    if (tempFile != null) {
      tempFile.delete();
    }
    return result;
  }

  ///saves image from provided temp path and optional album name in gallery
  static Future<bool?> saveImage(
    String path, {
    String? albumName,
    bool toDcim = false,
    Map<String, String>? headers,
  }) async {
    File? tempFile;
    if (path.isEmpty) {
      throw ArgumentError(pleaseProvidePath);
    }

    if (isLocalFilePath(path) && !isImage(path)) {
      throw ArgumentError(fileIsNotImage);
    }

    if (!isLocalFilePath(path)) {
      tempFile = await _downloadFile(path, headers: headers);
      path = tempFile.path;
    }

    bool? result = await _channel.invokeMethod(
      methodSaveImage,
      <String, dynamic>{'path': path, 'albumName': albumName, 'toDcim': toDcim},
    );
    if (tempFile != null) {
      tempFile.delete();
    }

    return result;
  }

  static Future<File> _downloadFile(String url, {Map<String, String>? headers}) async {
    print(url);
    print(headers);
    http.Client _client = new http.Client();
    final uri = Uri.parse(url);

    var req = await _client.get(uri, headers: headers);
    if (req.statusCode >= 400) {
      throw HttpException(req.statusCode.toString());
    }

    var bytes = req.bodyBytes;
    String fileName = getFileNameFromUri(
      uri: uri,
      response: req,
    );

    String dir = (await getTemporaryDirectory()).path;
    File file = new File('$dir/$fileName');
    await file.writeAsBytes(bytes);
    print('File size:${await file.length()}');
    print(file.path);
    return file;
  }

  @visibleForTesting
  static getFileNameFromUri({
    required Uri uri,
    required http.Response response,
  }) {
    String fileName = basename(uri.path);

    /// Return the fileName if it already consists of a valid image- or video-
    /// file-extension.
    if (isVideo(fileName) || isImage(fileName)) {
      return fileName;
    }

    // Append the fileExtensionFromContentType to the fileName and return the result.
    final fileExtensionFromContentType = '.${response.headers['content-type']?.split('/')[1]}';
    if (isVideo(fileExtensionFromContentType) || isImage(fileExtensionFromContentType)) {
      return '$fileName$fileExtensionFromContentType';
    }

    throw ArgumentError(failedToParseFileName);
  }
}
