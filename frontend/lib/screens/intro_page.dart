import 'package:flutter/material.dart';
import 'package:dx_project_dev2/screens/login_page.dart';
import '../widgets/double_back_to_exit.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  bool _tapped = false;
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    // 1초 주기로 부드럽게 페이드 인/아웃 반복
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }
  /// ─────────────────────────────────────────────
  void _onTap() {
    setState(() => _tapped = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (ctx, anim, anim2) => FadeTransition(
            opacity: anim,
            child: const LoginPage(),
          ),
        ),
      );
    });
  }
  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DoubleBackToExit(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tapped ? null : _onTap,
          child: AnimatedOpacity(
            opacity: _tapped ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            child: Column(
              children: [
                /// ─────────────────────────────────────────────
                // 1) Expanded로 로고를 화면 중앙에 배치
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
                          'assets/stamps/stamp_happy.gif',
                          width: 32,
                          height: 32,
                        ),
                      ],
                    ),
                  ),
                ),
                /// ─────────────────────────────────────────────
                // 2) 맨 아래에 텍스트 배치
                FadeTransition(
                  opacity: _blinkController.drive(
                    CurveTween(curve: Curves.easeInOut),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      '계속하려면 이곳을 터치해 주세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                /// ─────────────────────────────────────────────
              ],
            ),
          ),
        ),
      ),
    );
  }
}
