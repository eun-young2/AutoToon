import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dx_project_dev2/widgets/alert_dialogs.dart';
import 'package:dx_project_dev2/screens/write_page.dart'
    show WritePage, postContents, postDateTimes, postImages, postStyles;
import '../widgets/double_back_to_exit.dart';
import 'package:dx_project_dev2/utils/image_store.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dx_project_dev2/models/diary_model.dart';
import 'package:dx_project_dev2/services/api_service.dart';
import 'dart:typed_data';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';


/// ─────────────────────────────────────────────
class DetailPage extends StatefulWidget {
  final Diary diary;
  final String source;
  final int reward;

  const DetailPage({
    Key? key,
    required this.diary,
    required this.source,
    required this.reward,
  }) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

/// ─────────────────────────────────────────────
class _DetailPageState extends State<DetailPage> {
  bool _rewardShown = false; // 보상 다이얼로그를 이미 띄웠는지 여부

  @override
  void initState() {
    super.initState();
    _fetchDiary();
  }

  Diary? _diary;
  bool _loading = true;

  Future<void> _fetchDiary() async {
    final diary = await ApiService.readDiary(widget.diary.diaryNum);
    if (mounted) {
      setState(() {
        _diary = diary;
        _loading = false;
      });
    }
  }

  // 뒤로보내는 함수: source 에 따라 분기
  // void _popToSource(String source) {
  //   final userId = widget.diary.userId is int
  //     ? widget.diary.userId
  //     : int.tryParse(widget.diary.userId.toString()) ?? 0;
  //   switch (source) {
  //     case 'home':
  //       // 홈 화면으로 돌아가기
  //       Navigator.pushNamedAndRemoveUntil(
  //         context,
  //         '/main',
  //         (route) => false,
  //         arguments: {
  //           'userId': widget.diary.userId is int
  //               ? widget.diary.userId
  //               : int.tryParse(widget.diary.userId.toString()) ?? 0,
  //         },
  //       );
  //       break;
  //     case 'calendar':
  //       // 캘린더로 돌아가기
  //       Navigator.pushNamedAndRemoveUntil(
  //         context,
  //         '/history',
  //         (route) => false,
  //         arguments: {
  //           'userId': widget.diary.userId is int
  //               ? widget.diary.userId
  //               : int.tryParse(widget.diary.userId.toString()) ?? 0,
  //         },
  //       );
  //       break;
  //     case 'history':
  //       // 히스토리로 돌아가기
  //       Navigator.pushNamedAndRemoveUntil(
  //         context,
  //         '/history',
  //         (route) => false,
  //         arguments: {
  //           'userId': userId,
  //         },
  //       );
  //       break;
  //     default:
  //       // 그 외에 안전하게 홈으로
  //       Navigator.pushNamedAndRemoveUntil(
  //         context,
  //         '/main',
  //         (route) => false,
  //         arguments: {
  //           'userId': userId,
  //         },
  //       );
  //   }
  // }

  
  Future<bool> ensureBluetoothPermissions() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    // 필요하다면 advertise도 요청
    return scan.isGranted && connect.isGranted;
  }

  void tryConnectBluetooth() async {
    bool hasPermission = await ensureBluetoothPermissions();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('블루투스 스캔/연결 권한이 필요합니다!')),
      );
      return;
    }

    // 여기에 기존 BLE 연결 시도 코드 실행!
  }

  void _popToSource(String source) {
    switch (source) {
      case 'home':
      case 'calendar':
        // 홈/캘린더 탭으로 가야 할 때만 메인으로 가고, 탭 인덱스 같이 전달!
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
          (route) => false,
          arguments: {
            'userId': widget.diary.userId is int
                ? widget.diary.userId
                : int.tryParse(widget.diary.userId.toString()) ?? 0,
            'initialIndex': source == 'calendar' ? 1 : 0, // 예시: 0=home, 1=calendar
          },
        );
        break;
      case 'history':
      default:
        // 그냥 뒤로가기만 하면 됨 (pop!)
        Navigator.pop(context);
        break;
    }
  }
  /// TODO – 수정 페이지 이동(원하는 곳으로 push)
  /// “수정하기” 선택 시 호출되는 메서드
  void _editPost(int idx) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    final userId = prefs.getString('userId');

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    // 1) 서버에서 최신 사용자의 correction_tape_item 값을 조회
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://211.188.62.213:8000';
    final getUri = Uri.parse('$baseUrl/api/users/$userId');
    int serverTapeCount = 0;

    try {
      final getResponse = await http.get(getUri);
      if (getResponse.statusCode == 200) {
        final data = jsonDecode(getResponse.body);
        serverTapeCount = data['correction_tape_item'] ?? 0;
      } else {
        print(
          '수정테이프 조회 실패 (HTTP ${getResponse.statusCode}): ${getResponse.body}',
        );
        // 서버 오류이므로 안전하게 원래 WritePage로 바로 이동하거나 멈춤
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버에서 사용자 정보를 가져오지 못했습니다.')),
        );
        return;
      }
    } catch (e) {
      print('서버 호출 중 오류(조회): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
      return;
    }

    // 2) SharedPreferences에 저장된 lastEditDate 확인
    final storedDate = prefs.getString('lastEditDate');

    if (storedDate == todayKey) {
      // 오늘 이미 수정한 상태이므로, 수정테이프 사용 대화상자
      WriteLockDialogs.showUnlockEditDialog(
        context: context,
        onUnlock: () async {
          // 3) 서버에서 받아온 serverTapeCount 가 0 이하인지 확인
          if (serverTapeCount <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('수정테이프가 부족합니다.')),
            );
            return;
          }

          // 4) newCount = serverTapeCount - 1
          final newCount = serverTapeCount - 1;

          // 5) 로컬 SharedPreferences에도 차감된 값 저장
          await prefs.setInt('correctionTapeCount', newCount);

          // 6) 서버에 PATCH 요청: correction_tape_item = newCount
          final patchUri = Uri.parse('$baseUrl/api/users/$userId');
          try {
            final patchResponse = await http.patch(
              patchUri,
              headers: {
                'Content-Type': 'application/json',
                // 인증 헤더가 있다면 여기에 추가
              },
              body: jsonEncode({'correction_tape_item': newCount}),
            );
            if (patchResponse.statusCode == 200) {
              print('서버에 수정테이프 차감 완료: $newCount');
            } else {
              print(
                '서버 수정테이프 차감 실패 (HTTP ${patchResponse.statusCode}): ${patchResponse.body}',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('서버 업데이트가 실패했습니다.')),
              );
              return;
            }
          } catch (e) {
            print('서버 호출 중 오류(차감): $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
            );
            return;
          }

          // 7) 오늘 마지막 수정 날짜를 저장
          await prefs.setString('lastEditDate', todayKey);

          // 8) 진짜 수정 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>  WritePage(
                  userId: widget.diary.userId,      // 또는 적절한 userId
                  editIdx: widget.diary.diaryNum,   // ← 반드시 수정할 일기번호로!
                ),
                  // WritePage(userId: int.parse(userId!), editIdx: idx),
            ),
          ).then((_) {
            setState(() {}); // 돌아왔을 때 화면 갱신
          });
        },
      );
    } else {
      // 오늘 한 번도 수정 안 했으면 바로 수정 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WritePage(userId: int.parse(userId!), editIdx: idx),
        ),
      ).then((_) {
        setState(() {});
      });
    }
  }

  /// 같은 날짜(연·월·일)를 비교하기 위한 헬퍼
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 하드웨어 백버튼(시스템 뒤로가기) 콜백
  Future<bool> _onWillPop(String source) async {
    final validRoutes = ['main', 'calendar', 'history'];
    final route = validRoutes.contains(source) ? '/$source' : '/main';

    // 기존 popAndPushNamed 대신 pushReplacementNamed 또는 pushNamedAndRemoveUntil 사용
    Navigator.pushReplacementNamed(context, route);

    return true; // ✅ 시스템 pop 허용하여 화면 전환 정상 처리
  }

  // context: 스낵바 등 알림에 필요, imagePath: 저장할 이미지 경로(로컬 or URL)
  Future<void> saveImageToGallery(BuildContext context, String imagePath) async {
    try {
      // 1) 권한 체크
      // final status = await Permission.photos.request(); // iOS
      // final storage = await Permission.storage.request(); // Android

      // if (!status.isGranted && !storage.isGranted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('갤러리 접근 권한이 필요합니다!')),
      //   );
      //   return;
      // }

    // final storageStatus = await Permission.storage.request();

    // if (!storageStatus.isGranted) {
    //   // if (storageStatus.isPermanentlyDenied) {
    //     // 설정 앱으로 유도
    //     showDialog(
    //       context: context,
    //       builder: (_) => AlertDialog(
    //         title: const Text('권한 필요'),
    //         content: const Text('툰 이미지를 저장하려면 갤러리(사진) 접근 권한이 필요합니다.\n'
    //             '설정에서 권한을 허용해 주세요.'),
    //         actions: [
    //           TextButton(
    //             onPressed: () => Navigator.pop(context),
    //             child: const Text('취소'),
    //           ),
    //           TextButton(
    //             onPressed: () async {
    //               Navigator.pop(context);
    //               await openAppSettings();
    //             },
    //             child: const Text('설정으로 이동'),
    //           ),
    //         ],
    //       ),
    //     );
      // } else {
      //   // 일반 거부는 스낵바만
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('갤러리 접근 권한이 필요합니다!')),
      //   );
      // }
      // return;
    // }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final imagesPermission = await Permission.photos.request(); // or images.request()
        if (!imagesPermission.isGranted) {
          // 권한 안내 코드
          return;
        }
      } else {
        final storagePermission = await Permission.storage.request();
        if (!storagePermission.isGranted) {
          // 권한 안내 코드
          return;
        }
      }
    }

      Uint8List? bytes;

      // 2) 네트워크 이미지면 다운로드, 로컬 파일이면 읽기
      if (imagePath.startsWith('http')) {
        final response = await http.get(Uri.parse(imagePath));
        if (response.statusCode == 200) {
          bytes = response.bodyBytes;
        } else {
          throw Exception('이미지 다운로드 실패');
        }
      } else {
        final file = File(imagePath);
        bytes = await file.readAsBytes();
      }

      // 3) 저장
      final result = await ImageGallerySaverPlus.saveImage(
        bytes!,
        quality: 100,
        name: 'autotoon_${DateTime.now().millisecondsSinceEpoch}',
      );

      if ((result['isSuccess'] ?? false) == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지가 갤러리에 저장되었습니다!')),
        );
      } else {
        throw Exception('갤러리 저장 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  /// ───────────────── UI ──────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading || _diary == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final diary = _diary!;
    final reward = widget.reward;
    final source = widget.source;

    // 신규 작성(reward==true)이면, 이 화면 빌드 직후 다이얼로그 띄우기
    if (!_rewardShown && reward > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DiaryRewardDialog.showDiaryRewardDialog(context, reward);
        setState(() {
          _rewardShown = true;
        });
      });
    }

    // 우선 이 idx로부터 해당 게시글의 날짜를 구한다.
    // final DateTime baseDate = postDateTimes[idx];
    final DateTime baseDate = diary.diaryDate;
    const styleKo = {2: '일러스트', 4: '캐릭터'};

    // 5) 정상적인 경우 (하나 이상의 게시글이 있을 때)
    return WillPopScope(
      onWillPop: () => _onWillPop(source),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Auto Toon'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _popToSource(source),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),

        /// ─────────────────────────────────────────────
        body: DoubleBackToExit(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(baseDate),
                    style: const TextStyle(
                      fontFamily: '온글잎 혜련',
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            styleKo[diary.styleId] ?? '캐릭터',
                            style: const TextStyle(
                              fontFamily: '온글잎 혜련',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black26,
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            color: const Color(0xFFF5F5F5),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/main',
                                  arguments: {
                                    'userId': widget.diary.userId is int
                                        ? widget.diary.userId
                                        : int.tryParse(widget.diary.userId.toString()) ?? 0,
                                    'initialIndex': 2, // Write 탭으로 이동
                                    'editDiaryNum': widget.diary.diaryNum,
                                  },
                                );
                              } else if (value == 'delete') {
                                  // 정말 삭제할지 한번 더 물어보는 다이얼로그
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('일기 삭제'),
                                      content: const Text('정말로 이 일기를 삭제하시겠습니까? 복구할 수 없습니다.'),
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
                                  if (ok != true) return;
                                  try {
                                    await ApiService.deleteDiary(widget.diary.diaryNum);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('일기가 삭제되었습니다')));
                                    // 소스별로 돌아가기
                                    _popToSource(widget.source);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('삭제에 실패했습니다: $e')));
                                  }
                                } else if (value == 'store') {
                                  final path = diary.mergedPath ?? '';
                                  if (path.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('저장할 이미지가 없습니다')));
                                    return;
                                  }
                                  // 네트워크면 절대주소로 변환
                                  final uri = Uri.tryParse(path);
                                  String imagePath = path;
                                  if (!(uri != null && (uri.scheme == 'http' || uri.scheme == 'https'))) {
                                    imagePath = ApiService.fullImageUrl(path);
                                  }
                                  await saveImageToGallery(context, imagePath);
                                } else if (value == 'export') {
                                  // final tag = diary.emotionTag!;
                                  // print('[DEBUG] emotionTag: $tag');
                                  // await DetailAlertDialogs.showEmotionLightDialog(
                                  //   context: context,
                                  //   emotionTag: tag,
                                  // );
                                  // 권한 체크
                                  bool hasPermission = await ensureBluetoothPermissions();
                                  if (!hasPermission) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('블루투스 권한이 필요합니다!')),
                                    );
                                    return;
                                  }
                                  final tag = diary.emotionTag!;
                                  await DetailAlertDialogs.showEmotionLightDialog(
                                    context: context,
                                    emotionTag: tag,
                                  );
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('수정하기')),
                              PopupMenuItem(
                                  value: 'delete', child: Text('삭제하기')),
                              PopupMenuItem(
                                  value: 'store', child: Text('툰 저장하기')),
                              PopupMenuItem(value: 'export', child: Text('감정 색칠하기')),
                            ],
                            icon: const Icon(Icons.more_vert,
                                color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    if (diary.mergedPath != null &&
                        diary.mergedPath!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildMergedImage(diary.mergedPath!),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        diary.content,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Divider(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMergedImage(String path) {
    // path가 http/https로 시작하면 네트워크 URL로 처리
    final uri = Uri.tryParse(path);
    final isNet =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    // 만약 http/https가 아니면, 서버의 상대 경로이거나 로컬 파일일 수 있음

    // 로컬 파일이 실제로 존재하는지 확인
    final file = File(path);
    final isLocalFile = file.existsSync();

    if (isNet) {
      // 완전한 네트워크 URL
      return Image.network(
        path,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const ColoredBox(color: Colors.grey, child: SizedBox(height: 160)),
      );
    } else if (isLocalFile) {
      // 로컬 파일
      return Image.file(
        file,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const ColoredBox(color: Colors.grey, child: SizedBox(height: 160)),
      );
    } else {
      // 서버 상대경로: ApiService.fullImageUrl로 변환
      final url = ApiService.fullImageUrl(path);
      return Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const ColoredBox(color: Colors.grey, child: SizedBox(height: 160)),
      );
    }
  }
}
