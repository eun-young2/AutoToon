import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'kakao_login_page.dart'; // 경로 확인

void main() {
  KakaoSdk.init(nativeAppKey: '357e8702e8dc4cd5b00e4945d74252d1');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: KakaoLoginPage());
  }
}
