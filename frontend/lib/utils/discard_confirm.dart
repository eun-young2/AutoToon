import 'package:flutter/material.dart';

/// 작성 중인 내용이 있으면 이동 전 확인을 띄웁니다.
/// 사용자가 ‘이동’을 선택해야 true를 반환합니다.
Future<bool> showDiscardDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('작성 중인 내용이 있습니다'),
      content: const Text('이동 시 작성 중인 내용이 사라집니다. 계속 이동하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('확인'),
        ),
      ],
    ),
  ).then((v) => v ?? false);
}
