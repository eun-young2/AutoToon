import 'dart:io';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../widgets/bottom_nav.dart';
import 'write_page.dart'; // postImages, postTitles, postContents, postDateTimes

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  bool _isMonthView = false;

  List<int> get _postsForSelected {
    final selected = _selected ?? _focused;
    return List.generate(postDateTimes.length, (i) => i)
        .where((i) => isSameDay(postDateTimes[i], selected))
        .toList();
  }

  void _toggleView(bool toMonth) {
    setState(() {
      _isMonthView = toMonth;
    });
  }

  void _adjustFocused(int offsetDays) {
    setState(() {
      _focused = _focused.add(Duration(days: offsetDays));
      _selected = _focused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final posts = _postsForSelected;
    final selectedDate = _selected ?? _focused;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
                'AutoToon',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            Text(
              DateFormat('yyyy.MM.dd').format(selectedDate),
              style: const TextStyle(color: Colors.black,fontSize: 15),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 게시글 목록
          Expanded(
            flex: 3,
            child: posts.isEmpty
                ? const Center(child: Text('해당 날짜에 작성된 게시글이 없습니다.'))
                : ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (_, idx) {
                      final i = posts[idx];
                      return ListTile(
                        leading: Image.file(
                          File(postImages[i].path),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(postTitles[i]),
                        subtitle:
                            Text(DateFormat('HH:mm').format(postDateTimes[i])),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/detail',
                          arguments: i,
                        ),
                      );
                    },
                  ),
          ),
          // 달력 컨테이너 (하단)
          GestureDetector(
            onVerticalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              if (v < 0 && !_isMonthView) {
                _toggleView(true);
              } else if (v > 0 && _isMonthView) {
                _toggleView(false);
              }
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  // 날짜 조정 Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () =>
                            _adjustFocused(_isMonthView ? -30 : -7),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _focused,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _focused = picked;
                              _selected = picked;
                            });
                          }
                        },
                        child: Text(
                          DateFormat('yyyy.MM').format(_focused),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () => _adjustFocused(_isMonthView ? 30 : 7),
                      ),
                      IconButton(
                          icon: const Icon(LineAwesomeIcons.calendar_check),
                          onPressed: () {
                            final today = DateTime.now();
                            setState(() {
                              _focused = today;
                              _selected = today;
                            });
                          }
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100, // 캘린더 전체 배경색
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TableCalendar(
                      locale: 'ko_KR',
                      firstDay: DateTime.utc(2000),
                      lastDay: DateTime.utc(2100),
                      focusedDay: _focused,
                      selectedDayPredicate: (d) => isSameDay(d, _selected),
                      calendarFormat: _isMonthView
                          ? CalendarFormat.month
                          : CalendarFormat.week,
                      headerVisible: false,
                      onDaySelected: (d, _) => setState(() {
                        _selected = d;
                        _focused = d;
                      }),
                      calendarStyle: CalendarStyle(
                        // 기본 평일 날짜
                        defaultDecoration: BoxDecoration(
                          shape: BoxShape.rectangle, // Modified: shape 통일
                          borderRadius: BorderRadius.circular(6),
                        ),

                        // 주말 날짜
                        weekendDecoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(6),
                        ),

                        // 오늘 날짜 배경을 #DFCFCF로 채움
                        todayDecoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: const Color(0xFFDFCFCF),
                          borderRadius: BorderRadius.circular(6),
                        ),

                        // 선택된 날짜는 배경 없이 테두리만 #DFCFCF로
                        selectedDecoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.transparent,
                          border: Border.all(
                              color: const Color(0xFFDFCFCF), width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        defaultTextStyle:
                            const TextStyle(color: Color(0xFFE97B75)),
                        weekendTextStyle:
                            const TextStyle(color: Color(0xFFE97B75)),
                        selectedTextStyle:
                            const TextStyle(color: Color(0xFFDFCFCF)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}
