import 'dart:io';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'write_page.dart' // postImages, postDateTimes …
    show
        postImages; // (필요하면 postContents 도 불러오세요)
import '../widgets/double_back_to_exit.dart';
import '../models/diary_model.dart';
import '../services/api_service.dart';

class HistoryPage extends StatefulWidget {
  final int userId;
  const HistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  /// true  → 4칸, false → 3칸
  bool _fourColumns = false;
  List<Diary> _diaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    try {
      final diaries = await ApiService.fetchUserDiaries(widget.userId);
      setState(() {
        _diaries = diaries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _diaries = [];
      });
      // 에러 처리는 필요에 따라 추가
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = postImages; // 작성된 글들의 썸네일 이미지
    final crossCount = _fourColumns ? 4 : 3; // 현재 열 수

    return Scaffold(
      // ────────────────  AppBar  ────────────────
      appBar: AppBar(
        title: const Text('히스토리'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // 그리드 토글 아이콘
          IconButton(
            icon: Icon(
              _fourColumns
                  ? LineAwesomeIcons.th_large_solid // 4칸 → 눌렀을 때 3칸 아이콘
                  : LineAwesomeIcons.btc, // 3칸 → 눌렀을 때 4칸 아이콘
              size: 24,
              color: Colors.black,
            ),
            onPressed: () => setState(() => _fourColumns = !_fourColumns),
            tooltip: _fourColumns ? '3칸 보기' : '4칸 보기',
          ),
        ],
      ),
      // ────────────────  Body  ────────────────
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _diaries.isEmpty
            ? const Center(child: Text('아직 작성한 일기가 없습니다'))
            : GridView.builder(
                padding: const EdgeInsets.only(top: 8.0),
                itemCount: _diaries.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemBuilder: (_, idx) {
                  final diary = _diaries[idx];
                  final imgUrl = ApiService.fullImageUrl(
                      diary.thumbPath ?? diary.mergedPath ?? '');
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/detail',
                        arguments: {
                          'diary': diary,
                          'reward': 0,
                          'source': 'history',
                          'userId': diary.userId,
                        },
                      ),
                      splashColor: Colors.black12,
                      highlightColor: Colors.black12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: imgUrl.isEmpty
                            ? Container(color: Colors.grey)
                            : Image.network(
                                imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
      // DoubleBackToExit(
      //   child: images.isEmpty
      //       ? const Center(child: Text('아직 작성한 일기가 없습니다'))
      //       : GridView.builder(
      //           padding: const EdgeInsets.only(top: 8.0),
      //           itemCount: images.length,
      //           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      //             crossAxisCount: crossCount,
      //             crossAxisSpacing: 3,
      //             mainAxisSpacing: 3,
      //           ),
      //           itemBuilder: (_, idx) {
      //             return Material(
      //               color: Colors.transparent,
      //               child: InkWell(
      //                 onTap: () => Navigator.pushNamed(
      //                     context, '/detail', // 이미 라우트에 등록돼 있을 DetailPage
      //                     arguments: {
      //                       'idx': idx,
      //                       'reward': 0,
      //                       'source': 'history',
      //                     } // ▶ WritePage 에서 쓰던 방식 그대로
      //                     ),
      //                 splashColor:
      //                     Colors.black12, // 터치시 퍼지는 잉크 색 (원하는 색으로 조정 가능)
      //                 highlightColor: Colors.black12, // 터치시 배경 하이라이트 색s
      //                 child: ClipRRect(
      //                   borderRadius: BorderRadius.circular(0),
      //                   child: Image.file(
      //                     File(images[idx].path),
      //                     fit: BoxFit.cover,
      //                   ),
      //                 ),
      //               ),
      //             );
      //           },
      //         ),
      // ),
    );
  }
}
