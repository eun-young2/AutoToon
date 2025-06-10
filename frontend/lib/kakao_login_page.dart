import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 환경변수 사용

class KakaoLoginPage extends StatefulWidget {
  const KakaoLoginPage({super.key});

  @override
  State<KakaoLoginPage> createState() => _KakaoLoginPageState();
}

class _KakaoLoginPageState extends State<KakaoLoginPage> {
  String _loginStatus = "로그인되지 않음";

  Future<void> kakaoLogin() async {
    print("hello");
    try {
      String code;
      bool talkInstalled = await isKakaoTalkInstalled();

      final redirectUri = dotenv.env['KAKAO_REDIRECT_URI']!;
      debugPrint('🔍 redirectUri -> $redirectUri');

      print(talkInstalled);
      if (talkInstalled) {
        code = await AuthCodeClient.instance.authorizeWithTalk(
          redirectUri: redirectUri,
        );
      } else {
        code = await AuthCodeClient.instance.authorize(
          redirectUri: redirectUri,
        );
      }

      setState(() {
        _loginStatus = "인가코드 받음: $code";
      });

      // 받은 인가코드를 FastAPI 서버로 전달
      final apiBaseUrl = dotenv.env['API_BASE_URL']!;
      print('API → ${dotenv.env['API_BASE_URL']}');
      final response = await http.get(
        Uri.parse('$apiBaseUrl/auth/kakao/callback?code=$code'),
      );
      setState(() {
        _loginStatus = "서버 응답: ${response.body}";
      });
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
