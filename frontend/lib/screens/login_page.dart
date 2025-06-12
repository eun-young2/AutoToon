import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // AppLinks 인스턴스 (딥링크 스트림을 수신)
  final AppLinks _appLinks = AppLinks();

  // 딥링크 구독 객체
  StreamSubscription<Uri?>? _linkSub;

  // 화면 하단 상태 문자열 (로그인 진행 상황 표시)
  String _status = '로그인되지 않음';

  @override
  void initState() {
    super.initState();

    // ────────────────────────────────────────────────────────────────────────────
    // 1) 앱이 이미 실행 중(포그라운드/백그라운드)일 때 들어오는 딥링크 처리
    //    (Custom Scheme 또는 HTTP 딥링크 모두 uriLinkStream에서 수신)
    // ────────────────────────────────────────────────────────────────────────────
    _linkSub = _appLinks.uriLinkStream.listen((Uri? uri) {
      (uri) => debugPrint('📦 deep-link: $uri');
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      setState(() => _status = '딥링크 수신 오류: $err');
    });

    // ────────────────────────────────────────────────────────────────────────────
    // 2) Cold start(앱이 아예 꺼져 있다가 딥링크로 실행) 시에도
    //    uriLinkStream은 “첫 번째 이벤트”로 해당 URI를 보내 주므로,
    //    별도의 getInitialAppLink 호출이 필요 없습니다.
    // ────────────────────────────────────────────────────────────────────────────
  }

  @override
  void dispose() {
    _linkSub?.cancel(); // 반드시 구독 해지
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  /// 들어온 URI가 Custom Scheme 또는 HTTP 딥링크인지 검사하고,
  /// 그에 따라 동작을 분기 처리합니다.
  void _handleDeepLink(Uri uri) async {
    // ──────────────────────────────────────────────────────────────────────────
    // (A) Custom Scheme 처리 예시:
    //     FastAPI 백엔드가 아래 형태로 RedirectResponse를 호출했다고 가정합니다.
    //       autotoon://login-success?nickname=홍길동&token=XYZ
    //     → 이 경우, uri.scheme == 'autotoon', uri.host == 'login-success'
    // ──────────────────────────────────────────────────────────────────────────
    if (uri.scheme == 'autotoon' && uri.host == 'login-success') {
      final nickname = uri.queryParameters['nickname'];
      final token = uri.queryParameters['token'];
      debugPrint('딥링크(Custom Scheme) 수신 → nick=$nickname, token=$token');

      // 홈 화면('/main')으로 이동하면서 닉네임을 arguments로 전달
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/main',
        arguments: nickname,
      );
      return; // 분기 처리 후 함수를 종료
    }

    // ──────────────────────────────────────────────────────────────────────────
    // (B) HTTP 앱 링크(카카오 콜백) 처리 예시:
    //     FastAPI 백엔드가 인가코드를 받아 처리한 뒤,
    //     다시 아래 HTTP 콜백으로 리디렉트할 경우 사용합니다.
    //       http://10.0.2.2:8000/auth/kakao/callback?code=AbCdEf...
    //     → 이 경우, uri.scheme == 'http', uri.host == '10.0.2.2',
    //       uri.path == '/auth/kakao/callback'
    // ──────────────────────────────────────────────────────────────────────────
    final redirectUri = Uri.parse(dotenv.env['KAKAO_REDIRECT_URI']!);

    if (uri.scheme == redirectUri.scheme && // http 또는 https
        uri.host == redirectUri.host && // 10.0.2.2  / autotoon.ngrok.io
        uri.path == redirectUri.path && // /auth/kakao/callback
        uri.queryParameters['code'] != null) {
      final code = uri.queryParameters['code']!;
      await _sendCodeToBackend(code);
      return;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  /// 백엔드에게 카카오 인가코드를 보내고, JSON 응답(닉네임 + 토큰)을 받아
  /// 로그인 성공 시 '/main'으로 네비게이트합니다.
  Future<void> _sendCodeToBackend(String code) async {
    final apiBase = dotenv.env['API_BASE_URL']!; // .env에 정의된 API_BASE_URL
    final response = await http.get(
      Uri.parse('$apiBase/auth/kakao/callback?code=$code'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final nickname = data['nickname'] as String?;
      final token = data['access_token'] as String?;
      debugPrint('로그인(HTTP 콜백) 성공 → nick=$nickname');

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/main',
        arguments: nickname,
      );
    } else {
      setState(() => _status = '로그인 실패: ${response.body}');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  /// 카카오 로그인 버튼을 눌렀을 때, 백엔드 '/login/kakao' URL을 외부 브라우저(Chrome 등)로 엽니다.
  /// 백엔드가 카카오 로그인 페이지로 리디렉트하면, 사용자가 로그인 후 다시
  /// 콜백 URI(HTTP or Custom Scheme)로 돌아오게 됩니다.
  Future<void> _launchKakaoLogin() async {
    final apiBase = dotenv.env['API_BASE_URL']!;
    final uri = Uri.parse('$apiBase/login/kakao');
    print(uri);
    // 외부 앱(브라우저)을 사용해 URI 실행
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      setState(() => _status = '브라우저 실행 실패');
    } else {
      print("되야함");
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  /// [웹 테스트용]
  /// webOnlyWindowName: '_self' 를 사용해 동일한 웹뷰/페이지 안에서 열기
  /// 실제 모바일 앱에서는 _launchKakaoLogin() 만 사용
  void launchKakaoLoginWeb() async {
    final url = '${dotenv.env['API_BASE_URL']}/login/kakao';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, webOnlyWindowName: '_self');
    } else {
      print('카카오 로그인 URL 실행 실패');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  /// 화면 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ────────────────────────────────────────────────────────────────────────
            // 상단 스페이서
            const SizedBox(height: 8.5),

            // ────────────────────────────────────────────────────────────────────────
// 중앙 로고 텍스트 // 06/11 이미지 수정
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'AutoToon',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/stamps/stamp_peace.gif',
                      width: 40,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),

            // ────────────────────────────────────────────────────────────────────────
            // 하단 이미지 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: GestureDetector(
                // 실제 모바일 앱에서는 아래 onTap: _launchKakaoLogin 만 사용하세요
                onTap: _launchKakaoLogin,
                // 웹 테스트용일 경우 주석을 바꿔 사용하세요:
                // onTap: launchKakaoLoginWeb,

                child: Image.asset(
                  'assets/images/kakao_login_medium_wide.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // ────────────────────────────────────────────────────────────────────────
          ],
        ),
      ),
    );
  }
}
