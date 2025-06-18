import 'dart:async';
import 'dart:math';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:convert';
import 'package:eventsource/eventsource.dart';

import '../widgets/member_info_components.dart';
import 'detail_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:dx_project_dev2/widgets/alert_dialogs.dart';
import 'package:dx_project_dev2/widgets/modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dx_project_dev2/services/api_service.dart';
import 'package:intl/intl.dart';
import '../widgets/double_back_to_exit.dart';
import '../widgets/chat_bubble.dart';
import 'package:dx_project_dev2/models/diary_model.dart';
import 'package:dx_project_dev2/main.dart' show navigatorKey;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 전역 리스트 선언 (이미지, 텍스트, 작성시간, 이미지스타일)
final List<XFile> postImages = [];
final List<String> postTitles = [];
final List<String> postContents = [];
final List<DateTime> postDateTimes = [];
final List<String> postStyles = [];

/// 좋아요 누른 게시글 인덱스 모아두기
final Set<int> likedPosts = {};

class WritePage extends StatefulWidget {
  /// 유저 ID
  final int userId;

  /// editIdx: null 이면 신규 작성, 정수값(idx)이 넘어오면 수정 모드
  final int? editIdx;

  const WritePage({Key? key, required this.userId, this.editIdx})
      : super(key: key);

  @override
  State<WritePage> createState() => _WritePageState();
}

/// ─────────────────────────────────────────────
class _WritePageState extends State<WritePage> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _contentCtrl = TextEditingController();
  String _selectedStyle = '캐릭터';
  String _currentTmi = ''; // 모달 안에 표시할 현재 TMI
  bool _isEditMode = false; // 수정 모드 여부
  Diary? _editDiary;

  String? _questionText; // 질문 텍스트 상태  //🌸
  bool _isLoadingQuestion = false; // 질문 로딩 중 여부 🌸
  bool _isLoading = false;
  bool _hasWrittenToday = false;

  /// 로딩 애니메이션용 인덱스 (0, 1, 2 순환)
  int _loadingDotIndex = 0;
  int _loadingDotDirection = 1; // 방향 변수
  Timer? _loadingDotTimer;

  final List<String> _tmiList = [];
  // EventSource (SSE)
  EventSource? _eventSource;
  StreamSubscription<Event>? _eventSub;
  // late final Diary _createdDiary;          // ← null 허용 X, 초기화 안 되면 크래시
  Diary? _createdDiary; // ← null 허용
  int? _createdDiaryId; // ← diary_num만 먼저 저장해 둘 때 사용

  /// “질문으로 일기 시작하기” 버튼 클릭 시 로딩 + 질문 표시
  void _startQuestionAnimation() {
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
        // _questionText = "오늘 가장 기뻤던 순간은?"; // 실제 API 호출 로직으로 교체 가능
      });
    });
  }

  /// ─────────────────────────────────────────────
  // CSV에서 읽어온 문구
  List<String> _facts = [];
  List<String> _balancePrompts = [];

  /// ─────────────────────────────────────────────
  // MemberInfoPage에서 저장된 아이템 개수를 SharedPreferences에서 불러올 변수
  int _correctionTapeCount = 0;
  int _diaryCount = 0;

  late final String _baseUrl;

  @override
  void initState() {
    super.initState();
    
    _isEditMode = widget.editIdx != null;

    _baseUrl = dotenv.env['API_BASE_URL'] ?? "http://211.188.62.213:8000";

    // if (_isEditMode) {
    //   final idx = widget.editIdx!;
    //   _contentCtrl.text = postContents[idx]; // 전역 리스트에서
    //   _selectedStyle = postStyles[idx];
    //   // _fetchDiaryAndSetup(widget.editIdx!);
    // }

    if (_isEditMode) {
      // 비동기 fetch는 addPostFrameCallback으로 안전하게 호출!
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchDiaryAndSetup(widget.editIdx!);
      });
    } else {
      // 신규 작성 모드 - 상태를 모두 초기화
      _contentCtrl.text = '';
      _selectedStyle = '캐릭터';  // 또는 기본값
      _image = null;
      _editDiary = null;
      // 필요하면 여기서 _checkWrittenToday()도 호출
    }

    // 오늘 이미 일기를 썼는지 체크하는 함수 호출
    _checkWrittenToday();
    _loadCountsFromPrefs();

    // 글자 수 실시간 업데이트를 위해 컨트롤러 리스너 추가
    _contentCtrl.addListener(() {
      setState(() {});
    });
  }
  

  /// SharedPreferences에서 MemberInfoPage가 저장해 둔 아이템 개수 불러오는 메서드
  Future<void> _loadCountsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _correctionTapeCount = prefs.getInt('correctionTapeCount') ?? 0;
      _diaryCount = prefs.getInt('diaryCount') ?? 0;
    });
  }

  /// ─────────────────────────────────────────────
  @override
  void dispose() {
    _contentCtrl.dispose();
    // 로딩 타이머와 PageController 정리
    _loadingDotTimer?.cancel();
    // SSE 연결 해제
    _eventSub?.cancel();
    super.dispose();
  }

  /// 1) 질문 로드
  Future<void> _fetchRandomQuestion() async {
    // setState(() {
    //   _isLoadingQuestion = true;
    //   _questionText = null;
    //   _loadingDotIndex = 0;
    // });
    // _loadingDotTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
    //   setState(() {
    //     if (_loadingDotIndex == 2)
    //       _loadingDotDirection = -1;
    //     else if (_loadingDotIndex == 0) _loadingDotDirection = 1;
    //     _loadingDotIndex += _loadingDotDirection;
    //   });
    // });
    try {
      final q =
          await ApiService.getCustomizedQuestion(userId: widget.userId.toString());
      _loadingDotTimer?.cancel();
      setState(() {
        _isLoadingQuestion = false;
        _questionText = q;
      });
    } catch (e) {
      _loadingDotTimer?.cancel();
      setState(() => _isLoadingQuestion = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('질문 로드 실패'),
          content: Text(e.toString()),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'))
          ],
        ),
      );
    }
  }

  Future<void> _fetchDiaryAndSetup(int diaryNum) async {
    try {
      final diary = await ApiService.readDiary(diaryNum);
      setState(() {
        _editDiary = diary;
        _contentCtrl.text = diary.content;
        _selectedStyle = diary.styleId == 4 ? '캐릭터' : '일러스트';
        // 만약 이미지나 기타 데이터도 있다면 여기에 세팅
        // _image = diary.mergedPath != null ? XFile(diary.mergedPath!) : null;
      });

      final imgCount = diary.imgCount ?? 0;
      if (imgCount >= 2) {
        if (_correctionTapeCount <= 0) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('수정 제한'),
              content: const Text('수정테이프 아이템이 부족해 수정이 불가합니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
          Navigator.of(context).pop(); // WritePage 나가기
          return;
        }

        // 사용자 동의받고 차감
        final use = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('수정 아이템 사용'),
            content: const Text('이미지 재생성이 3회 이상이므로\n수정테이프를 1개 사용해야 합니다.\n계속하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('사용'),
              ),
            ],
          ),
        );

        if (use != true) {
          Navigator.of(context).pop();
          return;
        }

        // 실제 차감
        final ok = await _useCorrectionTape();
        if (!ok) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('차감 실패'),
              content: const Text('수정테이프 차감에 실패했습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
          Navigator.of(context).pop();
          return;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기를 불러오지 못했습니다.')),
      );
      Navigator.of(context).pop();
    }
  }

  // 오늘 일기 썼는지 체크
  Future<void> _checkWrittenToday() async {
    if (_isEditMode) {
      // 수정 모드일 때는 잠금 풀기!
      setState(() {
        _hasWrittenToday = false;
      });
      return;
    }
    // 유저 ID 가져오기
    final userId = widget.userId;
    // 오늘 날짜 구하기
    final today = DateTime.now();
    // 백엔드에서 오늘 쓴 일기 fetch
    final diaries = await ApiService.fetchDiariesForDate(userId, today);
    setState(() {
      _hasWrittenToday = diaries.isNotEmpty;
    });
  }

  // 일기장 아이템 사용
  Future<bool> _useDiaryItem() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (_diaryCount <= 0 || userId == null || userId.isEmpty) return false;

    setState(() {
      _diaryCount -= 1;
    });
    await prefs.setInt('diaryCount', _diaryCount);

    // 서버 동기화
    final uri = Uri.parse("$_baseUrl/api/users/$userId");
    final res = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'diary_item': _diaryCount}),
    );
    return res.statusCode == 200;
  }

// 수정테이프 아이템 사용
  Future<bool> _useCorrectionTape() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (_correctionTapeCount <= 0 || userId == null || userId.isEmpty)
      return false;

    setState(() {
      _correctionTapeCount -= 1;
    });
    await prefs.setInt('correctionTapeCount', _correctionTapeCount);

    // 서버 동기화
    final uri = Uri.parse("$_baseUrl/api/users/$userId");
    final res = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correction_tape_item': _correctionTapeCount}),
    );
    return res.statusCode == 200;
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
      if (rnd.nextBool()) {
        return _facts[rnd.nextInt(_facts.length)];
      } else {
        return _balancePrompts[rnd.nextInt(_balancePrompts.length)];
      }
    }
    if (_facts.isNotEmpty) return _facts[rnd.nextInt(_facts.length)];
    if (_balancePrompts.isNotEmpty) {
      return _balancePrompts[rnd.nextInt(_balancePrompts.length)];
    }
    return '';
  }

  /// 백엔드 /diaries/stream 에 POST → TMI+이미지 스트림 수신
  Future<void> _startDiaryStream() async {
    // late void Function(VoidCallback) setStateModal;

    String dialogField = '';
    String dialogContent = '';
    late StateSetter dialogSetState;

    // 1) 로딩 모달 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) {
          dialogSetState = setState;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('💡알쓸신잡!'),
                    const SizedBox(width: 8),
                    Text(dialogField,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(dialogContent, textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );

    try {
      final diaryDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      // (2) 스트림 전용 엔드포인트 호출 (생성/수정 공용)
      final streamClient = _isEditMode
          ? await ApiService.updateDiaryWithStream(
              diaryNum: widget.editIdx!,
              styleId: _selectedStyle == '캐릭터' ? 4 : 2,
              diaryDate: diaryDate,
              content: _contentCtrl.text.trim(),
            )
          : await ApiService.createDiaryWithStream(
              userId: widget.userId.toString(),
              styleId: _selectedStyle == '캐릭터' ? 4 : 2,
              diaryDate: diaryDate,
              content: _contentCtrl.text.trim(),
            );
      // 3) 스트림 구독
      _eventSub = streamClient.listen((evt) async {
        final name = evt.event ?? '';
        final data = evt.data ?? '';

        print('[SSE 이벤트 수신] name: $name, data: $data');

        if (name == 'diary_created') {
          // // 최초 이벤트: Diary 객체 전체
          // try {
          //   _createdDiary = Diary.fromJson(jsonDecode(data));
          //   _createdDiaryId = _createdDiary!.diaryNum;
          // } catch (_) {
          //   // 혹시 JSON 파싱에 실패해도 최소한 diary_num 은 챙겨 둔다
          //   _createdDiaryId = (jsonDecode(data) as Map)['diary_num'] as int?;
          // }
          // return;                         // ← 여기서 끝
          final map = jsonDecode(data) as Map<String, dynamic>;
          _createdDiary = Diary.fromJson(jsonDecode(data));
          // 여기서 diaryNum 필드를 ID 변수에도 저장
          _createdDiaryId = map['diary_num'] ?? map['diaryNum'];
          print('[diary_created] diary_num: $_createdDiaryId');
          return;
        }
        if (name.isEmpty) {
          dialogSetState(() {
            // dialogField   = '';    // 필요 없으면 빈 문자열로
            dialogContent = data; // 데이터 그대로 표시
          });
          return;
        }
        if (name == 'image_done') {
          print('[image_done] 호출됨! DetailPage로 이동 시도');
          // 반드시 rootNavigator: true로 pop
          Navigator.of(context, rootNavigator: true).pop();

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            // context: navigatorKey.currentContext를 사용 (안전)
            final navContext = navigatorKey.currentContext ?? context;
            if (_createdDiary != null) {
              Navigator.of(navContext).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => DetailPage(
                          diary: _createdDiary!,
                          source: 'home',
                          reward: 0,
                        )),
              );
            } else if (_createdDiaryId != null) {
              try {
                final fallback = await ApiService.readDiary(_createdDiaryId!);
                Navigator.of(navContext).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => DetailPage(
                            diary: fallback,
                            source: 'home',
                            reward: 0,
                          )),
                );
              } catch (_) {
                ScaffoldMessenger.of(navContext).showSnackBar(
                  const SnackBar(content: Text('일기 정보를 불러올 수 없습니다.')),
                );
              }
            } else {
              ScaffoldMessenger.of(navContext).showSnackBar(
                const SnackBar(content: Text('일기 정보를 불러올 수 없습니다.')),
              );
            }
          });

          await _eventSub?.cancel();
          return;
        }
      }); // ───── listen 콜백 닫기
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('요청 실패'),
          content: Text(e.toString()),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인')),
          ],
        ),
      );
    }
  }

  /// ─────────────────────────────────────────────
  /// “완료” 버튼 눌렀을 때(1) : 모달 띄우고 10초 슬립 후 DetailPage로 이동
  ///  “완료” 버튼 눌렀을 때(2) : 새 작성인지 수정인지 분기
  Future<void> _onSubmit() async {
    late final Diary createdDiary;
    final prompt = _randomPrompt;

    // 1) 로딩 모달 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: LoadingModal(prompt: prompt)),
    );

    try {
      setState(() => _isLoading = true);
      // 2) 실제 POST 요청 (30초 이상 걸리면 에러)
      createdDiary = await ApiService.createDiary(
        userId: widget.userId.toString(),
        styleId: _selectedStyle == '캐릭터' ? 4 : 2,
        diaryDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        content: _contentCtrl.text.trim(),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('요청 시간이 60초를 초과했습니다.'),
      );

      // 3) 모달 닫고 상세 페이지로 이동
      Navigator.of(context).pop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DetailPage(
            diary: createdDiary,
            source: 'home',
            reward: 0,
          ),
        ),
      );
    } catch (e) {
      // 에러 시 모달 닫고 다이얼로그
      Navigator.of(context).pop();
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('오류'),
          content: Text('일기 작성에 실패했습니다.\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }

    // final now = DateTime.now();
    // int rewardGiven = 0;

    // 수정인지 신규인지에 따라 rewardGiven, gotoIdx 계산
    final now = DateTime.now();
    int rewardGiven = 0;
    int gotoIdx;

    if (_isEditMode) {
      // 1) 수정 모드 : 기존 리스트에 덮어쓰기
      final idx = widget.editIdx!;
      postContents[idx] = _contentCtrl.text.trim();
      postStyles[idx] = _selectedStyle;
      postImages[idx] = _image ?? XFile('');
      // 작성 시간은 그대로 두거나, 원한다면 다음 줄처럼 변경할 수도 있음
      // postDateTimes[idx] = now;

      // 수정 시 보상 없음
      gotoIdx = idx;

      // “수정 완료” 시점에 SharedPreferences에 lastEditDate 기록
      final prefs = await SharedPreferences.getInstance();
      final todayKey = now.toIso8601String().split('T').first;
      await prefs.setString('lastEditDate', todayKey);
    } else {
      // 신규 모드: 기존 로직대로 append
      postImages.add(_image ?? XFile(''));
      postContents.add(_contentCtrl.text.trim());
      postDateTimes.add(now);
      postStyles.add(_selectedStyle);
      gotoIdx = postContents.length - 1;

      // 신규 작성이기 때문에 하루 1회 30크레딧 지급
      final prefs = await SharedPreferences.getInstance();
      final todayKey = now.toIso8601String().split('T').first;
      final lastGiven = prefs.getString('lastDiaryCreditDate') ?? '';
      if (lastGiven != todayKey) {
        final prevCredit = prefs.getInt('userCredit') ?? 0;
        await prefs.setInt('userCredit', prevCredit + 30);
        await prefs.setString('lastDiaryCreditDate', todayKey);
        rewardGiven = 30;
      }
    }

    // 완료 후 상세 페이지로 이동 (수정 모드면 같은 idx, 신규면 새 idx)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          diary: createdDiary, // ← 필수
          source: 'home', // ← 선택
          reward: rewardGiven,
        ),
        settings: RouteSettings(
          arguments: {
            'idx': gotoIdx,
            'reward': rewardGiven, // 하루 1회 30 크레딧
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
      // onWillPop: () async => true,
      onWillPop: _onWillPop,
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leadingWidth: _isEditMode ? null : 120,  // 수정모드면 기본(56), 작성모드만 넓게!s
        leading: _isEditMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : Row(
                children: [
                  const SizedBox(width: 12),
                  ItemCountIcon(
                      imagePath: 'assets/items/correction tape.png',
                      count: _correctionTapeCount),
                  const SizedBox(width: 8),
                  ItemCountIcon(
                      imagePath: 'assets/items/diary.png', count: _diaryCount),
                ],
              ),
        title: Text(_isEditMode ? '일기 수정하기' : '새 일기 쓰기'),
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
                            'assets/stamps/stamp_happy2.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 0),

                          TextButton(
                            onPressed: (_hasWrittenToday || _isLoadingQuestion)
                                ? null
                                : () {
                                    _startQuestionAnimation();
                                    _fetchRandomQuestion();
                                  },
                            child: const Text(
                              '질문으로 일기 시작하기',
                              style: TextStyle(
                                fontFamily: '온글잎 혜련',
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          // 로딩 중일 때만 점프 애니메이션 노출
                          if (_isLoadingQuestion) ...[
                            const SizedBox(width: 0),

                            // AnimatedSmoothIndicator 사용
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

                      // 로딩 끝난 뒤 질문 표시
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

                  // ─────────────────────────────────────────────
                  // // 스트리밍으로 들어온 TMI를 화면에 순차 출력
                  // if (_tmiList.isNotEmpty) ...[
                  //   const SizedBox(height: 16),
                  //   for (var msg in _tmiList)
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(vertical: 4),
                  //       child: ChatBubble(
                  //         text: msg,
                  //         isSender: false,
                  //       ),
                  //     ),
                  // ],

                  /// ─────────────────────────────────────────────
                  // 텍스트 입력박스 + + 잠금해제 버튼
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
                          onChanged: (_) => setState(() {}), // 실시간 글쓰기 카운트 출력부
                          enabled: !_hasWrittenToday || _isEditMode,
                          controller: _contentCtrl,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontFamily: '온글잎 혜련',
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
                                color: Colors.white, //<— 비활성 상태 테두리 색
                                width: 1,
                              ),
                            ),

                            /// ─────────────────────────────────────────────
                            // 포커스 받았을 때 테두리
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: const BorderSide(
                                color: Color(0xFFD3D3D3), //<— 포커스 상태 테두리 색
                                width: 2,
                              ),
                            ),

                            /// ─────────────────────────────────────────────
                          ),
                        ),

                        // 잠금된 상태일 때만 보여주는 ‘+잠금해제’ 버튼
                        if (_hasWrittenToday && !_isEditMode)
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.lock_open),
                              label: const Text('+ 잠금해제'),
                              onPressed: () async {
                                final ok = await _useDiaryItem();
                                if (ok) {
                                  setState(() {
                                    _hasWrittenToday = false;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('일기장 아이템이 부족합니다!')),
                                  );
                                }
                                // 분리된 다이얼로그 메서드 호출
                                // UnlockDialogs.showUnlockDiaryDialog(
                                //   context: context,
                                //   currentDiaryCount: _diaryCount,
                                //   onUnlocked: () {
                                //     // 잠금 해제되면 _hasWrittenToday = false 처리
                                //     setState(() {
                                //       _hasWrittenToday = false;
                                //     });
                                //   },
                                // );
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
                      // _buildRadio('애니', _selectedStyle, (v) {
                      //   setState(() => _selectedStyle = v!);
                      // }),
                      const SizedBox(width: 10),
                      _buildRadio('캐릭터', _selectedStyle, (v) {
                        setState(() => _selectedStyle = v!);
                      }),
                      // const SizedBox(width: 5),
                      // _buildRadio('수채화', _selectedStyle, (v) {
                      //   setState(() => _selectedStyle = v!);
                      // }),
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
                        // 완료 버튼 동작 구현
                        onPressed: _hasWrittenToday
                            ? null
                            : () async {
                                // 1) 내용 가져와서 앞뒤 공백 제거
                                final content = _contentCtrl.text.trim();
                                // 2) 비어있거나 100자 미만이면 경고
                                if (content.isEmpty || content.length < 100) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('일기를 최소 100자 이상 입력해주세요.'),
                                    ),
                                  );
                                  return; // 밑의 _onSubmit 호출 안 함
                                }
                                // 1) 오토툰 생성 확인
                                final ok =
                                    await showCreateConfirmDialog(context);
                                if (!ok) {
                                  // 확인을 못받았을 때: 오류 다이얼로그 띄우기
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
                                  return; // _onSubmit 호출하지 않고 함수 종료
                                }

                                // **여기서 수정모드+imgCount>=3이면 차감!**
                                print('editDiary: $_editDiary, imgCount: ${_editDiary?.imgCount}');
                                if (_isEditMode && (_editDiary?.imgCount ?? 0) >= 3) {
                                  final tapeOk = await _useCorrectionTape();
                                  if (!tapeOk) {
                                    await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('수정테이프 부족'),
                                        content: const Text('수정테이프 아이템이 부족해 수정이 불가합니다.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('확인'),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                                }

                                // 2) 확인 받았으면 원래 로딩/이동 로직 실행
                                await _startDiaryStream();
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
                  // 안내 텍스트
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
