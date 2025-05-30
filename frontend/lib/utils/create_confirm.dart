import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────
/// 오토툰 생성 전 사용자에게 한 번 더 묻는 확인 다이얼로그
Future<bool> showCreateConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('확인'),
      content: const Text('오토툰을 생성하겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('확인'),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}
/// ─────────────────────────────────────────────