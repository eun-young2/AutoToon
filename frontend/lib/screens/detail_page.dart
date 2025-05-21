import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dx_project_dev2/screens/write_page.dart' show likedPosts, postContents, postDateTimes, postImages;
import '../widgets/bottom_nav.dart'; // 필요시
import 'package:dx_project_dev2/theme/app_theme.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({Key? key}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final Set<int> _liked = {};

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final idx = ModalRoute.of(context)!.settings.arguments as int;
    final dateTime = postDateTimes[idx];
    final indexes = postDateTimes
        .asMap()
        .entries
        .where((e) => isSameDay(e.value, dateTime))
        .map((e) => e.key)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Auto Toon'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        itemCount: indexes.length,
        itemBuilder: (context, i) {
          final iIdx = indexes[i];
          final img = postImages[iIdx];
          final content = postContents[iIdx];
          final dTime = postDateTimes[iIdx];
          final liked = _liked.contains(iIdx);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.file(
                File(img.path),
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: IconButton(
                  icon: Icon(
                    likedPosts.contains(idx) ? Icons.favorite : Icons.favorite_border,
                    color: likedPosts.contains(idx) ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => setState(() {
                    if (likedPosts.contains(idx)) {
                      likedPosts.remove(idx);
                    } else {
                      likedPosts.add(idx);
                    }
                  }),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  content,
                  style: const TextStyle(fontSize : 16, height: 1.5),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  DateFormat('yyyy년 MM월 dd일 H시').format(dTime),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}