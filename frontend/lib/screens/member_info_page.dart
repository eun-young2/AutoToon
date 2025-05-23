import 'package:flutter/material.dart';

class MemberInfoPage extends StatefulWidget {
  const MemberInfoPage({super.key});

  @override
  State<MemberInfoPage> createState() => _MemberInfoPageState();
}

class _MemberInfoPageState extends State<MemberInfoPage> {

  // 변하지 않는 회원 정보 (카카오톡에서 받아온 정보라고 가정)
  static const String phoneNumber = '010-1234-5678';
  static const String name = '홍길동';
  static const String gender = '남성';
  static const String country = '대한민국';
  static const String ageRange = '20~29';

  // 닉네임 입력 컨트롤러
  final TextEditingController _nicknameController = TextEditingController();

  // 닉네임 저장(전송) 상태
  bool _isSaving = false ;
  String? _saveMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  // 서버에 닉네임을 전송하는 함수( 실제 서버 연동 시 구현)
  Future <void> sendNicknameToServer(String nickname) async{
    setState(() {
      _isSaving = true;
      _saveMessage = null;
    });

    try {
      // 실제 서버 전송 코드 (http post/put) 작성 요
      await Future.delayed(const Duration(seconds: 1));//서버 통신대기 시뮬레이션

      // 성공시
      setState(() {_saveMessage='닉네임이 성공적으로 저장되었습니다';});

    }catch(e) {
      // 실패 시
      setState(() {_saveMessage='닉네임 저장에 실패했습니다.';});
    }finally{setState(() {_isSaving=false;});}
  }


  @override
  Widget build(BuildContext context) {return Scaffold(
    appBar: AppBar(title:const Text('회원정보'),centerTitle: true,),
    body:Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
        _infoRow('전화번호', phoneNumber),
        const SizedBox(height: 12),
        _infoRow('이름', name),
        const SizedBox(height: 12),
        _infoRow('성별', gender),
        const SizedBox(height: 12),
        _infoRow('국가', country),
        const SizedBox(height: 12),
        _infoRow('나이대', ageRange),

        const SizedBox(height: 24),
        const Text('닉네임',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
        const SizedBox(height: 8),
        TextField(controller: _nicknameController,decoration: const InputDecoration(border: OutlineInputBorder(),
          hintText: '닉네임을 적어주세요'),
          onChanged: (value){setState((){});},
        ),
        const SizedBox(height: 12,),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isSaving
                ? null
                : () {
                    final nickname = _nicknameController.text.trim();
                    if (nickname.isNotEmpty) {
                      sendNicknameToServer(nickname);
                    } else {
                      setState(() {
                        _saveMessage = '닉네임을 입력해주세요.';
                      });
                    }
                  },
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('닉네임 저장'),
          ),
        ),
        if (_saveMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _saveMessage!,
            style: TextStyle(
              color: _saveMessage == '닉네임이 성공적으로 저장되었습니다!'
                  ? Colors.green
                  : Colors.red,
            ),
          ),],


      ],),
    ),

  );}


  Widget _infoRow(String label, String value) { return Row(children: [
    SizedBox(
      width: 80,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: Text(
        value,
        style: const TextStyle(fontSize: 15),
      ),
    ),
  ],);}
}

