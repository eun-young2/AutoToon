import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoLoginPage extends StatefulWidget {
  // 이름을 KakaoLoginPage로 변경
  const KakaoLoginPage({super.key});

  @override
  State<KakaoLoginPage> createState() => _KakaoLoginPageState();
}

class _KakaoLoginPageState extends State<KakaoLoginPage> {
  String _loginStatus = "로그인되지 않음";

  Future<void> kakaoLogin() async {
    try {
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
      setState(() {
        _loginStatus = "로그인 성공";
      });

      // 로그인 성공 후 사용자 정보 요청
      User user = await UserApi.instance.me();

      // 메인 화면으로 이동하며 사용자 정보 전달
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/main',
        arguments: user,
      );
    } catch (e) {
      setState(() {
        _loginStatus = "로그인 실패: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("카카오 로그인")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_loginStatus),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: kakaoLogin,
              child: const Text("카카오로 로그인"),
            ),
          ],
        ),
      ),
    );
  }
}
