import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

/// 앱 전역 바텀 네비게이션 위젯
/// currentIndex: 현재 활성화된 탭 인덱스 (0~3)
/// onWillNavigate: 탭 이동 전 호출, false 반환 시 이동 취소
class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Future<bool> Function(BuildContext context, int index)? onWillNavigate;

  const BottomNav({
    Key? key,
    required this.currentIndex,
    this.onWillNavigate,
  }) : super(key: key);

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        Navigator.pushReplacementNamed(context, '/main');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/calendar');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/write');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/likes');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30), // 하단으로 더 내림
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE6C4C2),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, -1), // 상단에 그림자
            ),
          ],
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => _onTap(context, index),
          backgroundColor: Colors.white,
          indicatorColor: Colors.transparent,
          destinations: const [
            NavigationDestination(
              icon: Icon(LineAwesomeIcons.home_solid, size: 30),
              selectedIcon: Icon(LineAwesomeIcons.home_solid, size: 30),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(LineAwesomeIcons.calendar_alt, size: 30),
              selectedIcon: Icon(LineAwesomeIcons.calendar_alt, size: 30),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(LineAwesomeIcons.plus_square, size: 30),
              selectedIcon: Icon(LineAwesomeIcons.plus_square, size: 30),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(LineAwesomeIcons.heart, size: 30),
              selectedIcon: Icon(LineAwesomeIcons.heart, size: 30),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(LineAwesomeIcons.user, size: 30),
              selectedIcon: Icon(LineAwesomeIcons.user, size: 30),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
