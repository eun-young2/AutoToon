/// 캘린더 페이지에 있는 감정 패널 영역입니당. 캘린더페이지 코드가 너무 길어져서 빼봣어용
///
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// 백에서 받아올 감정 통계 항목 모델
class EmotionStat {
  final String emotionTag;
  final int count;
  final double ratio;
  EmotionStat({required this.emotionTag, required this.count, required this.ratio});
  factory EmotionStat.fromJson(Map<String, dynamic> json) {
    return EmotionStat(
      emotionTag: json['emotion_tag'] as String,
      count: json['count'] as int,
      ratio: (json['ratio'] as num).toDouble(),
    );
  }
}

class SentimentPanel extends StatefulWidget {
  final int userId;
  final bool expanded;
  final ValueChanged<bool> onExpandChanged;
  final DateTime focused;
  /// ─────────────────────────────────────────────
  const SentimentPanel({
    Key? key,
    required this.userId,
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
  // final percents = [0.45, 0.25, 0.15, 0.10, 0.05];
  bool _isLoading = false;
  List<EmotionStat> _stats = [];
  late int currentUserId;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic stored = prefs.get('userId');
    if (stored is int) {
      currentUserId = stored;
    } else if (stored is String) {
      currentUserId = int.tryParse(stored) ?? widget.userId;
    } else {
      currentUserId = widget.userId;
    }
    print('[SentimentPanel] loaded currentUserId=$currentUserId');
    await _loadMonthlyStats();
  }

  @override
  void didUpdateWidget(covariant SentimentPanel old) {
    super.didUpdateWidget(old);
    if (old.focused.year != widget.focused.year ||
        old.focused.month != widget.focused.month) {
      _loadMonthlyStats();
    }
  }

  Future<void> _loadMonthlyStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchMonthlyStats(
        userId: currentUserId, // widget.userId 대신 currentUserId 사용
        year: widget.focused.year,
        month: widget.focused.month,
      );
      print('[SentimentPanel] userId=$currentUserId, stats=${data['stats']}');
      final list = (data['stats'] as List)
          .map((e) => EmotionStat.fromJson(e as Map<String,dynamic>))
          .toList();
      setState(() => _stats = list);
    } catch (_) {
      setState(() => _stats = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final colors = themeNotifier.palette;

    return GestureDetector(
      onVerticalDragUpdate: (d) {
        if (d.delta.dy < -8) widget.onExpandChanged(true);
        if (d.delta.dy > 8) widget.onExpandChanged(false);
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            kSentimentStampAssets.length,
                (i) {
              // 1) rawRatio: API에서 받은 0~100 값
              final rawRatio = (i < _stats.length) ? _stats[i].ratio : 0.0;
              // 2) pct: 0~1 구간으로 변환
              final pct = rawRatio / 100;
              // 3) 화면에 표시할 퍼센트 텍스트 (소수점 없이)
              final disp = rawRatio.round();

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
                    Text(
                      '$disp%',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 12),

                    /// ─────────────────────────────────────────────
                    // 게이지 (원본 그대로)
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
                            widthFactor: pct,    // <-- 여기만 stat.ratio
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
            },
          ),
        ),
      ),


      // child: ClipRRect(
      //   child: Container(
      //     color: Colors.transparent,
      //     padding: const EdgeInsets.symmetric(vertical: 20),
      //     child:
      //     Column(
      //       mainAxisSize: MainAxisSize.min,
      //       children: List.generate(kSentimentStampAssets.length, (i) {
      //         final pct = percents[i];
      //         return Padding(
      //           padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      //           child: Row(
      //             children: [
      //               SizedBox(
      //                 width: 28,
      //                 height: 35,
      //                 child: Image.asset(kSentimentStampAssets[i]),
      //               ),
      //               const SizedBox(width: 12),
      //               Text('${(pct * 100).round()}%',
      //                   style: const TextStyle(fontSize: 14)),
      //               const SizedBox(width: 12),

      //               /// ─────────────────────────────────────────────
      //               // 게이지
      //               Expanded(
      //                 child: Stack(
      //                   children: [
      //                     Container(
      //                       height: 8,
      //                       decoration: BoxDecoration(
      //                         color: Colors.grey.shade300,
      //                         borderRadius: BorderRadius.circular(4),
      //                       ),
      //                     ),
      //                     FractionallySizedBox(
      //                       widthFactor: pct,
      //                       child: Container(
      //                         height: 8,
      //                         decoration: BoxDecoration(
      //                           color: colors[i],
      //                           borderRadius: BorderRadius.circular(4),
      //                         ),
      //                       ),
      //                     ),
      //                   ],
      //                 ),
      //               ),
      //             ],
      //           ),
      //         );
      //       }),
      //     ),
      //   ),
      // ),
    );
  }
}
