// 글쓰기 페이지에서 완료버튼 누르고 확인 버튼 누르면 뜨는 모달창 로직입니다.
import 'package:flutter/material.dart';

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

            // 2) 고정 안내 텍스트
            const SizedBox(height: 12),
            const Text(
              '나만의 오토툰 생성중...',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),

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
          ],
        ),
      ),
    );
  }
}
