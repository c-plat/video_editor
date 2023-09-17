import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/domain/entities/cover_data.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

Stream<List<Uint8List>> generateTrimThumbnails(
  VideoEditorController controller, {
  required int quantity,
  int quality = 10,
}) async* {
  final String path = controller.file.path;
  final double eachPart = controller.videoDuration.inMilliseconds / quantity;
  List<Uint8List>? byteList = [];
  Map<int, Uint8List> tmpMap = {};

  final maxHeight = (controller.videoHeight * 0.1).toInt();
  final maxWidth = (controller.videoWidth * 0.1).toInt();

  for (int i = 1; i <= quantity; i++) {
    try {
      final idx = (eachPart * i).toInt();
      final isExist = tmpMap.containsKey(idx);

      if (isExist) {
        byteList.add(tmpMap[idx]!);
      } else {
        final Uint8List? bytes = await VideoThumbnail.thumbnailData(
          imageFormat: ImageFormat.WEBP,
          video: path,
          timeMs: idx,
          quality: quality,
          maxHeight: maxHeight,
          maxWidth: maxWidth,
        );

        if (bytes != null) {
          byteList.add(bytes);
          tmpMap[idx] = bytes;
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    yield byteList;
  }
}

Stream<List<CoverData>> generateCoverThumbnails(
  VideoEditorController controller, {
  required int quantity,
  int quality = 10,
}) async* {
  final int duration =
      controller.isTrimmed ? controller.trimmedDuration.inMilliseconds : controller.videoDuration.inMilliseconds;
  final double eachPart = duration / quantity;
  List<CoverData> byteList = [];

  for (int i = 0; i < quantity; i++) {
    try {
      final CoverData bytes = await generateSingleCoverThumbnail(
        controller.file.path,
        timeMs: (controller.isTrimmed ? (eachPart * i) + controller.startTrim.inMilliseconds : (eachPart * i)).toInt(),
        quality: quality,
      );

      if (bytes.thumbData != null) {
        byteList.add(bytes);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    yield byteList;
  }
}

/// Generate a cover at [timeMs] in video
///
/// return [CoverData] depending on [timeMs] milliseconds
Future<CoverData> generateSingleCoverThumbnail(
  String filePath, {
  int timeMs = 0,
  int quality = 10,
}) async {
  final Uint8List? thumbData = await VideoThumbnail.thumbnailData(
    imageFormat: ImageFormat.JPEG,
    video: filePath,
    timeMs: timeMs,
    quality: quality,
  );

  return CoverData(thumbData: thumbData, timeMs: timeMs);
}
