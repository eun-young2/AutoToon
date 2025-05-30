/// 캘린더 페이지에 있는 감정 패널 영역입니당. 캘린더페이지 코드가 너무 길어져서 빼봣어용
///
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class SentimentPanel extends StatefulWidget {
  final bool expanded;
  final ValueChanged<bool> onExpandChanged;
  final DateTime focused;
  /// ─────────────────────────────────────────────
  const SentimentPanel({
    Key? key,
    required this.expanded,
    required this.onExpandChanged,
    required this.focused,
  }) : super(key: key);

  @override
  State<SentimentPanel> createState() => _SentimentPanelState();
}
/// ─────────────────────────────────────────────
class _SentimentPanelState extends State<SentimentPanel> {
  // 예시용 placeholder 퍼센트
  final percents = [0.45, 0.25, 0.15, 0.10, 0.05];


  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final colors = themeNotifier.palette;

    return GestureDetector(
      onVerticalDragUpdate: (d) {
        if (d.delta.dy < -8) widget.onExpandChanged(true);
        if (d.delta.dy > 8) widget.onExpandChanged(false);
      },
      child: ClipRRect(
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(kSentimentStampAssets.length, (i) {
              final pct = percents[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 35,
                      child: Image.asset(kSentimentStampAssets[i]),
                    ),
                    const SizedBox(width: 12),
                    Text('${(pct * 100).round()}%',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 12),

                    /// ─────────────────────────────────────────────
                    // 게이지
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: pct,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors[i],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
