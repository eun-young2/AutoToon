import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
/// 말풍선(ChatBubble) 위젯과 그 페인터 클래스 분리
/// ─────────────────────────────────────────────────────────────
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isSender;

  const ChatBubble({
    Key? key,
    required this.text,
    required this.isSender,
  }) : super(key: key);

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
    path.quadraticBezierTo(
        size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius + 20, size.height);
    path.lineTo(25, size.height + 12); // 꼬리 시작점
    path.lineTo(20, size.height); // 꼬리 끝점
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius + 10, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// ────────────────────────────────────────────────────
/// 말풍선 툴팁 위젯 (TooltipBubble)
///
/// [tailCenterX]       : 말풍선 좌측 경계로부터 꼬리 삼각형 중심까지의 상대 x좌표
/// [message]           : 말풍선 안에 표시할 텍스트 (“나만의 액자를 꾸며보세요”)
/// [messageNshow]      : “다시 보지 않기” 버튼에 표시할 텍스트
/// [onClose]           : “×” 버튼을 눌렀을 때 호출되는 콜백
/// [onDoNotShowAgain]  : “다시 보지 않기” 버튼을 눌렀을 때 호출되는 콜백
/// ────────────────────────────────────────────────────
class TooltipBubble extends StatelessWidget {
  final double tailCenterX;
  final VoidCallback onClose;
  final VoidCallback onDoNotShowAgain;
  final String message;
  final String messageNshow;

  const TooltipBubble({
    Key? key,
    required this.tailCenterX,
    required this.onClose,
    required this.onDoNotShowAgain,
    required this.message,
    required this.messageNshow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 말풍선 배경
        CustomPaint(
          painter: _BubblePainter(tailCenterX: tailCenterX),
          size: const Size(double.infinity, double.infinity),
        ),

        // 말풍선 내부 콘텐츠
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: '온글잎 혜련',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // 2) “다시 보지 않기” 버튼
              TextButton(
                onPressed: onDoNotShowAgain,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  messageNshow,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3) “×” 버튼
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ────────────────────────────────────────────────────
/// 말풍선 배경을 그리는 CustomPainter (_BubblePainter)
/// ────────────────────────────────────────────────────
class _BubblePainter extends CustomPainter {
  final double tailCenterX;

  _BubblePainter({required this.tailCenterX});


  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black87;
    // ─────── 말풍선 꼬리가 위쪽에 오도록 ───────
    const tailHeight = 10.0;
    const tailWidth = 20.0;

    // 1) 꼬리 부분(맨 위 중심) 그리기
    final centerX = size.width / 1.345;
    final path = Path();
    path.moveTo(centerX - tailWidth / 2, tailHeight);
    path.lineTo(centerX + tailWidth / 2, tailHeight);
    path.lineTo(centerX, 0);
    path.close();
    canvas.drawPath(path, paint);
    path.close();
    canvas.drawPath(path, paint);

    // 2) 꼬리 아래(=tailHeight)부터 사각형 그리기
    final rrect = RRect.fromLTRBR(
      0,
      tailHeight,
      size.width,
      size.height,
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
