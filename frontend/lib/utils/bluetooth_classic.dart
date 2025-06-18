import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothClassicHelper {
  /// 1. 블루투스가 켜져 있는지, 꺼져 있으면 켜달라고 요청
  static Future<bool> ensureEnabled(BuildContext ctx) async {
    final state = await FlutterBluetoothSerial.instance.state;
    if (state != BluetoothState.STATE_ON) {
      // 사용자에게 켜달라는 시스템 다이얼로그
      final enabled = await FlutterBluetoothSerial.instance.requestEnable();
      if (!enabled!) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('블루투스를 켜야 사용 가능합니다.')),
        );
      }
      return enabled;
    }
    return true;
  }

  /// 2. 페어링된 디바이스 중 이름에 'HC-06' 또는 Light/Lamp가 들어간 기기 리스트
  static Future<List<BluetoothDevice>> getPairedLights() async {
    final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    return devices.where((d) {
      final n = d.name?.toLowerCase() ?? '';
      return n.contains('hc-06') || n.contains('light') || n.contains('lamp');
    }).toList();
  }

  /// 3. RFCOMM 연결 & 바이트 전송
  static Future<bool> sendColor(
    BluetoothDevice device,
    int index,
  ) async {
    try {
      print('[BLE] 커넥션 시도');
      final conn = await BluetoothConnection.toAddress(device.address);
      print('[BLE] 커넥션 성공');

      // 전송
      // 아두이노는 문자 '1'~'5'로 받아야 하니까
      final asciiCode = (index + 1).toString().codeUnitAt(0);
      print('[BT] 문자 전송: ${String.fromCharCode(asciiCode)} (코드 $asciiCode)');
      conn.output.add(Uint8List.fromList([asciiCode]));
      await conn.output.allSent;
      print('[BLE] 데이터 송신 완료');

      await Future.delayed(const Duration(milliseconds: 300));
      await conn.close();
      print('[BT] 연결 해제 완료');
      return true;
    } catch (e) {
      print('[BT] 에러 발생: $e');
      return false;
    }
  }

  /// 4. 감정 태그 → RGB 매핑
  static int emotionTagToRgb(String tag) {
    switch (tag) {
      case 'joy':
        return 0;
      case 'sadness':
        return 1;
      case 'anger':
        return 2;
      case 'excitement':
        return 3;
      case 'calm':
        return 4;
      default:
        return 4;
    }
  }
}
