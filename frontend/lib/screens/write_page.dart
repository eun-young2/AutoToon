import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

import '../widgets/alert_dialogs.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/double_back_to_exit.dart';
import '../widgets/member_info_components.dart';
import '../widgets/modal.dart';
import 'detail_page.dart';
import 'package:workmanager/workmanager.dart';  // 06/11 ++ 임포트 추가

/// 전역 리스트 선언 (이미지, 텍스트, 작성시간, 이미지스타일)
final List<XFile> postImages = [];
final List<String> postTitles = [];
final List<String> postContents = [];
final List<DateTime> postDateTimes = [];
final List<String> postStyles = [];

/// 좋아요 누른 게시글 인덱스 모아두기
final Set<int> likedPosts = {};

class WritePage extends StatefulWidget {
  /// editIdx: null 이면 신규 작성, 정수값(idx)이 넘어오면 수정 모드
  final int? editIdx;

  const WritePage({Key? key, this.editIdx}) : super(key: key);

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _contentCtrl = TextEditingController();
  String _selectedStyle = '캐릭터';
  bool _isEditMode = false; // 수정 모드 여부

  String? _questionText; // 질문 텍스트 상태
  bool _isLoadingQuestion = false; // 질문 로딩 중 여부

  /// 로딩 애니메이션용 인덱스 (0, 1, 2 순환)
  int _loadingDotIndex = 0;
  int _loadingDotDirection = 1; // 방향 변수
  Timer? _loadingDotTimer;

  /// “질문으로 일기 시작하기” 버튼 클릭 시 로딩 + 질문 표시
  void _loadQuestion() {
    setState(() {
      _isLoadingQuestion = true;
      _questionText = null;
      _loadingDotIndex = 0;
    });

    // 600ms마다 _loadingDotIndex를 0→1→2→1→0… 순환시켜 애니메이션을 갱신
    _loadingDotTimer =
        Timer.periodic(const Duration(milliseconds: 600), (timer) {
      setState(() {
        // 인덱스를 더하거나 빼기 전에, 경계(0 또는 2)에 도달하면 방향을 변경
        if (_loadingDotIndex == 2) {
          _loadingDotDirection = -1;
        } else if (_loadingDotIndex == 0) {
          _loadingDotDirection = 1;
        }
        _loadingDotIndex += _loadingDotDirection;
      });
    });

    // 3초 뒤에 타이머 취소하고 질문 텍스트 표시
    Future.delayed(const Duration(seconds: 3), () {
      _loadingDotTimer?.cancel();
      setState(() {
        _isLoadingQuestion = false;
        _questionText = "오늘 가장 기뻤던 순간은?"; // 실제 API 호출 로직으로 교체 가능
      });
    });
  }

  /// ─────────────────────────────────────────────
  // CSV에서 읽어온 문구
  List<String> _facts = [];
  List<String> _balancePrompts = [];

  /// ─────────────────────────────────────────────
  // 글쓰기 하나로 제한하기
  bool _hasWrittenToday = false;

  /// ─────────────────────────────────────────────
  // MemberInfoPage에서 저장된 아이템 개수를 SharedPreferences에서 불러올 변수
  int _correctionTapeCount = 0;
  int _diaryCount = 0;

  late final String _baseUrl;

  @override
  void initState() {
    super.initState();

    // “수정 모드”로 넘겨받은 postIdx가 있으면, 수정 모드로 전환하고
    // 기존 postContents, postStyles, postImages를 미리 세팅
    if (widget.editIdx != null) {
      final idx = widget.editIdx!;
      _isEditMode = true;
      // 기존에 작성된 내용을 텍스트 컨트롤러에 넣어두기
      _contentCtrl.text = postContents[idx];
      // 기존 스타일도 선택해 놓기
      _selectedStyle = postStyles[idx];
      // 기존 이미지가 있으면 _image에 세팅 (빈 XFile이라면 null 처리)
      final existing = postImages[idx];
      if (existing.path.isNotEmpty) {
        _image = existing;
      }
    }

    // SharedPreferences에서 보유 아이템 개수 불러오기 (초기 UI 반영용)
    _loadCountsFromPrefs();

    // 서버에서 아이템 개수를 가져와서 상태 및 SharedPreferences 동기화
    _loadCountsFromServer();

    // 글자 수 실시간 업데이트를 위해 컨트롤러 리스너 추가
    _contentCtrl.addListener(() {
      setState(() {});
    });

    /// ─────────────────────────────────────────────
    // 오늘 게시글 작성했는지 여부 체크하는 로직
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.now();
      final wrote = postDateTimes.any((d) =>
          d.year == today.year && d.month == today.month && d.day == today.day);
      // 수정 모드인 경우, _hasWrittenToday는 강제로 false로 두어
      // 텍스트 입력창이 열린 상태를 유지하게 함
      setState(() => _hasWrittenToday = _isEditMode ? false : wrote);
    });

    // CSV 프롬프트 읽기
    _loadPrompts();

    // .env에서 API_BASE_URL 가져오기
    _baseUrl = dotenv.env['API_BASE_URL'] ?? "http://10.0.2.2:8000";
  }

  /// SharedPreferences에서 아이템 개수만 가져오기 (초기 UI 반영용)
  Future<void> _loadCountsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _correctionTapeCount = prefs.getInt('correctionTapeCount') ?? 0;
      _diaryCount = prefs.getInt('diaryCount') ?? 0;
    });
  }

  /// 서버에서 사용자 정보를 GET → correction_tape_item, diary_item 가져와서 상태 및 SharedPreferences 동기화
  Future<void> _loadCountsFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null || userId.isEmpty) return;

    final uri = Uri.parse('$_baseUrl/api/users/$userId');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serverTapeCount = data['correction_tape_item'] as int? ?? 0;
        final serverDiaryCount = data['diary_item'] as int? ?? 0;

        // 로컬 상태에 반영
        setState(() {
          _correctionTapeCount = serverTapeCount;
          _diaryCount = serverDiaryCount;
        });

        // SharedPreferences에도 동기화
        await prefs.setInt('correctionTapeCount', serverTapeCount);
        await prefs.setInt('diaryCount', serverDiaryCount);
      } else {
        print('사용자 정보 조회 실패 (HTTP ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('사용자 정보 조회 중 오류: $e');
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _loadingDotTimer?.cancel();
    super.dispose();
  }

  /// ─────────────────────────────────────────────
  /// assets/폴더에 담긴 CSV 파일을 읽어서 리스트로 변환
  Future<void> _loadPrompts() async {
    // 1) 지식 문구 CSV
    final rawFacts =
        await rootBundle.loadString('assets/modals/Useful_information.csv');
    final factRows = const CsvToListConverter(eol: '\n').convert(rawFacts);
    _facts = factRows.skip(1).map((r) {
      const title = '💡알아두면 좋은 사실!';
      final content = '${r[1]}'.toString();
      return '$title\n $content';
    }).toList();

    // 2) 밸런스 게임 CSV (A 또는 B)
    final rawBal =
        await rootBundle.loadString('assets/modals/balance_game.csv');
    final balRows = const CsvToListConverter(eol: '\n').convert(rawBal);
    _balancePrompts = balRows.skip(1).map((r) {
      const title = '💡밸런스 게임!!';
      final content = '${r[1]} VS ${r[2]}';
      return '$title\n $content';
    }).toList();

    setState(() {}); // 불러온 뒤 UI 갱신
  }

  /// ─────────────────────────────────────────────
  /// 랜덤으로 문구 하나 선택
  String get _randomPrompt {
    final rnd = Random();
    if (_facts.isNotEmpty && _balancePrompts.isNotEmpty) {
      return rnd.nextBool()
          ? _facts[rnd.nextInt(_facts.length)]
          : _balancePrompts[rnd.nextInt(_balancePrompts.length)];
    }
    if (_facts.isNotEmpty) return _facts[rnd.nextInt(_facts.length)];
    if (_balancePrompts.isNotEmpty) {
      return _balancePrompts[rnd.nextInt(_balancePrompts.length)];
    }
    return '';
  }

  /// ─────────────────────────────────────────────
  /// “완료” 버튼 눌렀을 때(1) : 모달 띄우고 10초 슬립 후 DetailPage로 이동
  /// “완료” 버튼 눌렀을 때(2) : 새 작성인지 수정인지 분기
  Future<void> _onSubmit() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');

    final prompt = _randomPrompt;
    // ++ 06/11 백그라운드 태스크로 “생성” 작업을 위임합니다.
    Workmanager().registerOneOffTask(
      'creationTask', // unique name
      'doCreation', // callback 이름 (callbackDispatcher 에서 같은 이름)
      existingWorkPolicy: ExistingWorkPolicy.replace, // ▶ 덮어쓰기
      initialDelay: Duration.zero,
      inputData: {
        // 필요시 서버 파라미터나 스타일 정보 등 전달
        'style': _selectedStyle,
        'content': _contentCtrl.text.trim(),
      },
    );

    // 1) 모달 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoadingModal(prompt: prompt),
    );
    // 2) 10초 기다림 (프로토타입)
    await Future.delayed(const Duration(seconds: 10));
    // 3) 모달 닫기
    Navigator.of(context).pop();

    final now = DateTime.now();
    int rewardGiven = 0;

    if (_isEditMode) {
      // ── 수정 모드 로직 ──
      final idx = widget.editIdx!;
      postContents[idx] = _contentCtrl.text.trim();
      postStyles[idx] = _selectedStyle;
      postImages[idx] = _image ?? XFile('');
      // 필요하다면 postDateTimes[idx] = now;
      final todayKey = now.toIso8601String().split('T')[0];
      await prefs.setString('lastEditDate', todayKey);
    } else {
      // ── 신규 모드 로직 ──
      postImages.add(_image ?? XFile(''));
      postContents.add(_contentCtrl.text.trim());
      postDateTimes.add(now);
      postStyles.add(_selectedStyle);

      // 신규 작성이기 때문에 하루 1회 30크레딧 지급
      final todayKey = now.toIso8601String().split('T')[0];
      final lastGiven = prefs.getString('lastDiaryCreditDate') ?? '';
      if (lastGiven != todayKey) {
        // 1) 로컬 SharedPreferences 크레딧 업데이트
        final prevCredit = prefs.getInt('userCredit') ?? 0;
        await prefs.setInt('userCredit', prevCredit + 30);
        await prefs.setString('lastDiaryCreditDate', todayKey);
        rewardGiven = 30;

        // 2) 서버에도 크레딧 +30 반영
        if (userId != null && rewardGiven > 0) {
          final url = Uri.parse('$_baseUrl/api/users/$userId/credit');
          try {
            final response = await http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
                // 인증 토큰이 필요하면 여기에 추가:
                // 'Authorization': 'Bearer ${prefs.getString('accessToken')}',
              },
              body: jsonEncode({'amount': rewardGiven}),
            );

            if (response.statusCode == 200) {
              final body = jsonDecode(response.body);
              final updatedCredit = body['credit'] as int;
              print('서버에서 갱신된 크레딧: $updatedCredit');
              // 서버에서 받아온 최종 credit으로 로컬에도 덮어써 두면 동기화가 됩니다.
              await prefs.setInt('userCredit', updatedCredit);
            } else {
              print(
                  '크레딧 갱신 실패 (HTTP ${response.statusCode}): ${response.body}');
            }
          } catch (e) {
            print('크레딧 갱신 중 오류: $e');
          }
        }
      }
    }

    // ── 완료 후 DetailPage로 이동 ──
    final gotoIdx = _isEditMode ? widget.editIdx! : postContents.length - 1;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const DetailPage(),
        settings: RouteSettings(
          arguments: {
            'idx': gotoIdx,
            'reward': rewardGiven, // 하루 1회 30 크레딧
            'source': 'home',
          },
        ),
      ),
    );
  }

  /// 뒤로가기(팝) 시 호출될 콜백
  Future<bool> _onWillPop() async {
    if (_isEditMode) {
      // 수정 모드라면, 다이얼로그 띄우기
      final shouldCancel = await WriteAlertDialogs.showCancelEditDialog(
        context,
        widget.editIdx!,
      );
      return shouldCancel; // true면 Pop 허용, false면 Pop 차단
    }
    // 신규 작성 모드라면 그냥 Pop
    return true;
  }

  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(now);

    // WillPopScope로 감싸서, 뒤로가기(onWillPop) 콜백을 가로챕니다.
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        /// ─────────────────────────────────────────────
        resizeToAvoidBottomInset: false, // 키보드가 올라올때 바디 못밀게 막기
        appBar: AppBar(
          leadingWidth: 120,
          // 아이콘 두 개 공간 확보
          leading: Row(
            children: [
              // 보유 아이템 개수 (서버 동기화된 _correctionTapeCount, _diaryCount)
              const SizedBox(width: 12), // 좌측 여백
              ItemCountIcon(
                imagePath: 'assets/items/correction tape.png',
                count: _correctionTapeCount,
              ),
              const SizedBox(width: 8),
              ItemCountIcon(
                imagePath: 'assets/items/diary.png',
                count: _diaryCount,
              ),
            ],
          ),
          title: const Text('새 일기 쓰기'),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          automaticallyImplyLeading: !_hasWrittenToday,
        ),

        /// ─────────────────────────────────────────────
        body: DoubleBackToExit(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 날짜 표시
                  Center(
                    child: Text(
                      dateString,
                      style: const TextStyle(
                        fontFamily: '온글잎 혜련',
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  /// ─────────────────────────────────────────────
                  // 질문 텍스트 버튼
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/stamps/stamp_happy.gif',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 0),
                          TextButton(
                            onPressed: (_hasWrittenToday || _isLoadingQuestion)
                                ? null
                                : _loadQuestion,
                            child: const Text(
                              '질문으로 일기 시작하기',
                              style: TextStyle(
                                fontFamily: '온글잎 혜련',
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (_isLoadingQuestion) ...[
                            const SizedBox(width: 0),
                            SizedBox(
                              width: 20, // dotWidth*3 + spacing*2 정도 크기
                              height: 12, // dotHeight 정도 높이
                              child: AnimatedSmoothIndicator(
                                activeIndex: _loadingDotIndex,
                                count: 3,
                                effect: JumpingDotEffect(
                                  dotWidth: 5,
                                  dotHeight: 5,
                                  spacing: 3,
                                  jumpScale: 0.6,
                                  verticalOffset: 5.0,
                                  dotColor: Colors.grey.shade400,
                                  activeDotColor: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 0),
                      if (!_isLoadingQuestion && _questionText != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: ChatBubble(
                            text: _questionText!,
                            isSender: false,
                          ),
                        ),
                      ],
                    ],
                  ),

                  /// ─────────────────────────────────────────────
                  // 텍스트 입력박스 + 잠금해제 버튼
                  Container(
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: Colors.white,
                      border:
                          Border.all(color: const Color(0xFFD3D3D3), width: 1),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        TextField(
                          enabled: !_hasWrittenToday,
                          controller: _contentCtrl,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontFamily: 'assets/fonts/온글잎 혜련.ttf',
                          ),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: _hasWrittenToday
                                ? '오늘은 이미 작성하셨습니다.'
                                : '오늘의 이야기를 적어보세요.',
                            hintStyle: const TextStyle(color: Colors.black38),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD3D3D3)),
                            ),
                            fillColor: _hasWrittenToday
                                ? Colors.grey.shade200
                                : Colors.transparent,
                            filled: true,
                            counterText: '',
                            contentPadding: const EdgeInsets.all(12),

                            /// ─────────────────────────────────────────────
                            // 포커스가 없을 때 테두리
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: const BorderSide(
                                color: Colors.white,
                                width: 1,
                              ),
                            ),

                             /// ─────────────────────────────────────────────
                            // 포커스 받았을 때 테두리
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: const BorderSide(
                                color: Color(0xFFD3D3D3),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        // 잠금된 상태일 때만 보여주는 ‘+잠금해제’ 버튼
                        if (_hasWrittenToday)
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.lock_open),
                              label: const Text('+ 잠금해제'),
                              onPressed: () {
                                UnlockDialogs.showUnlockDiaryDialog(
                                  context: context,
                                  currentDiaryCount: _diaryCount,
                                  onUnlocked: () {
                                    setState(() {
                                      _hasWrittenToday = false;
                                      _diaryCount--; // ✅ 바로 차감
                                    });
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                backgroundColor: const Color(0xFFD6C7A6),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  /// ─────────────────────────────────────────────
                  const SizedBox(height: 16),
                  // 글자 수 표시 (오른쪽 아래)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_contentCtrl.text.length}/500',
                      style: TextStyle(
                        fontSize: 12,
                        color: _contentCtrl.text.length >= 500
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                  ),

                  /// ─────────────────────────────────────────────
                  // 스타일 라디오 + 정보 아이콘
                  Row(
                    children: [
                      const Text(
                        '어떤 스타일로 그림을 그려드릴까요?',
                        style: TextStyle(
                          fontFamily: '온글잎 혜련',
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const StyleInfoDialog(),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 10),
                      _buildRadio('캐릭터', _selectedStyle, (v) {
                        setState(() => _selectedStyle = v!);
                      }),
                      const SizedBox(width: 10),
                      _buildRadio('일러스트', _selectedStyle, (v) {
                        setState(() => _selectedStyle = v!);
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// ─────────────────────────────────────────────
                  // 완료 버튼 (오른쪽 정렬)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _hasWrittenToday
                            ? null
                            : () async {
                                final content = _contentCtrl.text.trim();
                                if (content.isEmpty || content.length < 100) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('일기를 최소 100자 이상 입력해주세요.'),
                                    ),
                                  );
                                  return;
                                }
                                final ok =
                                    await showCreateConfirmDialog(context);
                                if (!ok) {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('오류'),
                                      content: const Text('잠시 후 다시 시도해주세요.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('확인'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }
                                await _onSubmit();
                              },
                        child: const Text(
                          '완료',
                          style: TextStyle(
                            fontFamily: '온글잎 혜련',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// ─────────────────────────────────────────────
                  const SizedBox(height: 10),
                  const Text(
                    '일기 생성은 2-3분 정도 소요될 수 있어요:D',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
// 라디오 버튼
Widget _buildRadio(
    String label, String groupValue, ValueChanged<String?> onChanged) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Radio<String>(
        value: label,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: Colors.black87,
      ),
      Text(
        label,
        style: const TextStyle(
          fontFamily: '온글잎 혜련',
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    ],
  );
}
