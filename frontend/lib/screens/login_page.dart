import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 상단 스페이서
            const SizedBox(height: 1),

            // 중앙 로고 텍스트
            const Center(
              child: Text(
                'AutoToon',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // 하단 이미지 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/main');
                },
                child: Image.asset(
                  'assets/images/kakao_login_medium_wide.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
