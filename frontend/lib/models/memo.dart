import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailDesign extends StatelessWidget {
  // final String diaryText; // 일기쓰기페이지에서 전달받은 일기텍스트
  // final List<String> imagePaths; // 일기웹툰 이미지 경로 리스트
  const DetailDesign({Key? key}) : super(key: key);
  // const DetailDesign({super.key,required this.diaryText, required this.imagePaths,});

  // final String diaryText;
  @override
  Widget build(BuildContext context) {

    final now = DateTime.now();
    final dateString = DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(now);
    const diaryText = '이 세상에 제일 가는 말썽쟁이 짱구';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Auto Toon'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) async {
              if (value == 'edit') {
                // 수정 기능: 예시로 로그 출력
                debugPrint('수정하기 선택됨');
                // TODO: 수정 페이지로 이동하도록 구현
              } else if (value == 'delete') {
                // 삭제 기능: 확인 다이얼로그 후 pop
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('삭제 확인'),
                    content: const Text('정말로 이 글을 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  // 실제 삭제 로직을 여기에 작성
                  Navigator.of(context).pop(); // 뒤로 가기
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('수정하기'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('삭제하기'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal:18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 날짜 출력부
              Center(
                child: Text(
                  dateString,
                  style: const TextStyle(
                    fontFamily: '온글잎 혜련',
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              //이미지출력부
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                child: Image.asset('assets/images/diary.png',width:double.infinity,fit:BoxFit.cover,),
              ),
              const SizedBox(height: 20.0,),

              // 일기텍스트 출력부
              const Padding(
                  padding:  EdgeInsets.symmetric(horizontal:30.0),
                  // child: Text(diaryText,style: const TextStyle(fontSize: 16),)
                  child: Text(diaryText,style:  TextStyle(fontSize: 16),)
              ),

              const SizedBox(height: 20,),
            ],
          ),
        ),
      ),
    );
  }
}