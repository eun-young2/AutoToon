import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'write_page.dart'
    show likedPosts, postContents, postDateTimes, postImages, postTitles; // likedPosts: global Set<int>
import '../widgets/bottom_nav.dart';
import '../theme/app_theme.dart';

/// 좋아요 누른 게시글 모아보기 페이지
class LikesPage extends StatelessWidget {
  const LikesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 전역 likedPosts에 들어있는 인덱스 리스트
    final likedList = likedPosts.toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('좋아요 목록'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: likedList.isEmpty
          ? const Center(child: Text('좋아요 누른 게시글이 없습니다.'))
          : ListView.builder(
        itemCount: likedList.length,
        itemBuilder: (context, idx) {
          final i = likedList[idx];
          final img = postImages[i];
          final title = postTitles[i];
          final content = postContents[i];
          final dTime = postDateTimes[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지: 가로 가득, 비율 유지
              ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.file(
                  File(img.path),
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
              ),
              // 좋아요 버튼
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              // 제목
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              // 내용
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              const SizedBox(height: 4),
              // 날짜 및 시간
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  DateFormat('yyyy.MM.dd HH:mm').format(dTime),
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