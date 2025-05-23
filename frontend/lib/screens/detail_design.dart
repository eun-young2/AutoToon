
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
    const diaryText = '이세상에 제일가는 말썽쟁이 짱구';

    return Scaffold(backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Auto Toon'),),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal:18, vertical: 10),
          child: Column(crossAxisAlignment:CrossAxisAlignment.start,children: [

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
          ],),
        ),
      ),

    );
  }
}
