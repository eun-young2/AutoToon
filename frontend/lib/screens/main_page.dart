import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'write_page.dart';
import 'package:dx_project_dev2/widgets/bottom_nav.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int? _selectedCount;  // 선택된 개수

  @override
  Widget build(BuildContext context) {
    final images = postImages; // WritePage에서 추가된 리스트
    final crossCount = _selectedCount ?? 3; // 기본 3개씩 보기

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Text(
              'AutoToon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 정렬 드롭다운
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                const Icon(LineAwesomeIcons.th_large_solid, size: 20, color: Colors.black),
                const SizedBox(width: 3),
                DropdownButton<int>(
                  value: _selectedCount,
                  hint: const Text('정렬'),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  items: [2, 3, 4, 5].map((e) => DropdownMenuItem(
                    value: e,
                    child: Text('$e개씩 보기'),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCount = val);
                  },
                ),
              ],
            ),
          ),
          // 그리드 뷰 (글쓰기 버튼을 첫 번째 타일로 포함)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                itemCount: images.length + 1, // +1 for write button
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, idx) {
                  if (idx == 0) {
                    // 첫 번째: 글쓰기 버튼
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/write'),
                      child: DottedBorder(
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(20),
                        dashPattern: const [6, 3],
                        strokeWidth: 1,
                        color: Colors.black,
                        child: const Center(
                          child: Icon(Icons.edit, color: Colors.black,size: 35),
                        ),
                      ),
                    );
                  }
                  // images 리스트에서 XFile을 직접 꺼내 사용
                  final imgIdx = idx - 1;  // XFile 타입
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/detail',
                      arguments: imgIdx,            // ▶ 인덱스 전달
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20), // 원하는 반경
                      child: Image.file(
                        File(postImages[imgIdx].path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}