import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import 'package:dx_project_dev2/screens/write_page.dart'
    show postImages, postTitles, postContents, postDateTimes;
import 'package:intl/intl.dart';
import '../widgets/bottom_nav.dart';
import 'package:dx_project_dev2/theme/app_theme.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({Key? key}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {


    final idx = ModalRoute.of(context)!.settings.arguments as int;
    final imgFile = postImages[idx];
    final title = postTitles[idx];
    final content = postContents[idx];
    final dTime = postDateTimes[idx];


    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Auto Toon',style: TextStyle(fontFamily: '온글잎 혜련'),),
        
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 날짜 출력부
              Center(
                child: Text(
                  DateFormat('yyyy.MM.dd HH:mm').format(dTime),    
                  style: const TextStyle(
                    fontFamily: '온글잎 혜련',
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            

              // 이미지출력부 : padding 주고 비율 유지
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Image.file(
                  File(imgFile.path),                 
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  // fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 20.0),

              // 제목과 내용 (가운데)
             const  Center(
                child: Column(
                  children: [
                    Text(
                      'title',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    // 일기 출력부
                    Text(
                      // content,
                      '기능 입력 후 위의 주석을 해제합니다.',
                      style:  TextStyle(fontSize: 16, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              

            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}