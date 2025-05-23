import 'package:dx_project_dev2/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


import 'package:dx_project_dev2/screens/calendar_page.dart';
import 'package:dx_project_dev2/screens/detail_page.dart';
import 'package:dx_project_dev2/screens/intro_page.dart';
import 'package:dx_project_dev2/screens/likes_page.dart';
import 'package:dx_project_dev2/screens/login_page.dart';
import 'package:dx_project_dev2/screens/main_page.dart';
import 'package:dx_project_dev2/screens/profile_page.dart';
import 'package:dx_project_dev2/screens/signup_page.dart';
import 'package:dx_project_dev2/screens/write_page.dart';
import 'package:dx_project_dev2/theme/app_theme.dart';


void main() {
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
        fontFamily: '온글잎 혜련',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.background,    // AppBar 배경을 전체 배경과 동일하게
          elevation: 0,                             // 그림자 제거
        ),
      ),
      // builder: (context, child) {
      //   return TexturedBackground(child: child!);
      // },
      initialRoute: '/intro',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/main': (context) => const MainWithTabs(),
        '/calendar': (context) => const CalendarPage(),
        '/write': (context) => const WritePage(),
        '/likes': (context) => const LikesPage(),
        '/profile': (context) => const ProfilePage(),
        '/intro': (context) => const IntroPage(),
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

/// ─────────────────────────────────────────────
/// /main 루트에서 보여줄 탭 구조
/// ─────────────────────────────────────────────
class MainWithTabs extends StatelessWidget {
  const MainWithTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 5,              // 탭 개수 (홈, 일정, 게시, 좋아요, 프로필)
      initialIndex: 0,        // 시작 탭
      child: Scaffold(
        // AppBar 나 Drawer 가 필요하면 여기 추가 가능
        body: TabBarView(
          physics: BouncingScrollPhysics(),
          children: [
            MainPage(),
            CalendarPage(),
            WritePage(),
            LikesPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: BottomNav(),
      ),
    );
  }
}