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
  // ───────── 수정 / 삭제 콜백 ─────────
  void _deletePost(int idx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제')),
        ],
      ),
    );

    if (ok ?? false) {
      setState(() {
        postImages.removeAt(idx);
        postContents.removeAt(idx);
        postDateTimes.removeAt(idx);
      });
      Navigator.pop(context); // 목록에서 돌아가기
    }
  }

  /// TODO – 수정 페이지 이동(원하는 곳으로 push)
  void _editPost(int idx) {
    // Navigator.pushNamed(context, '/edit', arguments: idx);
    debugPrint('수정하기 클릭 – index $idx');
  }

  /// ───────────────── UI ──────────────────────
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    if (args is! int) {
      // 올바른 인덱스가 안 넘어왔을 때
      return const Scaffold(
        body: Center(child: Text('잘못된 접근입니다.')),
      );
    }

    final int idx = args;
    final imgFile = postImages[idx];
    final bodyText = postContents[idx];
    final DateTime date = postDateTimes[idx];

    return Scaffold(
      /// ─────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Auto Toon'),
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editPost(idx);
              } else if (value == 'delete') {
                _deletePost(idx);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('수정하기')),
              PopupMenuItem(value: 'delete', child: Text('삭제하기')),
            ],
          ),
        ],
      ),
      /// ─────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜
            Center(
              child: Text(
                DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(date),
                style: const TextStyle(fontFamily: '온글잎 혜련', fontSize: 20),
              ),
            ),
            const SizedBox(height: 30),
            /// ─────────────────────────────────────────────
            // 이미지
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Image.file(
                File(imgFile.path),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            /// ─────────────────────────────────────────────
            // 본문
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                bodyText,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            /// ─────────────────────────────────────────────
          ],
        ),
      ),
    );
  }
}
