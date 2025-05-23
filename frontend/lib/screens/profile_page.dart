import 'package:flutter/material.dart';
import 'package:dx_project_dev2/models/user_model.dart';
import 'package:dx_project_dev2/utils/date_formatter.dart';
import 'package:dx_project_dev2/widgets/bottom_nav.dart';

/// 내 정보 페이지
/// [user] 객체를 전달받아 화면에 보여줍니다.
class ProfilePage extends StatelessWidget {
  final User? user;

  const ProfilePage({Key? key, this.user}) : super(key: key);

  /// 라우트에서 arguments를 읽어 이 팩토리로 호출하세요.
  factory ProfilePage.route(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return ProfilePage(user: args is User ? args : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: Text('사용자 정보 없음'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('아이디', user!.id),
            const SizedBox(height: 12),
            _buildInfoRow('이메일', user!.email),
            const SizedBox(height: 12),
            _buildInfoRow('성별', user!.gender),
            const SizedBox(height: 12),
            _buildInfoRow(
              '생년월일',
              user!.birth != null
                  ? DateFormatter.yMd(user!.birth!)
                  : '미등록',
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 4),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}