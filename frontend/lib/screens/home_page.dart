import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../utils/attendance_helper.dart';
import 'write_page.dart' // postImages / postDateTimes
    show postImages, postDateTimes;
import '../widgets/double_back_to_exit.dart';

// 최신순, 오래된순
enum SortOption { latest, oldest }

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  SortOption _sort = SortOption.latest;

  /// 정렬된 인덱스 리스트를 만들어 두면 detail 로 넘길 때 편하다
  List<int> get _sortedIndexes {
    final idx = List<int>.generate(postImages.length, (i) => i);
    idx.sort((a, b) {
      final cmp = postDateTimes[a].compareTo(postDateTimes[b]);
      return _sort == SortOption.latest ? -cmp : cmp; // 최신순==내림차순
    });
    return idx;
  }

  /// ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // 첫 번째 프레임이 그려진 뒤 출석 체크 로직을 한 번 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AttendanceHelper.checkAttendance(context);
    });
  }
  /// ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final indexes = _sortedIndexes;

    return Scaffold(
      /// ───────────────── AppBar ──────────────────────
      appBar: AppBar(
        title: const Text(
          'AutoToon',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          // 정렬 드롭다운
          Row(
            children: [
              /// ─────────────── 정렬 토글 버튼 ───────────────
              InkWell(
                borderRadius: BorderRadius.circular(4), // 살짝 터치 피드백
                onTap: () {
                  setState(() {
                    // 최신순 ↔ 오래된순 토글
                    _sort = _sort == SortOption.latest
                        ? SortOption.oldest
                        : SortOption.latest;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _sort == SortOption.latest
                          ? LineAwesomeIcons.sort_amount_down_solid // 최신순 ↓
                          : LineAwesomeIcons.sort_amount_up_solid, // 오래된순 ↑
                      size: 18,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _sort == SortOption.latest ? '최신순' : '오래된순',
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),

      /// ───────────────── Body ──────────────────────
      body: DoubleBackToExit(
        child: postImages.isEmpty
            ? const Center(child: Text('작성한 일기가 없습니다'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: indexes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (_, listIdx) {
                  final realIdx = indexes[listIdx];
                  final date = postDateTimes[realIdx];
                  final img = postImages[realIdx];
        
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/detail',
                      arguments: {
                        'idx' :realIdx,
                        'reward': 0,   // 보상이 없으면 0
                        'source': 'home'
                      }  // detail_page 는 단일 index 처리
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 날짜 헤더
                        Text(
                          DateFormat('yyyy.MM.dd').format(date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 썸네일 (가로꽉차게 1칸)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(img.path),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}