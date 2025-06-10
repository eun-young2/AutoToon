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
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        Navigator.pushNamedAndRemoveUntil(
            context, '/calendar', (route) => false);
        break;
      case 'history':
        // 히스토리로 돌아가기
        Navigator.pushNamedAndRemoveUntil(
            context, '/history', (route) => false);
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
    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    final userId = prefs.getString('userId');

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    // 1) 서버에서 최신 사용자의 correction_tape_item 값을 조회
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://211.188.62.213:8000';
    final getUri = Uri.parse('$baseUrl/api/users/$userId');
    int serverTapeCount = 0;

    try {
      final getResponse = await http.get(getUri);
      if (getResponse.statusCode == 200) {
        final data = jsonDecode(getResponse.body);
        serverTapeCount = data['correction_tape_item'] ?? 0;
      } else {
        print(
          '수정테이프 조회 실패 (HTTP ${getResponse.statusCode}): ${getResponse.body}',
        );
        // 서버 오류이므로 안전하게 원래 WritePage로 바로 이동하거나 멈춤
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버에서 사용자 정보를 가져오지 못했습니다.')),
        );
        return;
      }
    } catch (e) {
      print('서버 호출 중 오류(조회): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
      return;
    }

    // 2) SharedPreferences에 저장된 lastEditDate 확인
    final storedDate = prefs.getString('lastEditDate');

    if (storedDate == todayKey) {
      // 오늘 이미 수정한 상태이므로, 수정테이프 사용 대화상자
      WriteLockDialogs.showUnlockEditDialog(
        context: context,
        onUnlock: () async {
          // 3) 서버에서 받아온 serverTapeCount 가 0 이하인지 확인
          if (serverTapeCount <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('수정테이프가 부족합니다.')),
            );
            return;
          }

          // 4) newCount = serverTapeCount - 1
          final newCount = serverTapeCount - 1;

          // 5) 로컬 SharedPreferences에도 차감된 값 저장
          await prefs.setInt('correctionTapeCount', newCount);

          // 6) 서버에 PATCH 요청: correction_tape_item = newCount
          final patchUri = Uri.parse('$baseUrl/api/users/$userId');
          try {
            final patchResponse = await http.patch(
              patchUri,
              headers: {
                'Content-Type': 'application/json',
                // 인증 헤더가 있다면 여기에 추가
              },
              body: jsonEncode({'correction_tape_item': newCount}),
            );
            if (patchResponse.statusCode == 200) {
              print('서버에 수정테이프 차감 완료: $newCount');
            } else {
              print(
                '서버 수정테이프 차감 실패 (HTTP ${patchResponse.statusCode}): ${patchResponse.body}',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('서버 업데이트가 실패했습니다.')),
              );
              return;
            }
          } catch (e) {
            print('서버 호출 중 오류(차감): $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
            );
            return;
          }

          // 7) 오늘 마지막 수정 날짜를 저장
          await prefs.setString('lastEditDate', todayKey);

          // 8) 진짜 수정 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WritePage(editIdx: idx),
            ),
          ).then((_) {
            setState(() {}); // 돌아왔을 때 화면 갱신
          });
        },
      );
    } else {
      // 오늘 한 번도 수정 안 했으면 바로 수정 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WritePage(editIdx: idx),
        ),
      ).then((_) {
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
    final validRoutes = ['main', 'calendar', 'history'];
    final route = validRoutes.contains(source) ? '/$source' : '/main';

    // 기존 popAndPushNamed 대신 pushReplacementNamed 또는 pushNamedAndRemoveUntil 사용
    Navigator.pushReplacementNamed(context, route);

    return true; // ✅ 시스템 pop 허용하여 화면 전환 정상 처리
  }

  /// ───────────────── UI ──────────────────────
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    // arguments로 Map을 받음: {'idx': int, 'reward': bool}
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
              onPressed: () {
                final validRoutes = ['main', 'calendar', 'history'];
                final route =
                    validRoutes.contains(source) ? '/$source' : '/main';

                Navigator.pushReplacementNamed(context, route);
              },
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
              onPressed: () {
                final validRoutes = ['main', 'calendar', 'history'];
                final route =
                    validRoutes.contains(source) ? '/$source' : '/main';

                Navigator.pushReplacementNamed(context, route);
              },
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
            onPressed: () {
              final validRoutes = ['main', 'calendar', 'history'];
              final route = validRoutes.contains(source) ? '/$source' : '/main';

              Navigator.pushReplacementNamed(context, route);
            },
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
