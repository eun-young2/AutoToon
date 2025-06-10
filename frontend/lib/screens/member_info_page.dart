import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dx_project_dev2/widgets/modal.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/alert_dialogs.dart';
import '../widgets/member_info_components.dart';
import '../widgets/double_back_to_exit.dart';

class MemberInfoPage extends StatefulWidget {
  const MemberInfoPage({super.key});

  @override
  State<MemberInfoPage> createState() => _MemberInfoPageState();
}

/// ───────────────── INFO 하드코딩 ───────────────────────
class _MemberInfoPageState extends State<MemberInfoPage> {
  // 변하지 않는 회원 정보 (카카오톡에서 받아온 정보라고 가정)
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String _nickname = '로딩중...';
  String _name = '';
  final String _phoneNumber = '010-1234-5678'; // 필요 시 API로 연결
  String _gender = '로딩중';
  String _ageGroup = '로딩중';

  // 보유 크레딧(차감 가능)
  int _credit = 0;

  // 보유 아이템 개수
  int _correctionTapeCount = 0;
  int _diaryCount = 0;

  late final String _baseUrl;

  @override
  void initState() {
    super.initState();
    // 화면이 처음 열릴 때 SharedPreferences에서 userCredit을 불러와 _credit에 세팅
    _baseUrl = dotenv.env['API_BASE_URL'] ?? "http://211.188.62.213:8000";
    // 🔹 로컬 캐시 즉시 적용
    _applyPrefsCache();

    _loadUserInfoFromApi();
  }

  Future<void> _applyPrefsCache() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nickname = prefs.getString('userNick') ?? _nickname;
      _credit = prefs.getInt('userCredit') ?? _credit;
      _correctionTapeCount = prefs.getInt('correctionTapeCount') ?? 0;
      _diaryCount = prefs.getInt('diaryCount') ?? 0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 다른 화면에서 돌아올 때마다 SharedPreferences에서 userCredit을 다시 읽어 와서 setState
    _loadUserInfoFromApi();
  }

  /// ──────────────── 크레딧 사용시 저장 ──────────────────────
  /// SharedPreferences에서 userCredit, correctionTapeCount, diaryCount를 모두 불러와서
  /// _credit, _correctionTapeCount, _diaryCount에 세팅
  Future<void> _loadUserInfoFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    // userId가 없으면 로그인 페이지로 보내거나 기본값 유지
    if (userId == null || userId.isEmpty) {
      print("SharedPreferences에 userId가 없습니다.");
      return;
    }

    // ─── ① URI 생성: _baseUrl + "/users/$userId"
    final uri = Uri.parse("$_baseUrl/api/users/$userId");
    print('GET $uri');
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // ─── ② 응답 JSON 파싱
        final data = jsonDecode(response.body);

        setState(() {
          // 예시 JSON:
          // {
          //   "user_id": "4284707752",
          //   "user_name": "김찬휘",
          //   "user_nick": "김찬휘",
          //   "user_gender": 0,
          //   "user_age_range": "20~29",
          //   "created_at": "2025-05-31T06:03:44",
          //   "credit": 300,
          //   "correction_tape_item": 0,
          //   "diary_item": 0
          // }
          _nickname = data['user_nick'] ?? data['user_name'] ?? '닉네임 없음';
          _name = data['user_name'] ?? '';

          final int? genderInt = data['user_gender'];
          if (genderInt == 0) {
            _gender = '남성';
          } else if (genderInt == 1) {
            _gender = '여성';
          } else {
            _gender = '알 수 없음';
          }

          _ageGroup = data['user_age_range'] ?? '알 수 없음';
          _credit = data['credit'] ?? 0;
          _correctionTapeCount = data['correction_tape_item'] ?? 0;
          _diaryCount = data['diary_item'] ?? 0;
        });

        // ─── ③ SharedPreferences에도 동기화(옵션)
        await prefs.setInt('userCredit', _credit);
        await prefs.setInt('correctionTapeCount', _correctionTapeCount);
        await prefs.setInt('diaryCount', _diaryCount);
      } else {
        print("API 호출 실패: statusCode = ${response.statusCode}");
      }
    } catch (e) {
      print("API 호출 중 에러: $e");
    }
  }

  /// ─────────────────────────────────────────────
  // 프로필 사진 등록
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = picked);
    }
  }

  /// ─────────────────────────────────────────────
  // 닉네임 수정
  Future<void> _editNickname() async {
    final newNick = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NicknameModal(initial: _nickname),
    );
    if (newNick != null && newNick.isNotEmpty) {
      setState(() => _nickname = newNick);
    }
  }

  /// ─────────────────────────────────────────────
  // 내 상세정보 보기 (alert_dialogs.dart 로 분리)
  void _showDetailDialog() {
    ProfileAlertDialog.showProfileDialog(
      context: context,
      imageFile: _imageFile,
      nickname: _nickname,
      name: _name,
      phone: _phoneNumber,
      gender: _gender,
      ageGroup: _ageGroup,
      credit: _credit,
    );
  }

  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 120,
        // 아이콘 두 개 공간 확보
        leading: Row(
          children: [
            // 보유 아이템 개수
            const SizedBox(width: 12), // 좌측 여백
            ItemCountIcon(
                imagePath: 'assets/items/correction tape.png',
                count: _correctionTapeCount),
            const SizedBox(width: 8),
            ItemCountIcon(
                imagePath: 'assets/items/diary.png', count: _diaryCount),
          ],
        ),
        title: const Text('내정보'),
        centerTitle: true,
        actions: [
          // 액자 앱 실행 버튼 (설정 버튼 바로 왼쪽)
          const FrameoLauncher(),

          // 설정 버튼
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                AlertDialogs.showThemeSheet(context, themeNotifier),
          ),
        ],
      ),
      body: DoubleBackToExit(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ─────────────────────────────────────────────
              // 프로필 사진, 닉네임, 알림창
              /// 프로필 헤더
              ProfileHeader(
                imageFile: _imageFile != null ? File(_imageFile!.path) : null,
                nickname: _nickname,
                onImageTap: _pickImage,
                onEditNickname: _editNickname,
                onDetailTap: _showDetailDialog,
              ),
              const SizedBox(height: 12),

              /// ─────────────────────────────────────────────
              /// 크레딧·성별·나이대
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CreditBox(credit: _credit),
                  InfoBox(title: '성별', value: _gender),
                  InfoBox(title: '나이대', value: _ageGroup),
                ],
              ),
              const Divider(height: 32),

              /// ─────────────────────────────────────────────
              // 아이템 목록
              const Text('아이템',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ItemCard(
                    imagePath: 'assets/items/correction tape.png',
                    label: '수정테이프',
                    price: 100,
                    onTap: () => _buyItem(
                      imagePath: 'assets/items/correction tape.png',
                      title: '수정테이프',
                      description: '일기를 수정할 수 있어요!',
                      price: 100,
                    ),
                  ),
                  ItemCard(
                    imagePath: 'assets/items/diary.png',
                    label: '일기장',
                    price: 100,
                    onTap: () => _buyItem(
                      imagePath: 'assets/items/diary.png',
                      title: '일기장',
                      description: '일기를 하나 더 작성할 수 있어요!',
                      price: 100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              /// ─────────────────────────────────────────────
              // 감정 테마 선택
              // ───────────── 감정 오브제 ─────────────
              const Text('감정 오브제 (PRO👑)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                        children: const [
                          CharacterCard(
                              imagePath: 'assets/stamps/stamp_ver1.png',
                              label: '감정이들1',
                              count: '5 / 5'),
                          CharacterCard(
                              imagePath: 'assets/stamps/stamp_ver2.png',
                              label: '감정이들2',
                              count: '2 / 5'),
                          CharacterCard(
                              imagePath: 'assets/stamps/stamp_ver3.jpg',
                              label: '감정이들3',
                              count: '3 / 5'),
                          CharacterCard(
                              imagePath: 'assets/stamps/stamp_ver4.png',
                              label: '감정이들4',
                              count: '0 / 5'),
                          CharacterCard(
                              imagePath: 'assets/stamps/stamp_ver5.jpg',
                              label: '감정이들5',
                              count: '0 / 5'),
                          CharacterCard(
                              imagePath: 'assets/stamps/stamp_ver6.jpg',
                              label: '감정이들6',
                              count: '0 / 5'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      /// ─────────────────────────────────────────────
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ────────────────────────────────────────────
  /// 아이템 구매 공통 로직
  void _buyItem({
    required String imagePath,
    required String title,
    required String description,
    required int price,
  }) async {
    AlertDialogs.showItemDialog(
      context: context,
      imagePath: imagePath,
      title: title,
      description: description,
      price: price,
      onBuy: () async {
        if (_credit >= price) {
          // 1) 크레딧 차감, 아이템 개수 증가
          setState(() {
            _credit -= price;
            if (title == '수정테이프') _correctionTapeCount++;
            if (title == '일기장') _diaryCount++;
          });

          // 2) SharedPreferences에 변경된 값 저장
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userCredit', _credit);
          await prefs.setInt('correctionTapeCount', _correctionTapeCount);
          await prefs.setInt('diaryCount', _diaryCount);

          // 3) 백엔드 API 호출: credit, correction_tape_item 또는 diary_item 필드 동기화
          final userId = prefs.getString('userId');
          if (userId != null && userId.isNotEmpty) {
            final baseUrl =
                dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
            final uri = Uri.parse('$baseUrl/api/users/$userId');

            // 전송할 JSON 바디 구성
            final Map<String, dynamic> body = {
              'credit': _credit,
            };
            if (title == '수정테이프') {
              body['correction_tape_item'] = _correctionTapeCount;
            }
            if (title == '일기장') {
              body['diary_item'] = _diaryCount;
            }

            try {
              final response = await http.patch(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  // 필요하다면 인증 헤더 추가:
                  // 'Authorization': 'Bearer ${prefs.getString('accessToken')}',
                },
                body: jsonEncode(body),
              );

              if (response.statusCode == 200) {
                // 서버에서 갱신된 User 데이터를 JSON으로 받았다면
                final updatedData = jsonDecode(response.body);
                // (선택) 서버가 돌려준 크레딧 등을 화면에 재반영하고 싶다면 이곳에 setState
                // 예: setState(() { _credit = updatedData['credit']; ... });
                print('서버 반영 완료: $updatedData');
              } else {
                print(
                    '서버 반영 실패 (HTTP ${response.statusCode}): ${response.body}');
              }
            } catch (e) {
              print('서버 호출 중 오류: $e');
            }
          }

          // 4) 다이얼로그 닫고, 완료 메시지
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title 구매 완료!')),
          );
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('크레딧이 부족합니다.')),
          );
        }
      },
    );
  }
}
