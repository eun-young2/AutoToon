import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}
/// ─────────────────────────────────────────────
class _SignupPageState extends State<SignupPage> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _gender = '남성';
  Country? _country;
  String? _ageGroup;
  final List<String> _ageGroups = ['10대', '20대', '30대', '40대', '50대', '60대'];
  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _idCtrl, decoration: const InputDecoration(labelText: '아이디')),
            const SizedBox(height: 8),
            TextField(controller: _pwCtrl, decoration: const InputDecoration(labelText: '비밀번호'), obscureText: true),
            const SizedBox(height: 8),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: '이메일')),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('성별:'),
                Radio<String>(value: '남성', groupValue: _gender, onChanged: (v) => setState(() => _gender = v!)),
                const Text('남성'),
                Radio<String>(value: '여성', groupValue: _gender, onChanged: (v) => setState(() => _gender = v!)),
                const Text('여성'),
              ],
            ),
            /// ─────────────────────────────────────────────
            // *** Modified: Age & Country selection in one row, each half width ***
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _ageGroup,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '나이대',
                      border: OutlineInputBorder(),
                    ),
                    items: _ageGroups
                        .map((age) => DropdownMenuItem(
                      value: age,
                      child: Text(age),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => _ageGroup = val),
                  ),
                ),
                /// ─────────────────────────────────────────────
                const SizedBox(width: 8),

                /// ─────────────────────────────────────────────
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '국가',
                      border: OutlineInputBorder(),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: false,
                          onSelect: (Country country) {
                            setState(() => _country = country);
                          },
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_country?.name ?? '국가 선택'),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            /// ─────────────────────────────────────────────
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
              child: const Text('회원가입 완료'),
            ),
            /// ─────────────────────────────────────────────
          ],
        ),
      ),
    );
  }
}