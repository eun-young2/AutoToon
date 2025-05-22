import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _loginStatus = "로그인되지 않음";

  // 카카오 로그인 함수
  void kakaoLogin() async {
    bool installed = await isKakaoTalkInstalled();

    if (installed) {
      try {
        OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
        print('카카오톡으로 로그인 성공: ${token.accessToken}');
        setState(() {
          _loginStatus = "카카오톡 로그인 성공";
        });
        // 로그인 성공 후 메인 페이지로 이동
        Navigator.pushReplacementNamed(context, '/main');
      } catch (error) {
        print('카카오톡으로 로그인 실패: $error');
        setState(() {
          _loginStatus = "카카오톡 로그인 실패: $error";
        });
      }
    } else {
      try {
        OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
        print('카카오계정으로 로그인 성공: ${token.accessToken}');
        setState(() {
          _loginStatus = "카카오계정 로그인 성공";
        });
        Navigator.pushReplacementNamed(context, '/main');
      } catch (error) {
        print('카카오계정으로 로그인 실패: $error');
        setState(() {
          _loginStatus = "카카오계정 로그인 실패: $error";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('카카오 로그인')),
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
            // 추후 공식 버튼 이미지로 교체 가능
            // Image.asset('assets/images/kakao_login_large.png')
          ],
        ),
      ),
    );
  }
}
