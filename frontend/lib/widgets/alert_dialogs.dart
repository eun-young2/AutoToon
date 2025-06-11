import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/write_page.dart';
import '../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';

// 알림창(dialog)들은 여기에 추가하겠습니당. 모달창은 따로에요! - 모달창은 확인, 취소가 없는 창
/// ──────────────── calendar_page.dart ───────────────────
/// 캘린더 페이지에서 날짜 두번 탭 했을때 작성된 게시글 없을때 뜨는창
class CalendarAlertDialog {
  static void showRewardDialog(
    BuildContext context,
    int rewardCount,
    TabController tabController,
    bool isToday,
  ) {
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
                      '2. 출석체크는 1일에 10 크레딧을 받을 수 있으며 연속 출석시 더 많은 크레딧을 받을 수 있어요.',
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
      backgroundColor: const Color(0xFFF5F5F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //테마변경
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('페이퍼 모드 전환'),
              trailing: Switch(
                value: theme.isPaperMode,
                onChanged: (_) => theme.togglePaperMode(),
              ),
            ),
            // 알람설정
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('알람설정'),
              trailing: Switch(
                value: theme.isPaperMode,
                onChanged: (_) => theme.togglePaperMode(),
              ),
            ),
            // 로그아웃
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () async {
                // ① bottom sheet 닫기
                Navigator.of(context).pop();

                // ② “정말 로그아웃하시겠습니까?” 확인 다이얼로그 띄우기
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFFF5F5F5),
                      title: const Text('로그아웃'),
                      content: const Text('정말 로그아웃하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFD6C7A6), // 기존 배경색 유지
                            foregroundColor: Colors.black, // 텍스트 색상을 검정으로
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('확인'),
                        ),
                      ],
                    );
                  },
                );
                // ③ 사용자가 “확인”을 눌렀다면 실제 로그아웃 처리 및 인트로 화면으로 이동
                if (shouldLogout == true) {
                  // 예를 들어: await KakaoSdk.instance.logout();
                  // TODO: 카카오톡 API에서 실제 로그아웃 처리 코드를 여기에 넣으세요
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  // Intro 페이지로 이동 (기존 스택 모두 제거)
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/intro',
                    (route) => false,
                  );
                }
              },
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        backgroundColor: const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Image.asset(imagePath, width: 80)),
              const SizedBox(height: 20),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center),
              const SizedBox(height: 20),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black, // 텍스트 색상을 검정으로
                        side: const BorderSide(
                            color: Colors.black), // 테두리도 검정으로 (원하시면)
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6C7A6),
                        // 기존 배경색 유지
                        foregroundColor: Colors.black, // 텍스트 색상을 검정으로
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
      content: const Text('일기생성 및 수정은 하루에 한번만 가능해요!\n이후에는 아이템을 사용해야 합니다!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(
            '취소',
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD6C7A6), // 기존 배경색 유지
            foregroundColor: Colors.black, // 텍스트 색상을 검정으로
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('확인'),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}

// 스타일 정보 다이얼로그 위젯(어떤 스타일로 그림을 그려드릴까요 부분)
class StyleInfoDialog extends StatelessWidget {
  const StyleInfoDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF5F5F5),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 다이얼로그 제목
              const Text(
                '스타일 예시',
                style: TextStyle(
                  fontFamily: '온글잎 혜련',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 캐릭터 (한 줄 전체)
              SizedBox(
                height: 280, // 원하는 크기로 조절하세요
                child: Center(
                  child: _StyleItem(
                    label: '캐릭터',
                    imagePaths: const [
                      'assets/example/캐릭터_남.png',
                      'assets/example/캐릭터_여.png',
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 일러스트 (한 줄 전체)
              SizedBox(
                height: 250, // 원하는 크기로 조절하세요
                child: Center(
                  child: _StyleItem(
                    label: '일러스트',
                    imagePaths: const [
                      'assets/example/일러스트_남.png',
                      'assets/example/일러스트_여.png',
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // 닫기 버튼
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '닫기',
                    style: TextStyle(
                      fontFamily: '온글잎 혜련',
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// _StyleItem: 레이블과 이미지 2장을 가로로 표시하는 커스텀 위젯
/// [label]      : 스타일 이름(예: '캐릭터', '일러스트' 등)
/// [imagePaths] : 반드시 2개의 이미지 경로를 전달해야 함
/// ─────────────────────────────────────────────────────────────
class _StyleItem extends StatelessWidget {
  final String label;
  final List<String> imagePaths; // 이미지 파일 경로 리스트, 길이=2여야 함

  _StyleItem({
    Key? key,
    required this.label,
    required this.imagePaths,
  })  : assert(imagePaths.length == 2, 'imagePaths에는 반드시 2개의 경로가 있어야 합니다.'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // 세로 축 가운데 정렬
      children: [
        // 1) 다이얼로그 너비의 90%만큼 차지하도록 FractionallySizedBox 사용
        FractionallySizedBox(
          widthFactor: 1, // 부모 다이얼로그 너비의 90%
          child: Row(
            children: [
              // 왼쪽 이미지
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    imagePaths[0],
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 오른쪽 이미지
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    imagePaths[1],
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 2) 레이블을 가운데 정렬
        Text(
          label,
          style: const TextStyle(
            fontFamily: '온글잎 혜련',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// ───────────────────────────────────────────────────
/// “잠금 해제” 다이얼로그: 다이얼로그 내부에서 일기장 소모 로직 수행
class UnlockDialogs {
  static Future<void> showUnlockDiaryDialog({
    required BuildContext context,
    required int currentDiaryCount,
    required VoidCallback onUnlocked, // 잠금 해제 후 WritePage 쪽 setState 콜백
  }) async {
    final prefs = await SharedPreferences.getInstance();
    bool hasNoDiary = currentDiaryCount <= 0;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('잠금을 해제하시겠습니까?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 일기장 이미지
                  Image.asset(
                    'assets/items/diary.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '해제 시 일기장 한 장이 소모됩니다.',
                    style: TextStyle(fontSize: 14),
                  ),
                  if (hasNoDiary) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '보유한 일기장이 없습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD6C7A6), // 기존 배경색 유지
                    foregroundColor: Colors.black, // 텍스트 색상을 검정으로
                  ),
                  onPressed: () async {
                    if (currentDiaryCount > 0) {
                      // 일기장 소모
                      final newCount = currentDiaryCount - 1;
                      await prefs.setInt('diaryCount', newCount);
                      onUnlocked(); // WritePage 쪽에서 잠금 해제 처리
                      Navigator.pop(context);
                    } else {
                      // 보유 일기장 없음 메시지 갱신
                      setDialogState(() {
                        hasNoDiary = true;
                      });
                    }
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// ────────────── “일기 작성 보상” 다이얼로그 ─────────────────────
class DiaryRewardDialog {
  /// 신규 작성 후 DetailPage 진입 시 호출
  /// - rewardCount: 일기 작성시 지급할 크레딧 양
  static Future<void> showDiaryRewardDialog(
    BuildContext context,
    int rewardCount,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF5F5F5),

        // 타이틀: 환영 인사
        title: const Text(
          '일기를 작성했어요!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // 메시지: 크레딧 안내
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/credit.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 8),
                // rewardCount를 동적으로 표시하기 위해 const 제거
                Text(
                  'x $rewardCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '오늘의 크레딧을 드릴게요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 다이얼로그 닫기 직전에 크레딧을 지급하도록
              final prefs = await SharedPreferences.getInstance();
              final todayKey = DateTime.now().toIso8601String().split('T')[0];
              final lastGiven = prefs.getString('lastDiaryCreditDate') ?? '';
              if (lastGiven != todayKey) {
                final prevCredit = prefs.getInt('userCredit') ?? 0;
                await prefs.setInt('userCredit', prevCredit + 30);
                await prefs.setString('lastDiaryCreditDate', todayKey);
              }
              Navigator.of(context).pop();
            },
            child: const Text(
              '확인',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────── detail_page.dart ─────────────────────
// ────────────── DetailPage 삭제 다이얼로그 ────────────────
// ───────── 수정 / 삭제 콜백 ─────────
class DetailAlertDialogs {
  /// 게시글 삭제 전에 “삭제 확인” 다이얼로그를 띄웁니다.
  ///
  /// [context]: 다이얼로그를 띄울 BuildContext
  /// [idx]: 삭제할 게시글의 인덱스
  /// [onDeleted]: 사용자가 “삭제”를 눌러 실제로 지운 뒤 호출할 콜백 (보통 DetailPage 쪽에서 setState용)
  static Future<void> showDeletePostDialog({
    required BuildContext context,
    required int idx,
    required VoidCallback onDeleted,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF5F5F5),
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 글을 삭제하시겠습니까?'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  '취소',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD6C7A6),
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
        ],
      ),
    );

    if (ok == true) {
      // 실제로 전역 리스트에서 idx 위치의 게시글 데이터를 지웁니다.
      postImages.removeAt(idx);
      postContents.removeAt(idx);
      postDateTimes.removeAt(idx);

      // 만약 삭제 후 다시 목록으로 돌아가고 싶다면 Navigator.pop(context) 해도 됩니다.
      // 여기서는 삭제만 하고, 같은 화면에서 리빌드 되어 remains 보여지도록 setState로 처리합니다.
      // 삭제가 끝난 뒤 호출 측에서 화면을 갱신할 수 있도록 콜백 실행
      onDeleted();
    }
  }
}

class WriteAlertDialogs {
  /// WritePage에서 수정 모드(editIdx != null)일 때,
  /// 뒤로가기 버튼을 누르면 이 함수를 호출하여 다이얼로그 띄우기.
  ///
  /// 반환값: 사용자가 “예”를 누르면 true, “아니요”를 누르면 false.
  static Future<bool> showCancelEditDialog(
    BuildContext context,
    int idx, // 수정 중이던 게시물의 인덱스를 파라미터로 받습니다
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 외부 터치 시 닫기 방지
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF5F5F5),
        title: const Text('수정 취소 확인'),
        content: const Text('수정을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false), // 취소 선택
            child: const Text(
              '아니요',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD6C7A6),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              // “예”를 누르면 DetailPage로 돌아가면서 idx를 함께 전달
              Navigator.pushNamed(
                context,
                '/detail', // 라우트에 등록된 DetailPage
                arguments: {
                  'idx': idx, // 전달받은 인덱스를 그대로 사용
                  'reward': 0,
                },
              );
            },
            child: const Text('예'),
          ),
        ],
      ),
    );

    // 다이얼로그에서 null이 리턴되면 false로 간주
    return result == true;
  }
}

/// ────────────── “잠금 해제(수정테이프 사용)” 다이얼로그 ──────────────
// DetailPage에서 ‘오늘 이미 수정했을 경우’에 띄우는 대화상자입니다.
// SharedPreferences의 'correctionTapeCount'를 꺼내서 사용하고,
// 사용자가 “확인”을 누르면 correctionTapeCount를 하나 차감하고
// lastEditDate는 오늘 날짜로 업데이트한 뒤 onUnlock()을 호출합니다.
class WriteLockDialogs {
  /// [context] : 다이얼로그를 띄울 컨텍스트
  /// [onUnlock] : 수정테이프를 사용해서 잠금을 해제한 후 호출할 콜백(대개 DetailPage에서 write 페이지로 이동)
  static Future<void> showUnlockEditDialog({
    required BuildContext context,
    required VoidCallback onUnlock,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // SharedPreferences에서 ‘수정테이프 보유 개수’ 가져오기
    int tapeCount = prefs.getInt('correctionTapeCount') ?? 0;
    bool hasNoTape = (tapeCount <= 0);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF5F5F5),
              title: const Text('오늘은 이미 수정 하였습니다.'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 수정 테이프 이미지
                  Image.asset(
                    'assets/items/correction tape.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '잠금을 해제 해주세요!\n잠금 해제 시 수정테이프 한 개가 소모됩니다.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (hasNoTape) ...[
                    const Text(
                      '수정테이프가 부족 합니다.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx2).pop(); // 취소하면 그냥 닫기
                  },
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasNoTape
                        ? Colors.grey.shade300
                        : const Color(0xFFD6C7A6),
                    foregroundColor: hasNoTape ? Colors.black38 : Colors.black,
                  ),
                  onPressed: hasNoTape
                      ? null // 수정테이프가 없으면 비활성화
                      : () async {
                          // 1) 수정테이프 차감
                          final newCount = tapeCount - 1;
                          await prefs.setInt('correctionTapeCount', newCount);

                          // 2) lastEditDate를 오늘로 기록 (yyyy-MM-dd 형식)
                          final todayKey =
                              DateTime.now().toIso8601String().split('T')[0];
                          await prefs.setString('lastEditDate', todayKey);

                          Navigator.of(ctx2).pop();
                          // 3) onUnlock 콜백(수정 페이지로 이동 등) 호출
                          onUnlock();
                        },
                  child: const Text('잠금해제'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
