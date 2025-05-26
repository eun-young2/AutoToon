import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class UserInfoTestPage extends StatefulWidget {
  const UserInfoTestPage({super.key});

  @override
  State<UserInfoTestPage> createState() => _UserInfoTestPageState();
}

class _UserInfoTestPageState extends State<UserInfoTestPage> {
  String _userInfo = "아직 사용자 정보 없음";

  Future<void> fetchKakaoUserInfo() async {
    try {
      User user = await UserApi.instance.me();
      setState(() {
        _userInfo = user.toString();
      });
      print('사용자 정보 요청 성공: $user');
    } catch (error) {
      setState(() {
        _userInfo = "사용자 정보 요청 실패: $error";
      });
      print('사용자 정보 요청 실패: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("카카오 사용자 정보 확인")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: fetchKakaoUserInfo,
              child: const Text("카카오 사용자 정보 불러오기"),
            ),
            const SizedBox(height: 24),
            SelectableText(_userInfo),
          ],
        ),
      ),
    );
  }
}
