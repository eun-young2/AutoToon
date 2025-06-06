// 바텀 내비게이션
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({Key? key}) : super(key: key);

  static const _icons = [
    LineAwesomeIcons.home_solid,
    LineAwesomeIcons.calendar,
    LineAwesomeIcons.plus_square,
    LineAwesomeIcons.history_solid,
    LineAwesomeIcons.user,
  ];

  @override
  Widget build(BuildContext context) {
    // 1) TabController 가져오기
    final tabController = DefaultTabController.of(context);

    /// ─────────────────────────────────────────────
    // 2) AnimatedBuilder 로 탭 컨트롤러를 리스닝
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final currentIndex = tabController.index;
        final count = _icons.length;
        // -1.0 부터 +1.0 까지 분할해서 alignment.x 를 계산
        final raw   = (2 * currentIndex + 1) / count - 1;

        const extra = 0.85; // 1.0보다 크면 양쪽으로 더 늘어남
        final scale = (count / (count - 1)) * extra;
        final alignX= raw * scale;

        return Container(
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black26, blurRadius: 1, offset: Offset(0, -1)),
            ],
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              /// ─────────────────────────────────────────────
              // 1) 아이콘 Row
              Row(
                children: List.generate(_icons.length, (idx) {
                  final selected = idx == currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => tabController.animateTo(idx),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        // 8픽셀 만큼 아래쪽 여백
                        child: Icon(
                          _icons[idx],
                          size: 28,
                          color: selected ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              /// ─────────────────────────────────────────────
              // 2) 선택된 탭 위의 슬라이딩 바
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                alignment: Alignment(alignX, -1.0),
                child: Container(
                  height: 2,
                  width: 24,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              /// ─────────────────────────────────────────────
            ],
          ),
        );
      },
    );
  }
}
