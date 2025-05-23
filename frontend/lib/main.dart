import 'package:dx_project_dev2/screens/calendar_page.dart';
import 'package:dx_project_dev2/screens/detail_design.dart';
import 'package:dx_project_dev2/screens/detail_page.dart';
import 'package:dx_project_dev2/screens/likes_page.dart';
import 'package:dx_project_dev2/screens/login_page.dart';
import 'package:dx_project_dev2/screens/main_page.dart';
import 'package:dx_project_dev2/screens/member_info_page.dart';
import 'package:dx_project_dev2/screens/profile_page.dart';
import 'package:dx_project_dev2/screens/signup_page.dart';
import 'package:dx_project_dev2/screens/write_page.dart';
import 'package:dx_project_dev2/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


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
        fontFamily: '온글잎 혜련',
        primaryColor: const Color.fromARGB(255, 255, 255, 255),
        scaffoldBackgroundColor: AppTheme.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.background,    // AppBar 배경을 전체 배경과 동일하게
          elevation: 0,                             // 그림자 제거
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
        '/design': (context) => const DetailDesign(),
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