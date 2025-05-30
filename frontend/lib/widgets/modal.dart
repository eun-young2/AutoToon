import 'package:flutter/material.dart';
/// 모달 두개 들어있습니다.
/// ─────────────────────────────────────────────
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

/// ─────────────────────────────────────────────
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