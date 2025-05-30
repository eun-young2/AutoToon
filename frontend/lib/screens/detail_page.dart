import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dx_project_dev2/screens/write_page.dart'
    show postContents, postDateTimes, postImages;
/// ─────────────────────────────────────────────
class DetailPage extends StatefulWidget {
  const DetailPage({Key? key}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}
/// ─────────────────────────────────────────────
class _DetailPageState extends State<DetailPage> {
  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    List<int> indexes;

    if (args is int) {
      final idx = args;
      final dateTime = postDateTimes[idx];
      indexes = postDateTimes
          .asMap()
          .entries
          .where((e) => isSameDay(e.value, dateTime))
          .map((e) => e.key)
          .toList();
    } else if (args is List<int>) {
      indexes = args;
    } else {
      indexes = [];
    }

    return Scaffold(
      /// ─────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Auto Toon'),
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      /// ─────────────────────────────────────────────
      body: indexes.isEmpty
          ? const Center(child: Text('선택된 게시물이 없습니다.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: indexes.map((iIdx) {
            final img = postImages[iIdx];
            final content = postContents[iIdx];
            final dTime = postDateTimes[iIdx];

            return Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ─────────────────────────────────────────────
                  // 날짜
                  Center(
                    child: Text(
                      DateFormat('yyyy.MM.dd').format(dTime),
                      style: const TextStyle(
                        fontFamily: '온글잎 혜련',
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// ─────────────────────────────────────────────
                  // 이미지
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Image.file(
                      File(img.path),
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // (주석 해제 후 사용하세요)
                  // Center(
                  //   child: IconButton(
                  //     icon: Icon(
                  //       liked ? Icons.favorite : Icons.favorite_border,
                  //       color: liked ? Colors.red : Colors.grey,
                  //     ),
                  //     onPressed: () => setState(() {
                  //       if (liked) likedPosts.remove(iIdx);
                  //       else likedPosts.add(iIdx);
                  //     }),
                  //   ),
                  // ),

                  /// ─────────────────────────────────────────────
                  // 내용
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      content,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  /// ─────────────────────────────────────────────
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
