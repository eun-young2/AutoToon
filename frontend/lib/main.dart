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

void main() async {
  // Flutter 프레임워크의 비동기 초기화를 보장 (필수)
  WidgetsFlutterBinding.ensureInitialized();
  // .env 파일을 비동기로 로드 (여기서 환경변수들이 메모리에 올라감)
  await dotenv.load();
  // 카카오 SDK 초기화
  // .env 파일에서 NATIVE_APP_KEY 값을 불러와서 사용
  KakaoSdk.init(
    nativeAppKey: dotenv.env['NATIVE_APP_KEY'], // .env 파일에 있는 실제 키 불러오기
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/main': (context) => const MainPage(),
        '/calendar': (context) => const CalendarPage(),
        '/write': (context) => const WritePage(),
        '/likes': (context) => const LikesPage(),
        '/profile': (context) => const ProfilePage(),
        '/detail': (context) => const DetailPage(),
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
