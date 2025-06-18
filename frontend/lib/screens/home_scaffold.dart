// 화면전환 비동기로 만들어 보기
import 'package:dx_project_dev2/screens/history_page.dart';
import 'package:dx_project_dev2/screens/member_info_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'calendar_page.dart';
import 'write_page.dart';

class HomeScaffold extends StatefulWidget {
  final int userId;
  final String nickname;
  final String? token;

  const HomeScaffold({
    Key? key,
    required this.userId,
    required this.nickname,
    this.token,
  }) : super(key: key);

  @override
  _HomeScaffoldState createState() => _HomeScaffoldState();
}

/// ─────────────────────────────────────────────
class _HomeScaffoldState extends State<HomeScaffold> {
  int _currentIndex = 0;
  int? _editIdx;
  late final List<Widget> _pages = [
    MainPage(userId: widget.userId),
    CalendarPage(userId: widget.userId),
    WritePage(userId: widget.userId),
    HistoryPage(userId: widget.userId),
    MemberInfoPage(),
  ];

  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['홈', '달력', '작성', '히스토리', '프로필'][_currentIndex]),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) {
          final beginOffset =
              Offset(_pages.indexOf(child) > _currentIndex ? 1 : -1, 0);
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

  /// ─────────────────────────────────────────────
}
