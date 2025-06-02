import 'dart:io';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'write_page.dart'            // postImages, postDateTimes …
    show postImages;                // (필요하면 postContents 도 불러오세요)

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  /// true  → 4칸, false → 3칸
  bool _fourColumns = false;

  @override
  Widget build(BuildContext context) {
    final images = postImages;                  // 작성된 글들의 썸네일 이미지
    final crossCount = _fourColumns ? 4 : 3;    // 현재 열 수

    return Scaffold(
      // ────────────────  AppBar  ────────────────
      appBar: AppBar(
        title: const Text('히스토리'),
        centerTitle: true,
        actions: [
          // 그리드 토글 아이콘
          IconButton(
            icon: Icon(
              _fourColumns ? LineAwesomeIcons.th_large_solid   // 4칸 → 눌렀을 때 3칸 아이콘
                  : LineAwesomeIcons.btc,             // 3칸 → 눌렀을 때 4칸 아이콘
              size: 22,
              color: Colors.black,
            ),
            onPressed: () => setState(() => _fourColumns = !_fourColumns),
            tooltip: _fourColumns ? '3칸 보기' : '4칸 보기',
          ),
        ],
      ),
      // ────────────────  Body  ────────────────
      body: images.isEmpty
          ? const Center(child: Text('아직 작성한 일기가 없습니다'))
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: images.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (_, idx) {
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/detail',          // 이미 라우트에 등록돼 있을 DetailPage
              arguments: idx,     // ▶ WritePage 에서 쓰던 방식 그대로
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(images[idx].path),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
