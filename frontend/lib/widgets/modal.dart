import 'package:flutter/material.dart';
/// ─────────────── write_page ───────────────────────
/// 로딩 중에 랜덤 문구를 보여주는 모달 다이얼로그
class LoadingModal extends StatelessWidget {
  final String prompt;
  const LoadingModal({Key? key, required this.prompt}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1) 로딩 인디케이터
            const CircularProgressIndicator(),
            /// ─────────────────────────────────────────────
            // 2) 고정 안내 텍스트
            const SizedBox(height: 12),
            const Text(
              '나만의 오토툰 생성중...',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            /// ─────────────────────────────────────────────
            // 3) 랜덤 프롬프트 묶음
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,       // 배경색 지정
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                prompt,
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            /// ─────────────────────────────────────────────
          ],
        ),
      ),
    );
  }
}

/// ─────────────── member_info_page ───────────────────────
/// 닉네임 수정용 모달 다이얼로그
class NicknameModal extends StatefulWidget {
  final String initial;
  const NicknameModal({Key? key, required this.initial}) : super(key: key);

  @override
  State<NicknameModal> createState() => _NicknameModalState();
}

class _NicknameModalState extends State<NicknameModal> {
  late TextEditingController _controller;
  bool _tooLong = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _tooLong = v.length > 6);
  }
  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFFF5F5F5),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/stamps/stamp_happy.png'),
            ),
            const SizedBox(height: 16),
            const Text(
              '최대 6글자 이내로 작성해 주세요.\n자신을 가장 잘 나타내는 이름이 좋아요!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            if (_tooLong) ...[
              const SizedBox(height: 8),
              const Text('6글자 이내로 입력해 주세요.',
                  style: TextStyle(fontSize: 12, color: Colors.red)),
            ],
            const SizedBox(height: 8),
            /// ─────────────────────────────────────────────
            TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              maxLength: 7,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                counterText: '',
                hintText: '닉네임 입력',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_tooLong || _controller.text.isEmpty)
                  ? null
                  : () => Navigator.of(context).pop(_controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF6A7C6),
                foregroundColor: Colors.black,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('작성 완료'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────── home_page.dart ───────────────────────
// ─────────────── 출석 체크 모달 다이얼로그 ───────────────────────
/// home_page에 접속했을 때 자동으로 한 번 띄워주는 “출석 체크” 알림창
class AttendanceModal extends StatelessWidget {
  final int totalDays; // 지금까지 출석한 누적 일수
  final int reward;    // 이번 출석으로 받은 크레딧 양

  const AttendanceModal({
    Key? key,
    required this.totalDays,
    required this.reward,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ① 타이틀: “xxx일차 방문 성공!”
            Text(
              '$totalDays일차\n방문 성공!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // ② 보상 안내 텍스트: 오늘 받은 크레딧
            Text(
              '오늘 출석으로 $reward 크레딧을 받으셨습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            // ③ 확인 버튼
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6C7A6),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('확인했어요'),
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────── welcome_modal ───────────────────────
/// 첫 로그인 시 한 번만 보여줄 환영 모달 다이얼로그
class WelcomeModal extends StatelessWidget {
  const WelcomeModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이틀: 환영 인사
            const Text(
              '환영합니다!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // 메시지: 크레딧 안내
            const Text(
              '300 크레딧이 적립되었습니다!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            // 확인 버튼
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6C7A6),
                foregroundColor: Colors.black,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('확인했어요'),
            ),
          ],
        ),
      ),
    );
  }
}