// 화면전환 비동기로 만들어 보기
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'main_page.dart';
import 'calendar_page.dart';
import 'write_page.dart';
import 'likes_page.dart';
import 'profile_page.dart';

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({Key? key}) : super(key: key);

  @override
  _HomeScaffoldState createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    MainPage(),
    CalendarPage(),
    WritePage(),
    LikesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['홈', '달력', '작성', '좋아요', '프로필'][_currentIndex]),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) {
          final beginOffset =
          Offset(_pages.indexOf(child!) > _currentIndex ? 1 : -1, 0);
          return SlideTransition(
            position: Tween<Offset>(begin: beginOffset, end: Offset.zero)
                .animate(anim),
            child: child,
          );
        },
        child: SizedBox(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
    );
  }
}