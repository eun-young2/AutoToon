import 'package:dx_project_dev2/screens/calendar_page.dart';
import 'package:dx_project_dev2/screens/detail_page.dart';
import 'package:dx_project_dev2/screens/likes_page.dart';
import 'package:dx_project_dev2/screens/login_page.dart';
import 'package:dx_project_dev2/screens/main_page.dart';
import 'package:dx_project_dev2/screens/profile_page.dart';
import 'package:dx_project_dev2/screens/signup_page.dart';
import 'package:dx_project_dev2/screens/write_page.dart';
import 'package:dx_project_dev2/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'; // 카카오 로그인 SDK import
import 'package:flutter_dotenv/flutter_dotenv.dart'; // .env 파일을 사용하기 위한 패키지
import 'kakao_login_page.dart'; // 경로 확인
import 'package:dx_project_dev2/screens/user_info_test_page.dart';

void main() async {
  // Flutter 프레임워크의 비동기 초기화를 보장 (필수)
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일을 비동기로 로드 (여기서 환경변수들이 메모리에 올라감)
  await dotenv.load();

  // ★★★★★★★★배포 시 반드시 삭제!!★★★★★★★★
  // 환경변수 정상 로드 확인 (개발/디버깅용)
  print('카카오 네이티브 앱키: ${dotenv.env['KAKAO_NATIVE_APP_KEY']}');
  print('카카오 JS 앱키: ${dotenv.env['KAKAO_JAVASCRIPT_APP_KEY']}');
  //////////////////////////////////////////////////////////////////////////////

  // 카카오 SDK 초기화 (앱/웹 모두 지원)
  // - 네이티브 앱 키: Android/iOS에서 사용
  // - 자바스크립트 앱 키: 웹(Flutter Web)에서 사용
  // - 두 키를 모두 전달하면 플랫폼에 맞게 자동 적용됨
  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'],
    javaScriptAppKey: dotenv.env['KAKAO_JAVASCRIPT_APP_KEY'],
  );

  // 앱 실행 (DxApp은 전체 앱의 루트 위젯)
  runApp(const DxApp());
}

class DxApp extends StatelessWidget {
  const DxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DX Project App',
      theme: ThemeData(
        primaryColor: AppTheme.primary,
        scaffoldBackgroundColor: AppTheme.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.background, // AppBar 배경을 전체 배경과 동일하게
          elevation: 0, // 그림자 제거
        ),
      ),
      initialRoute: '/login', // 앱 시작 시 보여줄 첫 화면
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/main': (context) => const MainPage(),
        '/calendar': (context) => const CalendarPage(),
        '/write': (context) => const WritePage(),
        '/likes': (context) => const LikesPage(),
        '/profile': (context) => const ProfilePage(),
        '/detail': (context) => const DetailPage(),
        '/userInfoTest': (context) => const UserInfoTestPage(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      locale: const Locale('ko', 'KR'),
    );
  }
}
