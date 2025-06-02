import 'dart:io';
import 'package:flutter/material.dart';

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