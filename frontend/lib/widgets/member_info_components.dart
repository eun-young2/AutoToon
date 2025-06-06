import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'chat_bubble.dart';  // TooltipBubble, _BubblePainter import

/// ───────────── 프로필 헤더 ─────────────
class ProfileHeader extends StatelessWidget {
  final File? imageFile;
  final String nickname;
  final VoidCallback onImageTap;
  final VoidCallback onEditNickname;
  final VoidCallback onDetailTap;

  const ProfileHeader({
    Key? key,
    required this.imageFile,
    required this.nickname,
    required this.onImageTap,
    required this.onEditNickname,
    required this.onDetailTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onImageTap,
          child: CircleAvatar(
            radius: 40,
            backgroundImage: imageFile != null
                ? FileImage(imageFile!) as ImageProvider
                : const AssetImage('assets/images/GodFaker.jpg'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '$nickname님 환영합니다',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEditNickname,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 28),
                onPressed: onDetailTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ───────────── 크레딧 박스 ─────────────
class CreditBox extends StatelessWidget {
  final int credit;
  const CreditBox({Key? key, required this.credit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('크레딧', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/credit.png', width: 20, height: 20),
            const SizedBox(width: 4),
            Text('$credit',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

/// ───────────── 인포 박스(성별·나이대 등) ─────────────
class InfoBox extends StatelessWidget {
  final String title;
  final String value;
  const InfoBox({Key? key, required this.title, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// ───────────── 아이템 카드 ─────────────
class ItemCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final int price;
  final VoidCallback? onTap;

  const ItemCard({
    Key? key,
    required this.imagePath,
    required this.label,
    required this.price,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(imagePath, width: 48, height: 48),
          const SizedBox(height: 4),
          Text(label),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/credit.png', width: 16, height: 16),
              const SizedBox(width: 4),
              Text('$price',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

/// ───────────── 캐릭터(오브제) 카드 ─────────────
class CharacterCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final String count;
  const CharacterCard({
    Key? key,
    required this.imagePath,
    required this.label,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text(count, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

/// ───────────── AppBar 아이템 보유 수량 ─────────────
class ItemCountIcon extends StatelessWidget {
  final String imagePath;
  final int count;
  const ItemCountIcon({Key? key, required this.imagePath, required this.count})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(imagePath, width: 24, height: 24),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// ────────────────────────────────────────────────────
/// FrameoLauncher: “액자 앱(Frameo) 실행/설치” 버튼 위젯
///
/// * 아이콘(Icons.filter_frames_sharp)만 누르면
///   1) 설치되어 있으면 바로 앱 실행
///   2) 설치되어 있지 않으면 Play Store 또는 App Store 로 이동
/// * “페이지가 열릴 때” 한 번만 말풍선 툴팁을 띄우는 로직
/// * 말풍선에서 “×”를 누르면 닫히고, “다시 보지 않기”를 누르면
/// SharedPreferences에 플래그를 남겨 다음 번엔 뜨지 않습니다.
/// ────────────────────────────────────────────────────
class FrameoLauncher extends StatefulWidget {
  const FrameoLauncher({Key? key}) : super(key: key);

  @override
  State<FrameoLauncher> createState() => _FrameoLauncherState();
}

class _FrameoLauncherState extends State<FrameoLauncher> {
  bool _skipTooltip = false;                    // SharedPreferences에서 가져온 “다시 보지 않기” 플래그
  OverlayEntry? _overlayEntry;                  // 말풍선 OverlayEntry
  final GlobalKey _frameoIconKey = GlobalKey(); // 이 FrameoLauncher 위젯의 키

  @override
  void initState() {
    super.initState();
    _loadSkipFlag().then((_) {
      // “페이지가 열리고 위젯이 완전히 마운트된 이후” 한 번만 툴팁을 띄움
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_skipTooltip) {
          _showTooltip();
        }
      });
    });
  }

  // SharedPreferences에서 “마지막으로 다시보지않기 누른 시각”을 읽어와서
  // 현재로부터 7일(=168시간) 이내면 _skipTooltip=true, 아니면 false로 설정
  Future<void> _loadSkipFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIso = prefs.getString('skipFrameoTooltipDate');
    if (savedIso != null) {
      try {
        final lastDismiss = DateTime.parse(savedIso);
        final now = DateTime.now();
        final diff = now.difference(lastDismiss);
        if (diff.inHours < 24 * 7) {
          // 7일 이내
          _skipTooltip = true;
        } else {
          // 7일 경과 → 다시 툴팁 띄우기
          _skipTooltip = false;
        }
      } catch (_) {
        // 파싱 에러가 나거나 이상한 값이라면, 다시 툴팁 띄우도록
        _skipTooltip = false;
      }
    } else {
      // 저장된 값이 없으면, 당연히 툴팁 띄워야 함
      _skipTooltip = false;
    }
    setState(() {}); // 상태 업데이트
  }

  /// 현재 시각을 “마지막 다시보지않기 누른 시각”으로 저장
  Future<void> _saveSkipDate() async {
    final prefs = await SharedPreferences.getInstance();
    // 현재의 ISO8601 문자열을 저장
    await prefs.setString('skipFrameoTooltipDate', DateTime.now().toIso8601String());
  }

  /// “앱 실행/설치” 버튼 누를 때 호출
  Future<void> _onPressed() async {
    const androidIntentUri = 'intent://#Intent;package=net.frameo.app;end';
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=net.frameo.app&hl=ko';
    const iosAppStoreUrl = 'https://apps.apple.com/kr/app/frameo/id1179744119';

    // 1) 현재 플랫폼 확인
    final deviceInfo = DeviceInfoPlugin();
    final info = await deviceInfo.deviceInfo;
    final isAndroid = info.data['platform'] == 'android' || Platform.isAndroid;
    final isIOS = info.data['platform'] == 'ios' || Platform.isIOS;

    if (isAndroid) {
      // 2) Android: Intent URI 로 앱 실행 시도
      final intentUri = Uri.parse(androidIntentUri);
      bool launched = false;
      try {
        launched = await launchUrl(
          intentUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        // 3) 설치 안 되어 있거나 실행 실패 시
        if (!_skipTooltip) {
          _showTooltip();
        }
        // Play Store 열기
        final Uri storeUri = Uri.parse(playStoreUrl);
        if (await canLaunchUrl(storeUri)) {
          await launchUrl(storeUri, mode: LaunchMode.externalApplication);
        }
      }
    } else if (isIOS) {
      // 4) iOS: 바로 App Store 링크 열기
      final Uri storeUri = Uri.parse(iosAppStoreUrl);
      if (await canLaunchUrl(storeUri)) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      }
    } else {
      // 5) 웹/기타 플랫폼: 그냥 Play Store 웹페이지 열기
      final Uri storeUri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(storeUri)) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// 말풍선 툴팁 띄우기
  void _showTooltip() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    // 이미 떠 있다면 지우기
    _removeTooltip();

    // 아이콘 위치 계산
    final renderBox =
    _frameoIconKey.currentContext!.findRenderObject() as RenderBox;
    final iconSize = renderBox.size;
    final iconPos = renderBox.localToGlobal(Offset.zero);

    // 화면 너비/높이
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // ① 메시지와 버튼, 아이콘까지 한 줄에 들어갈 수 있도록 넉넉한 가로 너비 계산
    const paddingHorizontal = 12.0; // 좌우 전체 padding
    const fontSize = 14.0;
    const btnSpacing = 8.0;   // 버튼들 사이 간격

    // “나만의 액자를 꾸며보세요” 너비
    final msg = '나만의 액자를 꾸며보세요';
    final msgWidth = msg.length * fontSize * 0.8;

    // “다시 보지 않기” 버튼 너비 (텍스트 길이 * fontSize * 0.6)
    final btnText = '/ 다시 보지 않기';
    final btnTextWidth = btnText.length * fontSize * 0.5;

    // “×” 아이콘 너비 + 간격
    const closeIconWidth = 8.0;

    // 전체 컨텐츠 너비 = 좌우 padding + 메시지 + 버튼 + 아이콘 + 각 요소 간 간격
    double totalContentWidth = paddingHorizontal +
        msgWidth +
        btnSpacing +
        btnTextWidth +
        btnSpacing +
        closeIconWidth;

    // 말풍선 최소/최대 너비 제한
    final tooltipW = totalContentWidth.clamp(120.0, screenWidth - 16);

    // ② 텍스트 높이 + 버튼 높이 + 꼬리 높이를 고려한 세로 높이 계산
    const textHeight = fontSize;
    const tailHeight = 1.0;
    // 버튼(텍스트버튼+아이콘)은 약 18~20 높이 잡고, 전체 패딩 포함
    const tooltipH = textHeight + 8.0 /*행 사이 간격*/
        + 20.0 /*버튼 영역*/
        + tailHeight
        + 5.0 /*위아래 여백*/;

    // X 좌표: 아이콘 중앙 기준으로, 말풍선을 넉넉히 해서 아이콘 중앙이 항상 말풍선 안에 들어오도록
    double dx = (iconPos.dx + iconSize.width / 2) - (tooltipW / 2);
    dx = dx.clamp(8.0, screenWidth - tooltipW - 8.0);

    // Y 좌표: 아이콘 바로 아래에 8px 간격
    double dy = iconPos.dy + iconSize.height - tailHeight;
    dy = dy.clamp(8.0, screenHeight - tooltipH - 8.0);

    // ─────────────────────────────────────────────
    // ⑥ 꼬리 중심 X 위치 계산 (말풍선 내부 좌측 경계(dx)로부터 아이콘 중심까지 거리)
    final double iconCenterX = iconPos.dx + iconSize.width / 2;
    const double tailWidth = 20.0;

    // 아이콘 중심과 말풍선 왼쪽(dx) 차이 → 말풍선 내부에서 꼬리 위치.
    double tailCenterX = iconCenterX - dx;

    // 꼬리 폭(tailWidth)의 절반만큼 여유 두고, 말풍선 경계를 벗어나지 않도록 제한
    tailCenterX = tailCenterX.clamp(tailWidth / 2, tooltipW - tailWidth / 2);

    // ─────────────────────────────────────────────
    // ⑤ OverlayEntry 삽입
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: dx,
          top: dy,
          width: tooltipW,
          height: tooltipH,
          child: Material(
            color: Colors.transparent,
            child: TooltipBubble(
              tailCenterX: tailCenterX,
              onClose: _removeTooltip,
              onDoNotShowAgain: () async {
                // “다시 보지 않기” 누르면 현재 시각 저장 → 다음 7일간 뜨지 않음
                await _saveSkipDate();
                setState(() {
                  _skipTooltip = true;
                });
                _removeTooltip();
              },
              message: msg,
              messageNshow:btnText,
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  /// 툴팁 제거
  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: _frameoIconKey,
      icon: const Icon(
        Icons.filter_frames_rounded,
        size: 24,
        color: Colors.black54,
      ),
      onPressed: _onPressed,
    );
  }
}