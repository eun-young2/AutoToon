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

      initialRoute: '/intro',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/main': (context) => const MainWithTabs(),
        '/calendar': (context) => const CalendarPage(),
        '/write': (context) => const WritePage(),
        '/history': (_) => const HistoryPage(),
        '/intro': (context) => const IntroPage(),
        '/detail': (context) => const DetailPage(),
        '/member': (context) => const MemberInfoPage(),
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
  const MainWithTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 5, // 탭 개수 (홈, 일정, 게시, 좋아요, 프로필)
      initialIndex: 0, // 시작 탭
      child: Scaffold(
        // AppBar 나 Drawer 가 필요하면 여기 추가 가능
        body: TabBarView(
          physics: BouncingScrollPhysics(),
          children: [
            MainPage(),
            CalendarPage(),
            WritePage(),
            HistoryPage(),
            MemberInfoPage(),
          ],
        ),
        bottomNavigationBar: BottomNav(),
      ),
    ); 
  }
}

/// ─────────────────────────────────────────────
