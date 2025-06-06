import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dx_project_dev2/widgets/alert_dialogs.dart';
import 'package:dx_project_dev2/screens/write_page.dart'
    show WritePage, postContents, postDateTimes, postImages, postStyles;
import '../widgets/double_back_to_exit.dart';
import 'package:dx_project_dev2/utils/image_store.dart';

/// ─────────────────────────────────────────────
class DetailPage extends StatefulWidget {
  const DetailPage({
    Key? key,
  }) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

/// ─────────────────────────────────────────────
class _DetailPageState extends State<DetailPage> {
  bool _rewardShown = false; // 보상 다이얼로그를 이미 띄웠는지 여부

  // 뒤로보내는 함수: source 에 따라 분기
  void _popToSource(String source) {
    switch (source) {
      case 'home':
      // 홈 화면으로 돌아가기
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        break;
      case 'calendar':
      // 캘린더로 돌아가기
        Navigator.pushNamedAndRemoveUntil(context, '/calendar', (route) => false);
        break;
      case 'history':
      // 히스토리로 돌아가기
        Navigator.pushNamedAndRemoveUntil(context, '/history', (route) => false);
        break;
      default:
      // 그 외에 안전하게 홈으로
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    }
  }

  /// TODO – 수정 페이지 이동(원하는 곳으로 push)
  /// “수정하기” 선택 시 호출되는 메서드
  void _editPost(int idx) async {
    final prefs = await SharedPreferences.getInstance();

    // 1) SharedPreferences에서 lastEditDate를 가져와서 오늘 키와 비교
    final storedDate = prefs.getString('lastEditDate');
    final todayKey = DateTime.now().toIso8601String().split('T')[0];

    // 2) 만약 storedDate == todayKey → 이미 오늘 수정한 상태
    if (storedDate == todayKey) {
      // 이미 오늘 수정함 → 수정테이프 사용 다이얼로그 띄우기
      WriteLockDialogs.showUnlockEditDialog(
        context: context,
        onUnlock: () {
          // 수정 잠금 해제 후: 진짜 수정 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WritePage(editIdx: idx),
            ),
          ).then((_) {
            // 수정 후 돌아왔을 때 화면 갱신
            setState(() {});
          });
        },
      );
    } else {
      // 3) 오늘 아직 수정 안 한 상태 → 바로 WritePage(editIdx)로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WritePage(editIdx: idx),
        ),
      ).then((_) {
        // 수정 완료 후 돌아왔을 때 화면 갱신
        setState(() {});
      });
    }
  }

  /// 같은 날짜(연·월·일)를 비교하기 위한 헬퍼
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 하드웨어 백버튼(시스템 뒤로가기) 콜백
  Future<bool> _onWillPop(String source) async {
    // 1) 스택에서 제일 처음(HomePage)이 나오도록 popUntil
    _popToSource(source);
    // 2) false를 반환해서 시스템 종료를 막음
    return false;
  }

  /// ───────────────── UI ──────────────────────
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    // arguments로 Map을 받음: {'idx': int, 'reward': bool}ㄷㄴ메
    if (args is! Map) {
      // 올바른 인덱스가 안 넘어왔을 때
      return const Scaffold(
        body: Center(child: Text('잘못된 접근입니다.')),
      );
    }

    final int idx = args['idx'] as int;
    final reward = args['reward'] as int;
    final String source = (args['source'] as String?) ?? 'home';

    // 전체 게시글 리스트가 비어 있으면, 인덱스로 접근하기 전에 바로 안내 메시지
    if (postDateTimes.isEmpty || postImages.isEmpty || postContents.isEmpty) {
      return WillPopScope(
        onWillPop: () => _onWillPop(source),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Auto Toon'),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _popToSource(source),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: const DoubleBackToExit(
            child: Center(
              child: Text(
                '아직 작성된 게시글이 없습니다.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }
    // -------------------

    // 신규 작성(reward==true)이면, 이 화면 빌드 직후 다이얼로그 띄우기
    if (!_rewardShown && reward > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DiaryRewardDialog.showDiaryRewardDialog(context, reward);
        setState(() {
          _rewardShown = true;
        });
      });
    }

    // 우선 이 idx로부터 해당 게시글의 날짜를 구한다.
    final DateTime baseDate = postDateTimes[idx];

    // 같은 날짜(연·월·일)에 해당하는 모든 인덱스를 찾는다.
    final List<int> sameDayIndices = [];
    for (int i = 0; i < postDateTimes.length; i++) {
      if (_isSameDate(postDateTimes[i], baseDate)) {
        sameDayIndices.add(i);
      }
    }

    // 4) 해당 날짜에 게시글이 하나도 없으면 안내 메시지
    if (sameDayIndices.isEmpty) {
      return WillPopScope(
        onWillPop: () => _onWillPop(source),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Auto Toon'),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _popToSource(source),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: const DoubleBackToExit(
            child: Center(
              child: Text(
                '해당 날짜의 게시글이 없습니다.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }

    // 5) 정상적인 경우 (하나 이상의 게시글이 있을 때)
    return WillPopScope(
      onWillPop: () => _onWillPop(source),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Auto Toon'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _popToSource(source),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),

        /// ─────────────────────────────────────────────
        body: DoubleBackToExit(
          child: Column(
            children: [
              // 날짜 표시 (한 번만 보여 줌)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(baseDate),
                    style: const TextStyle(
                      fontFamily: '온글잎 혜련',
                      fontSize: 20,
                    ),
                  ),
                ),
              ),

              /// ─────────────────────────────────────────────
              // 게시글 목록: 스크롤 가능하도록 Expanded + ListView.builder
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: sameDayIndices.length,
                  itemBuilder: (context, index) {
                    final int postIdx = sameDayIndices[index];
                    final XFile imgFile = postImages[postIdx];
                    final String bodyText = postContents[postIdx];
                    final String styleText = postStyles[postIdx]; // 저장된 스타일

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ───────── 게시글 헤더 (스타일 + PopupMenu) ─────────
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                // 왼쪽: 스타일 표시
                                Text(
                                  styleText,
                                  style: const TextStyle(
                                    fontFamily: '온글잎 혜련',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black26,
                                  ),
                                ),
                                const Spacer(),
                                // 오른쪽: PopupMenu (수정/삭제)
                                PopupMenuButton<String>(
                                  color: const Color(0xFFF5F5F5),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editPost(postIdx);
                                    } else if (value == 'delete') {
                                      // 여기에서 직접 삭제 다이얼로그 함수 호출
                                      DetailAlertDialogs.showDeletePostDialog(
                                        context: context,
                                        idx: postIdx,
                                        onDeleted: () {
                                          // 삭제가 확정된 뒤에 setState로 화면을 갱신해 줍니다.
                                          setState(() {});
                                        },
                                      );
                                    } else if (value == 'store') {
                                      // “툰 저장하기” 선택 시
                                      ImageSaver.saveToGallery(
                                          context, imgFile);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('수정하기'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('삭제하기'),
                                    ),
                                    PopupMenuItem(
                                      value: 'store',
                                      child: Text('툰 저장하기'),
                                    ),
                                    // PopupMenuItem(
                                    //   value: 'thumbnail',
                                    //   child: Text('대표 이미지 지정'),
                                    // ),
                                  ],
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.black54),
                                ),
                              ],
                            ),
                          ),

                          /// ─────────────────────────────────────────────
                          // 이미지 (파일이 없거나 경로가 없을 수 있으니 확인)
                          if (imgFile.path.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(imgFile.path),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          /// ─────────────────────────────────────────────
                          // 본문 텍스트
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              bodyText,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Divider(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
