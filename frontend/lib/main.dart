import 'package:dx_project_dev2/screens/history_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:dx_project_dev2/screens/member_info_page.dart';
import 'package:dx_project_dev2/screens/calendar_page.dart';
import 'package:dx_project_dev2/screens/detail_page.dart';
import 'package:dx_project_dev2/screens/intro_page.dart';
import 'package:dx_project_dev2/screens/login_page.dart';
import 'package:dx_project_dev2/screens/home_page.dart';
import 'package:dx_project_dev2/screens/signup_page.dart';
import 'package:dx_project_dev2/screens/write_page.dart';

import 'package:dx_project_dev2/theme/app_theme.dart';
import 'package:dx_project_dev2/widgets/bottom_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final themeNotifier = ThemeNotifier();
  // 앱 시작 전에 미리 팔레트 계산
  themeNotifier.initSentimentPalette();

  runApp(
    ChangeNotifierProvider<ThemeNotifier>.value(
      value: themeNotifier,
      child: const DxApp(),
    ),
  );
}

class DxApp extends StatelessWidget {
  const DxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider 로부터 현재 테마 모드 읽기
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DX Project App',

      // 라이트/다크 테마 설정
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.paperTheme,

      // 실제로 사용할 모드 선택
      themeMode: themeNotifier.isPaperMode ? ThemeMode.dark : ThemeMode.light,

      // 최초 진입 라우트
      initialRoute: '/intro',

      routes: {
        '/login':    (context) => const LoginPage(),
        '/signup':   (context) => const SignupPage(),

        // ─────────────────── 탭으로 진입하는 경로들 ───────────────────
        // '/main'로 들어오면 “홈 탭”이 활성화 된 MainWithTabs
        '/main':     (context) => const MainWithTabs(initialIndex: 0),

        // '/calendar'로 들어오면 “캘린더 탭”이 활성화 된 MainWithTabs
        '/calendar': (context) => const MainWithTabs(initialIndex: 1),

        // '/write'를 탭 2(글쓰기 탭)로 재사용하고 싶다면
        '/writeTab': (context) => const MainWithTabs(initialIndex: 2),

        // '/history'로 들어오면 “히스토리 탭”이 활성화 된 MainWithTabs
        '/history':  (context) => const MainWithTabs(initialIndex: 3),

        // '/member'로 들어오면 “멤버 탭”이 활성화 된 MainWithTabs
        '/member':   (context) => const MainWithTabs(initialIndex: 4),

        // ─────────────────── 탭 외부로 띄우는 경로들 ───────────────────
        '/intro':    (context) => const IntroPage(),
        '/detail':   (context) => const DetailPage(),

        // 혹시 탭 외부에서 직접 WritePage를 띄우고 싶으면
        '/write':    (context) => const WritePage(),
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

/// ─────────────────────────────────────────────
/// /main 루트에서 보여줄 탭 구조
class MainWithTabs extends StatelessWidget {
  final int initialIndex;
  const MainWithTabs({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // 탭 개수 (홈, 일정, 게시, 좋아요, 프로필)
      initialIndex: initialIndex, // 시작탭
      child: const Scaffold(
        body: const TabBarView(
          physics: BouncingScrollPhysics(),
          children: [
            MainPage(),       // index = 0
            CalendarPage(),   // index = 1
            WritePage(),      // index = 2
            HistoryPage(),    // index = 3
            MemberInfoPage(), // index = 4
          ],
        ),
        bottomNavigationBar: BottomNav(),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
