import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:dx_project_dev2/widgets/sentiment_panel.dart';
import 'package:dx_project_dev2/widgets/alert_dialogs.dart';
import 'write_page.dart'; // postImages, postTitles, postContents, postDateTimes
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import '../widgets/double_back_to_exit.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  bool _statsExpanded = false;

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<int> get _postsForSelected {
    final selected = _selected ?? _focused;
    return List.generate(postDateTimes.length, (i) => i)
        .where((i) => isSameDay(postDateTimes[i], selected))
        .toList();
  }

  void _changeMonth(DateTime newFocused) {
    setState(() {
      _focused = newFocused;
      if (!isSameDay(_selected ?? _focused, newFocused)) {
        _selected = null;
      }
    });
  }

  /// 두 번째 클릭했을때 상세페이지로 넘어가야 하는데 넘어갈 페이지가 없을때 띄우는 창
  void _onDaySelected(DateTime day, DateTime focusedDay) {
    // 1) 재클릭인지 체크
    final wasAlreadySelected = _selected != null && isSameDay(_selected!, day);

    // 2) 상태 업데이트
    setState(() {
      _selected = day;
      _focused = focusedDay;
    });

    // 3) 재클릭 && 게시글 없음일 때만 얼럿 (추후 없을때를 else로 빼고 있을때를 추가해야함)
    if (wasAlreadySelected) {
      final posts = _postsForSelected; // 오늘 날짜에 해당하는 post 인덱스 리스트
      if (posts.isEmpty) {
        // 오늘인지 검사
        final isToday = isSameDay(day, DateTime.now());
        // 게시글 없을 때
        final tabController = DefaultTabController.of(context);
        CalendarAlertDialog.showRewardDialog(context,3,tabController,isToday,);
      } else {
        // 게시글이 있을 때: detail_page 로 인덱스 리스트 전달
        Navigator.pushNamed(
          context,
          '/detail',
          arguments: {
            'idx': posts.first,
            'reward': 0,   // 보상이 없으면 0
            'source': 'calendar',
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 시스템 상태바 높이
    final topPadding = MediaQuery.of(context).padding.top;
    // 앱바 높이
    const appBarHeight = kToolbarHeight;
    const bottomNavHeight = 0.0;

    // 전체 사용 가능한 높이(앱바·상태바 제외)
    final totalHeight = MediaQuery.of(context).size.height
        - topPadding
        - appBarHeight
        - bottomNavHeight;

    // 2) 달력 / 패널 비율
    final panelRatio = _statsExpanded ? 0.5 : 0.3;
    final calendarHeight = totalHeight * (1 - panelRatio);

// 3) 화면 크기에 따른 동적 그리드 높이 계산
    final daysOfWeekHeight = calendarHeight * 0.06;
    final rowHeight = (calendarHeight - daysOfWeekHeight) / 6.2;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                    color: Colors.black
                )
            ),
            IconButton(
              icon: const Icon(LineAwesomeIcons.calendar_check,
                  color: Colors.black),
              onPressed: () {
                final today = DateTime.now();
                setState(() {
                  _focused = today;
                  _selected = today;
                });
              },
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
body: DoubleBackToExit(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
        
              /// ─────────────────────────────────────────────
              // 년/월/일 조절 가능 창 띄우기
              GestureDetector(
                onTap: () {
                  picker.DatePicker.showDatePicker(
                    context,
                    showTitleActions: true,
                    currentTime: _focused,
                    minTime: DateTime(2000, 1, 1),
                    maxTime: DateTime(2100, 12, 31),
                    locale: picker.LocaleType.ko,
        
                    // 사용자가 스크롤할 때마다 date가 바뀝니다.
                    onChanged: (_) {},
                    onConfirm: (date) {
                      setState(() {
                        _changeMonth(date); // focused와 selected를 date 기준으로 업데이트
                        _selected = date;
                      });
                    },
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// ─────────────────────────────────────────────
                      // 큰 숫자 (일)
                      Text(
                        '${(_selected ?? _focused).day}',
                        style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM').format(_focused).toUpperCase(),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              /// ─────────────────────────────────────────────
              const SizedBox(height: 12),
        
              /// ─────────────────────────────────────────────
              // 달력 영역: height에 따라 축소/확대
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: calendarHeight,
                child: ClipRect( // overflow 방지
                  child: TableCalendar(
                    locale: 'ko_KR',
                    firstDay: DateTime.utc(2000),
                    lastDay: DateTime.utc(2100),
                    focusedDay: _focused,
                    headerVisible: false,
        
                    // 그리드 크기 지정: 요일 헤더와 각 행 높이 지정
                    daysOfWeekHeight: daysOfWeekHeight,
                    rowHeight: rowHeight,
        
                    // 요일 글씨 스타일
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                      weekendStyle: const TextStyle(
                        color: Color(0xFFE97B75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
        
                    // ② 다른 월 날짜 숨기기
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: true,
                      outsideDecoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      // defaultBuilder 쓰므로 장식은 Builders 로만 처리
                      defaultDecoration: BoxDecoration(),
                      weekendDecoration: BoxDecoration(),
                      todayDecoration: BoxDecoration(),
                      selectedDecoration: BoxDecoration(),
                    ),

                    // 달력 좌우로 스와이프하면 월 자동 바뀜
                    onPageChanged: (DateTime newFocused) {
                      _changeMonth(newFocused);
                    },
                    
                    // 셀 커스터마이징
                    calendarBuilders: CalendarBuilders(
                      dowBuilder: (context, day) =>
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade100),
                            color: Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            DateFormat.E('ko_KR').format(day),
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      defaultBuilder: (context, day, focusedDay) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade100),
                            color: Colors.white,
                          ),
                          child: Stack(
                            children: [
                              // 날짜 숫자: 왼쪽 상단
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              // 중앙의 이미지 자리(placeholder)
                              Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Container(
                                      // TODO: 실제 캐릭터 이미지로 교체
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      // 다른 월 날짜 셀 (숫자 숨김)
                      outsideBuilder: (context, day, focusedDay) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade100),
                            color: Colors.white,
                          ),
                        );
                      },
                      // todayBuilder / selectedBuilder 도 동일한 border + 배경 색만 다르게 추가하세요
                      // 오늘 강조도 원하시면 추가
                      todayBuilder: (ctx, day, focusedDay) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade100),
                            color: Colors.white,
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.redAccent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '${day.day}',
                                    style:
                                        DefaultTextStyle.of(context).style.copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
        
                      // ③ 선택해도 “흰 배경+테두리” 유지
                      selectedBuilder: (ctx, day, focusedDay) {
                        // ① 오늘인지 검사
                        final isToday = isSameDay(day, DateTime.now());
        
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            color: Colors.white,
                          ),
                          child: Stack(
                            children: [
                              if (isToday)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.redAccent, // 원 테두리 색
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      '${day.day}',
                                      style:
                                          DefaultTextStyle.of(context).style.copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                    ),
                                  ),
                                )
                              else
                                // ③ 오늘이 아니면 기본 숫자 표시
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Container(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onDaySelected: _onDaySelected,
                    selectedDayPredicate: (d) => isSameDay(d, _selected ?? _focused),
                  ),
                ),
              ),
              /// ─────────────────────────────────────────────
        
              /// ─────────────────────────────────────────────
              // 통계 영역
              Transform.translate(
                offset: const Offset(0, -100),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: SentimentPanel(
                    focused: _focused,
                    expanded: _statsExpanded,
                    onExpandChanged: (e) => setState(() => _statsExpanded = e),
                  ),
                ),
              ),
              /// ─────────────────────────────────────────────
            ],
          ),
        ),
      ),
    );
  }
}
