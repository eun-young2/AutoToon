import 'dart:math';
import 'detail_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:dx_project_dev2/widgets/alert_dialogs.dart';
import 'package:dx_project_dev2/widgets/modal.dart';
import 'package:intl/intl.dart';

/// 전역 리스트 선언 (이미지, 텍스트, 작성시간)
final List<XFile> postImages = [];
final List<String> postTitles = [];
final List<String> postContents = [];
final List<DateTime> postDateTimes = [];

/// 좋아요 누른 게시글 인덱스 모아두기
final Set<int> likedPosts = {};

class WritePage extends StatefulWidget {
  const WritePage({Key? key}) : super(key: key);

  @override
  State<WritePage> createState() => _WritePageState();
}

/// ─────────────────────────────────────────────
// 말풍선 디자인
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isSender;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isSender,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CustomPaint(
        painter: BubblePainter(),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          constraints: const BoxConstraints(maxWidth: 250),
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
class BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow[200]!
      ..style = PaintingStyle.fill;

    const radius = 12.0;
    final path = Path();

    // 왼쪽 아래 꼬리 포함 말풍선
    path.moveTo(radius + 10, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius + 20, size.height);
    path.lineTo(25, size.height + 12); // 꼬리 시작점 크게
    path.lineTo(20, size.height);      // 꼬리 끝점
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius + 10, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
/// ─────────────────────────────────────────────
class _WritePageState extends State<WritePage> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _contentCtrl = TextEditingController();
  String _selectedStyle = '수채화';

  String? _questionText; //질문 텍스트 상태  //🌸

  // 예시로 질문 불러오기 함수 (나중에 DB 연동 시 API 호출로 대체 가능)🌸
  void _loadQuestion() {
    setState(() {
      _questionText = "오늘 가장 기뻤던 순간은?"; // 예시 질문
    });
  }
  /// ─────────────────────────────────────────────
  // CSV에서 읽어온 문구
  List<String> _facts = [];
  List<String> _balancePrompts = [];

  /// ─────────────────────────────────────────────
  // 글쓰기 하나로 제한하기
  bool _hasWrittenToday = false;
  @override
  void initState() {
    super.initState();
    //  글자 수 실시간 업데이트를 위해 컨트롤러 리스너 추가
    _contentCtrl.addListener(() {
      setState(() {
      });
    });
    /// ─────────────────────────────────────────────
    // 오늘 게시글 작성했는지 여부 체크하는 로직
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.now();
      final wrote = postDateTimes.any((d) =>
      d.year == today.year &&
          d.month == today.month &&
          d.day == today.day
      );
      setState(() => _hasWrittenToday = wrote);
    });
    // CSV 프롬프트 읽기
    _loadPrompts();
  }
  /// ─────────────────────────────────────────────
  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }
  /// ─────────────────────────────────────────────
  /// assets/폴더에 담긴 CSV 파일을 읽어서 리스트로 변환
  Future<void> _loadPrompts() async {
    // 1) 지식 문구 CSV
    final rawFacts = await rootBundle.loadString('assets/modals/Useful_information.csv');
    final factRows = const CsvToListConverter(eol: '\n').convert(rawFacts);
    _facts = factRows.skip(1)
        .map((r) {
          const title = '💡알아두면 좋은 사실!';
          final content = '${r[1]}'.toString();
          return '$title\n $content';
        })
        .toList();

    // 2) 밸런스 게임 CSV (A 또는 B)
    final rawBal = await rootBundle.loadString('assets/modals/balance_game.csv');
    final balRows = const CsvToListConverter(eol: '\n').convert(rawBal);
    _balancePrompts = balRows.skip(1)
        .map((r){
          const title = '💡밸런스 게임!!';
          final content = '${r[1]} VS ${r[2]}';
          return '$title\n $content';
        })
        .toList();

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
    if (_balancePrompts.isNotEmpty) return _balancePrompts[rnd.nextInt(_balancePrompts.length)];
    return '';
  }
  /// ─────────────────────────────────────────────
  /// “완료” 버튼 눌렀을 때: 모달 띄우고 5초 슬립 후 메인으로 이동
  Future<void> _onSubmit() async {

    final prompt = _randomPrompt;
    // 1) 모달 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoadingModal(prompt: prompt),
    );
    // 2) 5초 기다림 (프로토타입)
    await Future.delayed(const Duration(seconds: 15));
    // 3) 닫고 메인으로
    Navigator.of(context).pop();
    Navigator.pushReplacementNamed(context, '/main');
  }
  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(now);

    return Scaffold(
      /// ─────────────────────────────────────────────
      resizeToAvoidBottomInset: false,  // 키보드가 올라올때 바디 못밀게 막기
      appBar: AppBar(
        title: const Text('새 일기 쓰기'),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: !_hasWrittenToday,
      ),
      /// ─────────────────────────────────────────────
      body: Padding(
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset('assets/stamps/stamp_happy2.png',width: 30,height: 30,),
                    TextButton(
                      onPressed: _hasWrittenToday ? null : _loadQuestion,
                      child: const Text(
                        '질문으로 일기 시작하기',
                        style: TextStyle(
                          fontFamily: '온글잎 혜련',
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_questionText != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: ChatBubble(
                      text: _questionText!,
                      isSender: false,
                    ),
                  ),
                ],
              ],
            ),
            /// ─────────────────────────────────────────────
            // 텍스트 입력박스
            Expanded(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD3D3D3), width: 1),
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
                          borderSide: const BorderSide(color: Color(0xFFD3D3D3)),
                        ),
                        fillColor: _hasWrittenToday ? Colors.grey.shade200 : Colors.transparent,
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
                            color: Color(0xFFD3D3D3),       //<— 포커스 상태 테두리 색
                            width: 2,
                          ),
                        ),
                        /// ─────────────────────────────────────────────
                      ),
                    ),
                  ],
                ),
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
                    : Colors.grey),
              ),
            ),
            /// ─────────────────────────────────────────────
            // 스타일 라디오
            const Text(
              '어떤 스타일로 그림을 그려드릴까요?',
              style: TextStyle(
                fontFamily: '온글잎 혜련',
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRadio('애니', _selectedStyle, (v) {
                  setState(() => _selectedStyle = v!);
                }),
                const SizedBox(width: 10),
                _buildRadio('일러스트', _selectedStyle, (v) {
                  setState(() => _selectedStyle = v!);
                }),
                const SizedBox(width: 10),
                _buildRadio('수채화', _selectedStyle, (v) {
                  setState(() => _selectedStyle = v!);
                }),
                const SizedBox(width: 10),
                _buildRadio('웹툰', _selectedStyle, (v) {
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
                  onPressed: _hasWrittenToday ? null : () async {
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
                    final ok = await showCreateConfirmDialog(context);
                    if (!ok) return;
                    // 2) 확인 받았으면 원래 로딩/이동 로직 실행
                    _onSubmit();

                    // 저장
                    postImages.add(_image ?? XFile(''));
                    postContents.add(_contentCtrl.text.trim());
                    postDateTimes.add(DateTime.now());

                    final newIndex =postContents.length-1;

                    Navigator.push(context,MaterialPageRoute(
                      builder: (context)=> const DetailPage(),
                      settings: RouteSettings(arguments:newIndex),
                    ));
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
    );
  }
}
/// ─────────────────────────────────────────────
// 라디오 버튼
Widget _buildRadio(String label, String groupValue, ValueChanged<String?> onChanged) {
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
