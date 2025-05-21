import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

/// 카카오 로그인 페이지 위젯
class KakaoLoginPage extends StatefulWidget {
  const KakaoLoginPage({super.key});

  @override
  State<KakaoLoginPage> createState() => _KakaoLoginPageState();
}

class _KakaoLoginPageState extends State<KakaoLoginPage> {
  // 로그인 상태를 표시하는 변수
  String _loginStatus = "로그인되지 않음";

  /// 카카오 로그인 함수
  /// 카카오톡이 설치되어 있으면 카카오톡으로,
  /// 아니면 카카오계정으로 로그인 시도
  void kakaoLogin() async {
    bool installed = await isKakaoTalkInstalled();

    if (installed) {
      // 카카오톡 앱으로 로그인 시도
      try {
        OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
        print('카카오톡으로 로그인 성공: ${token.accessToken}');
        setState(() {
          _loginStatus = "카카오톡 로그인 성공";
        });
      } catch (error) {
        print('카카오톡으로 로그인 실패: $error');
        setState(() {
          _loginStatus = "카카오톡 로그인 실패: $error";
        });
      }
    } else {
      // 카카오계정(웹뷰)으로 로그인 시도
      try {
        OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
        print('카카오계정으로 로그인 성공: ${token.accessToken}');
        setState(() {
          _loginStatus = "카카오계정 로그인 성공";
        });
      } catch (error) {
        print('카카오계정으로 로그인 실패: $error');
        setState(() {
          _loginStatus = "카카오계정 로그인 실패: $error";
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await UserApi.instance.logout();
      setState(() {
        _loginStatus = "로그아웃 완료";
      });
    } catch (error) {
      setState(() {
        _loginStatus = "로그아웃 실패: $error";
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
            ElevatedButton(onPressed: kakaoLogin, child: const Text("카카오 로그인")),
            ElevatedButton(onPressed: _logout, child: const Text("로그아웃")),
          ],
        ),
      ),
    );
  }
}
