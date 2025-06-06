import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

/// ────────────────────────────────────────────────────
/// “툰(이미지) 저장하기” 기능을 별도 유틸로 분리한 클래스
/// 사용법:
///   ImageSaver.saveToGallery(context, imgFile);
/// imgFile 은 XFile 타입으로, 저장할 이미지 파일을 가리킵니다.
/// ────────────────────────────────────────────────────
class ImageSaver {
  /// 이미지를 갤러리에 저장하고, 성공/실패 결과를 Snackbar 로 보여 줌
  static Future<void> saveToGallery(
      BuildContext context, XFile imgFile) async {
    // 1) 이미지 경로 체크
    if (imgFile.path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 이미지가 없습니다.')),
      );
      return;
    }

    // 2) 권한 요청 (Android/iOS 공통 처리)
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 권한이 허용되지 않았습니다.')),
      );
      return;
    }

    try {
      // 3) 파일을 바이트로 읽어 옴
      final Uint8List bytes = await imgFile.readAsBytes();
      // 4) 갤러리에 저장
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'toon_${DateTime.now().millisecondsSinceEpoch}',
      );
      // 5) 저장 성공/실패 여부 확인
      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('갤러리에 저장되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 저장에 실패했습니다.')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 중 오류가 발생했습니다.')),
      );
    }
  }
}
