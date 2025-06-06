// lib/widgets/double_back_to_exit.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────────────
/// 뒤로가기 두 번 누를 때 마지막에 한번 더 누르면 앱 종료 토스트를 띄우고,
/// 2초 이내에 다시 누르면 앱을 종료합니다.
///
/// 사용법:
///   Scaffold(
///     body: DoubleBackToExit(
///       child: ...실제 페이지 위젯...,
///     ),
///   );
/// ─────────────────────────────────────────────────────────────────────
class DoubleBackToExit extends StatefulWidget {
  /// 실제로 보여줄 페이지(Scaffold의 body 등) 위젯
  final Widget child;

  const DoubleBackToExit({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastBackPressTime;

  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      Fluttertoast.showToast(
        msg: "'뒤로' 버튼을 한번 더 누르시면 앱이 종료됩니다.",
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFF6E6E6E),
        fontSize: 16,
        toastLength: Toast.LENGTH_SHORT,
      );
      return false; // pop을 막고 토스트만 띄움
    }
    // 2초 이내에 다시 누른 경우 → 앱 종료
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      // iOS 등에서는 Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.of(context).pop();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope가 감싸고 있는 위젯 트리에서
    // 백버튼(onWillPop)을 두 번 눌러야 종료하도록 처리합니다.
    return WillPopScope(
      onWillPop: _onWillPop,
      child: widget.child,
    );
  }
}