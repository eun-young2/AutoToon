// import 'package:dx_project_dev2/screens/detail_design.dart';
import 'package:dx_project_dev2/screens/detail_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // for LengthLimitingTextInputFormatter
import 'package:dx_project_dev2/theme/app_theme.dart';
import 'package:dx_project_dev2/widgets/bottom_nav.dart';
import 'package:dx_project_dev2/utils/discard_confirm.dart';
import 'package:intl/intl.dart';

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
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  String _selectedStyle = '수채화';

  @override
  void initState() {
    super.initState();
    _contentCtrl.addListener(() {
      setState(() {}); // 글자 수 갱신
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _image = img);
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
              title:  const Text('이미지 첨부'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(now);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('새 일기 쓰기'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _showAttachmentsMenu,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 날짜
            Center(
              child: Text(
                dateString,
                style: const TextStyle(
                  fontFamily: '온글잎 혜련',
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD3D3D3), width: 1),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TextField(
                      controller: _contentCtrl,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontFamily: '온글잎 혜련',
                      ),
                      maxLines: null,
                      expands: true,
                      maxLength: 300,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      inputFormatters: [LengthLimitingTextInputFormatter(500)],
                      decoration: const InputDecoration(
                        hintText: '오늘의 이야기를 적어보세요.',
                        hintStyle: TextStyle(fontFamily: '온글잎 혜련', fontSize:15, color: Colors.black38,),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_contentCtrl.text.length}/500',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const Text(
              '스타일',
              style: TextStyle(
                fontFamily: '온글잎 혜련',
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRadio('수채화', _selectedStyle, (v) {
                  setState(() => _selectedStyle = v!);
                }),
                const SizedBox(width: 24),
                _buildRadio('동화', _selectedStyle, (v) {
                  setState(() => _selectedStyle = v!);
                }),
                const SizedBox(width: 24),
                _buildRadio('웹툰', _selectedStyle, (v) {
                  setState(() => _selectedStyle = v!);
                }),
              ],
            ),
            const SizedBox(height: 24),
            // 완료 버튼 (오른쪽 정렬)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // 완료 버튼 동작 구현
                    // if(_contentCtrl.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(
                    final content = _contentCtrl.text.trim();
                    if(content.isEmpty || content.length < 30){ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('일기를 최소 30자 이상 입력해주세요.',)),
                    );
                      return;
                    }

                    // 일기생성시간안내 메세지 띄우기
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: 
                        Text('일기를 생성 중입니다. 2-3분 정도 소요될 수 있어요:D')),
                      );

                    
                    
                    // 저장
                    postImages.add(_image ?? XFile(''));
                    postTitles.add(_titleCtrl.text.trim());
                    postContents.add(_contentCtrl.text.trim());
                    postDateTimes.add(DateTime.now());

                    final newIndex =postContents.length-1;



                    Navigator.push(context,MaterialPageRoute(
                      builder: (context)=> const DetailPage(),
                      settings: RouteSettings(arguments:newIndex),
                    ));



                  },
                  child: const Text(
                    '완료',
                    style: TextStyle(
                      fontFamily: '온글잎 혜련',
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // const Text(
            //   '일기 생성은 2-3분 정도 소요될 수 있습니다.',
            //   style: TextStyle(
            //     color: Colors.grey,
            //     fontSize: 12,
            //   ),
            //   textAlign: TextAlign.center,
            // ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 2,
        onWillNavigate: (context, index) async {
          if (index != 2 && (_titleCtrl.text.isNotEmpty ||
              _contentCtrl.text.isNotEmpty || _image != null)) {
            return await showDiscardDialog(context);
          }
          return true;
        },
      ),
    );
  }
}

Widget _buildRadio(String label, String groupValue, ValueChanged<String?> onChanged) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Radio<String>(
        value: label,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: Colors.black87,
      ),
      Text(
        label,
        style: const TextStyle(
          fontFamily: '온글잎 혜련',
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    ],
  );
}
 