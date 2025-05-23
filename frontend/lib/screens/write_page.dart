import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter, MaxLengthEnforcement, rootBundle; // for LengthLimitingTextInputFormatter
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:dx_project_dev2/utils/create_confirm.dart';
import 'package:dx_project_dev2/theme/app_theme.dart';
import 'package:dx_project_dev2/widgets/loading_modal.dart';

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

class _WritePageState extends State<WritePage> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  String _selectedStyle = '수채화';

  // CSV에서 읽어온 문구
  List<String> _facts = [];
  List<String> _balancePrompts = [];

  @override
  void initState() {
    super.initState();
    _contentCtrl.addListener(() => setState(() {}));
    _loadPrompts();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _image = img);
  }

  void _showAttachmentsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('이미지 첨부'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(now);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('새 일기 쓰기'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _showAttachmentsMenu,
          ),
        ],
      ),
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

            // 텍스트 입력박스
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: Colors.white,
                  border: Border.all(color: Color(0xFFD3D3D3), width: 1),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TextField(
                      controller: _contentCtrl,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontFamily: 'assets/fonts/온글잎 혜련.ttf',
                      ),
                      maxLines: null,
                      expands: true,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: '오늘의 이야기를 적어보세요',
                        hintStyle: TextStyle(fontFamily: '온글잎 혜련', fontSize:15, color: Colors.black38,),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

            // 스타일 라디오
            const Text(
              '스타일',
              style: TextStyle(
                fontFamily: '온글잎 혜련',
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRadio('수채화', _selectedStyle, (v) {
                  setState(() => _selectedStyle = v!);
                }),
                const SizedBox(width: 24),
                _buildRadio('동화', _selectedStyle, (v) {
                  setState(() => _selectedStyle = v!);
                }),
                const SizedBox(width: 24),
                _buildRadio('웹툰', _selectedStyle, (v) {
                  setState(() => _selectedStyle = v!);
                }),
              ],
            ),
            const SizedBox(height: 24),

            // 완료 버튼 (오른쪽 정렬)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  // 완료 버튼 동작 구현
                  onPressed: () async {
                    // 1) 내용 가져와서 앞뒤 공백 제거
                    final content = _contentCtrl.text.trim();
                    // 2) 비어있거나 30자 미만이면 경고
                    if (content.isEmpty || content.length < 30) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('일기를 최소 30자 이상 입력해주세요.'),
                        ),
                      );
                      return; // 밑의 _onSubmit 호출 안 함
                    }
                    // 1) 오토툰 생성 확인
                    final ok = await showCreateConfirmDialog(context);
                    if (!ok) return;
                    // 2) 확인 받았으면 원래 로딩/이동 로직 실행
                    _onSubmit();
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

            // 안내 텍스트
            const SizedBox(height: 10),
            const Text(
              '일기 생성은 2-3분 정도 소요될 수 있습니다.',
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
