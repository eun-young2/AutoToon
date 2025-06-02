import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────
/// 상단 중앙 “pill-shaped” 배너 위젯
class PillBanner extends StatefulWidget {
  final String message;
  const PillBanner({Key? key, required this.message}) : super(key: key);

  @override
  State<PillBanner> createState() => _PillBannerState();
}

class _PillBannerState extends State<PillBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러: 300ms 동안 슬라이드-다운
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // y축 -1.0 → 0.0 (위에서 아래로)
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // 화면에 추가되자마자 애니메이션 시작
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SafeArea를 활용해 상태바 위에도 안전하게 표시
    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _slideAnim,
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 16, left: 40, right: 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
