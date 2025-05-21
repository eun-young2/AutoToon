import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dx_project_dev2/theme/app_theme.dart';
import 'package:dx_project_dev2/widgets/bottom_nav.dart';
import 'package:dx_project_dev2/utils/discard_confirm.dart';

/// 전역 리스트 선언 (이미지, 텍스트, 작성시간)
final List<XFile> postImages = [];
final List<String> postTitles = [];
final List<String> postContents = [];
final List<DateTime> postDateTimes = [];

/// 좋아요 누른 게시글 인덱스 모아두기
final Set<int> likedPosts = {};

class WritePage extends StatefulWidget {
  const WritePage({Key? key}) : super(key: key);

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  XFile? _image;
  // ▶ 오디오 파일 경로 저장
  File? _audioFile;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _image = img);
  }

  Future<void> _pickAudio() async {
    // TODO: audio picker 플러그인 적용
    // 예시: FilePicker.platform.pickFiles(type: FileType.audio)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('음성 파일 첨부 기능은 추후 구현됩니다.')),
    );
  }

  void _submitPost() {
    if (_image == null && _contentCtrl.text.isEmpty && _titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목, 내용 또는 이미지를 입력해주세요.')),
      );
      return;
    }
    postImages.insert(0, _image!);
    postTitles.insert(0, _titleCtrl.text);
    postContents.insert(0, _contentCtrl.text);
    postDateTimes.insert(0, DateTime.now());

    Navigator.pushReplacementNamed(context, '/main');
  }

  void _showAttachmentsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('이미지 첨부'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('음성 파일 첨부'),
              onTap: () {
                Navigator.pop(context);
                _pickAudio();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,  // ▶ 배경색 통일
      appBar: AppBar(
        title: const Text('새 글 쓰기'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
        actions: [
          // ▶ + 버튼 추가
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _showAttachmentsMenu,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // 제목 입력
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                border: InputBorder.none,
              ),
            ),
            const Divider(),

            // 내용 입력
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                style: const TextStyle(fontSize: 16, height: 1.5),
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: '내용을 입력하세요...',
                  border: InputBorder.none,
                ),
              ),
            ),

            // 첨부된 이미지
            if (_image != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_image!.path),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            // 첨부된 오디오 표시
            if (_audioFile != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.mic),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_audioFile!.path)),
                ],
              ),
            ],

            const SizedBox(height: 12),
            // 게시 버튼
            ElevatedButton(
              onPressed: _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('제출', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 10),
            const Text(
              '일기 변환은 2-3분 정도 소요됩니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:  BottomNav(
        currentIndex: 2,
        onWillNavigate: (context, index) async {
          // 다른 탭(0,1,3)으로 이동 시에만 확인창 띄우고,
          // 글쓰기 탭(2)을 누르면 바로 유지
          if (index != 2 && (_titleCtrl.text.isNotEmpty ||
              _contentCtrl.text.isNotEmpty || _image != null)) {
            // utils/discard_confirm.dart 의 함수
            return await showDiscardDialog(context);
          }
          return true;
        },
      ),
    );
  }
}