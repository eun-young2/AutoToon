import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _pwCtrl = TextEditingController();
  bool _keepLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _idCtrl, decoration: const InputDecoration(labelText: '아이디')),
            const SizedBox(height: 8),
            TextField(controller: _pwCtrl, decoration: const InputDecoration(labelText: '비밀번호'), obscureText: true),
            SwitchListTile(
              title: const Text('로그인 상태 유지'),
              value: _keepLoggedIn,
              onChanged: (v) => setState(() => _keepLoggedIn = v),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
              child: const Text('로그인'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}