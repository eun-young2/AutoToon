// 보류파일 입니다. 바탕화면에 종이질감 줄려고 텍스쳐 생성 해봤는데 별로라 일단 그냥 놔뒀어요.

import 'package:flutter/material.dart';

/// 자식 위젯 위에 반복되는 종이 질감 배경을 깔아주는 위젯
class TexturedBackground extends StatelessWidget {
  final Widget child;
  /// 질감 투명도 (0.0 ~ 1.0)
  final double opacity;
  /// 에셋 경로
  final String assetPath;

  const TexturedBackground({
    Key? key,
    required this.child,
    this.opacity = 1,
    this.assetPath = 'assets/textures/extracted_background_3.png',
  }) : super(key: key);
  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(assetPath),
          repeat: ImageRepeat.repeat,
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(opacity),
            BlendMode.dstATop,
          ),
        ),
      ),
      child: child,
    );
  }
}