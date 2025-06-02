import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
// 알림창(dialog)들은 여기에 추가하겠습니당. 모달창은 따로에요! - 모달창은 확인, 취소가 없는 창
/// ──────────────── calendar_page.dart ───────────────────
/// 캘린더 페이지에서 날짜 두번 탭 했을때 작성된 게시글 없을때 뜨는창
class CalendarAlertDialog {
  static void showRewardDialog(BuildContext context, int rewardCount,TabController tabController,bool isToday,) {
    showDialog(
      context: context,
      barrierDismissible: false, // 외부 터치 시 닫기 방지
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFFF5F5F5),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '해당 날짜에 작성된 게시글이 없습니다!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/stamps/stamp_peace.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x$rewardCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '오늘의 일기를 작성해보세요!\n분석해서 재밌는 만화를 그려드릴게요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                /// ─────────────────────────────────────────────
                // 작성하기 버튼은 오늘일 때만 활성화
                InkWell(
                  onTap: isToday
                      ? () {
                    Navigator.pop(context);
                    tabController.animateTo(2);
                  }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFFF6A7C6)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            Icons.edit,
                            size: 20,
                          color: isToday ? Colors.black : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '작성하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isToday ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                /// ─────────────────────────────────────────────
                const SizedBox(height: 12),
                TextButton(
                      onPressed: () {
                Navigator.pop(context);
                },
                  child: const Text(
                    '좀 이따 할게',
                    style: TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      color: Colors.black54,
                    ),
                  ),
                ),
                /// ─────────────────────────────────────────────
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ────────────── member_info_page.dart ─────────────────────
/// 회원 프로필 상세보기 다이얼로그
class ProfileAlertDialog {
  /// imageFile: 갤러리에서 골라둔 프로필 사진 XFile (null 이면 default_avatar)
  /// nickname, name, phone, gender, ageGroup, credit: 표시할 문자열
  static Future<void> showProfileDialog({
    required BuildContext context,
    XFile? imageFile,
    required String nickname,
    required String name,
    required String phone,
    required String gender,
    required String ageGroup,
    required int credit,
  }) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFF5F5F5),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ① 제목
              const Text(
                '내 정보',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ② 프로필 사진
              CircleAvatar(
                radius: 40,
                backgroundImage: imageFile != null
                    ? FileImage(File(imageFile.path))
                    : const AssetImage('assets/images/GodFaker.jpg')
                as ImageProvider,
              ),
              const SizedBox(height: 24),

              // ③ 정보 리스트 컨테이너
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.person, '닉네임: $nickname'),
                    _buildInfoRow(Icons.badge, '이름: $name'),
                    _buildInfoRow(Icons.phone, '전화: $phone'),
                    _buildInfoRow(Icons.male, '성별: $gender'),
                    _buildInfoRow(Icons.cake, '나이대: $ageGroup'),
                    _buildInfoRow(Icons.star, '크레딧: $credit'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 크레딧 정책 컨테이너
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/credit.png',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 8),

                        // 크레딧 정책 제목
                        const Text(
                          '크레딧 정책',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),

                    // 예시: 크레딧에 대한 설명 텍스트 추가
                    const Text(
                      '1. 회원가입시 최초에 300크레딧을 받을 수 있어요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '2. 출석체크는 1일에 30 크레딧을 받을 수 있으며 연속 출석시 더 많은 크레딧을 받을 수 있어요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '3. 일기 작성시 기본으로 30크레딧이 제공되며, 하루 한번에 한해서 적용돼요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ④ 닫기 버튼
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '닫기',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// ① 설정창 ───────────────────────────────
class AlertDialogs {
  static void showThemeSheet(BuildContext context, ThemeNotifier theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('페이퍼 모드 전환'),
              trailing: Switch(
                value: theme.isPaperMode,
                onChanged: (_) => theme.togglePaperMode(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('알람설정'),
              trailing: Switch(
                value: theme.isPaperMode,
                onChanged: (_) => theme.togglePaperMode(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ② 아이템 상세 Dialog ───────────────────────────────
  static Future<void> showItemDialog({
    required BuildContext context,
    required String imagePath,
    required String title,
    required String description,
    required int price,
    required VoidCallback onBuy,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        backgroundColor: const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Image.asset(imagePath, width: 80)),
              const SizedBox(height: 20),
              Text(title,
                  style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/credit.png', width: 24, height: 24),
                  const SizedBox(width: 6),
                  Text('$price',
                      style: const TextStyle(
                          fontSize: 20, fontStyle: FontStyle.italic)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,          // 텍스트 색상을 검정으로
                        side: const BorderSide(color: Colors.black), // 테두리도 검정으로 (원하시면)
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6C7A6), // 기존 배경색 유지
                        foregroundColor: Colors.black,             // 텍스트 색상을 검정으로
                      ),
                      // TODO: 구매 로직
                      onPressed: onBuy, // 구매 버튼 → 콜백 실행
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
}

/// ────────────── Write_page.dart ─────────────────────
// 오토툰 생성 전 사용자에게 한 번 더 묻는 확인 다이얼로그
Future<bool> showCreateConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFF5F5F5),
      title: const Text('오토툰을 생성하겠습니까?'),
      content: const Text('수정하거나 삭제 후 재작성은 하루에 한번만 가능해요!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('확인'),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}
/// ─────────────────────────────────────────────