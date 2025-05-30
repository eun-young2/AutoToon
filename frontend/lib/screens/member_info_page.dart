import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dx_project_dev2/widgets/modal.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../widgets/alert_dialogs.dart';

class MemberInfoPage extends StatefulWidget {
  const MemberInfoPage({super.key});

  @override
  State<MemberInfoPage> createState() => _MemberInfoPageState();
}

/// ─────────────────────────────────────────────
class _MemberInfoPageState extends State<MemberInfoPage> {
  // 변하지 않는 회원 정보 (카카오톡에서 받아온 정보라고 가정)
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String _nickname = 'Faker';
  final String _name = '이상혁';
  final String _phoneNumber = '010-1234-5678';
  final String _gender = '남성';
  final String _ageGroup = '30대';
  final int _credit = 100;

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
  // 설정 창
  void _showThemeDialog(BuildContext context, ThemeNotifier themeNotifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('페이퍼 모드 전환'),
                trailing: Switch(
                  value: themeNotifier.isPaperMode,
                  onChanged: (val) => themeNotifier.togglePaperMode(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('알람설정'),
                trailing: Switch(
                  value: themeNotifier.isPaperMode,
                  onChanged: (val) => themeNotifier.togglePaperMode(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  /// ─────────────────────────────────────────────
  /// 아이템(메모지, 다이어리) 아이콘을 눌렀을 때
  void _showItemDialog({
    required String imagePath,
    required String title,
    required String description,
    required int price,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        backgroundColor: const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이템 대표 이미지
              Center(child: Image.asset(imagePath, width: 80)),
              const SizedBox(height: 20),

              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center),
              const SizedBox(height: 20),

              // 크레딧 아이콘 + 가격
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/credit.png',
                      width: 24, height: 24),
                  const SizedBox(width: 6),
                  Text('$price',
                      style: const TextStyle(
                          fontSize: 20, fontStyle: FontStyle.italic)),
                ],
              ),
              const SizedBox(height: 24),

              // 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6C7A6),
                      ),
                      onPressed: () {
                        // TODO: 구매 처리
                        Navigator.pop(context);
                      },
                      child: const Text('구매'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('내정보'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showThemeDialog(context, themeNotifier);
              // TODO: 설정 페이지 연결
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ─────────────────────────────────────────────
            // 프로필 사진, 닉네임, 알림창
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _imageFile != null
                        ? FileImage(File(_imageFile!.path)) as ImageProvider
                        : const AssetImage('assets/images/GodFaker.jpg'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$_nickname님 환영합니다',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: _editNickname,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline, size: 28),
                        onPressed: _showDetailDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// ─────────────────────────────────────────────
            // 크레딧, 성별, 나이대 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCreditBox(_credit),
                _buildInfoBox('성별', _gender),
                _buildInfoBox('나이대', _ageGroup),
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
                // 메모지
                _buildItem(
                  'assets/items/memoji.png', '메모지', 35,
                  onTap: () => _showItemDialog(
                    imagePath: 'assets/items/memoji.png',
                    title: '메모지',
                    description: '어딘가에 메모를 남길 수 있을지도 몰라요!',
                    price: 35,
                  ),
                ),

                // 일기
                _buildItem(
                  'assets/items/diary.png', '일기', 45,
                  onTap: () => _showItemDialog(
                    imagePath: 'assets/items/diary.png',
                    title: '일기장',
                    description: '깜빡하고 작성하지 못한날의 일기를 작성할 수 있어요!',
                    price: 45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// ─────────────────────────────────────────────
            // 캐릭터 테마 선택
            // ───────────── 캐릭터 오브제 ─────────────
            const Text('감정 오브제',
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
                      children: [
                        _buildCharacter(
                            'assets/stamps/stamp_ver1.png', '감정이들1', '5 / 5'),
                        _buildCharacter(
                            'assets/stamps/stamp_ver2.png', '감정이들2', '2 / 5'),
                        _buildCharacter(
                            'assets/stamps/stamp_ver3.jpg', '감정이들3', '3 / 5'),
                        _buildCharacter(
                            'assets/stamps/stamp_ver4.png', '감정이들4', '0 / 5'),
                        _buildCharacter(
                            'assets/interior5.png', '감정이들5', '0 / 5'),
                        _buildCharacter(
                            'assets/interior6.png', '감정이들6', '0 / 5'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    /// ─────────────────────────────────────────────
                    // 로그아웃
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child:
                            const Text('로그아웃', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ────────────────────────────────────────────
  // 크레딧 전용 빌더 함수
  Widget _buildCreditBox(int credit) {
    return Column(
      children: [
        const Text('크레딧', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/credit.png',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '$credit',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
  Widget _buildCharacter(String imagePath, String label, String count) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text(count, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

Widget _buildItem(String imagePath, String label, int count,
    {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Image.asset(imagePath, width: 48, height: 48),
        const SizedBox(height: 4),
        Text(label),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/credit.png', width: 16, height: 16),
            const SizedBox(width: 4),
            Text('$count',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}
