import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/club_service.dart';
import '../../repoisitory/secure_storage.dart';

class AdminSettingsPage extends ConsumerWidget {
  final int clubId;
  const AdminSettingsPage({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // storage를 Riverpod에서 가져옴
    final storage = ref.read(secureStorageProvider);
    final clubService = ClubService(storage);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '모임 설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // 제목을 중앙으로 정렬
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SettingsButton(
              text: '멤버 조회',
              onPressed: () => context.push(
                '/clubs/$clubId/setting/members',
                extra: {'clubId': clubId, 'isAdmin': true}
              )
            ),
            SettingsButton(
              text: '모임 및 관리자 변경',
              onPressed: () => context.push('/clubs/$clubId/setting/edit')
            ),
            SettingsButton(
              text: '모임 삭제하기',
              textColor: Colors.red,
              onPressed: () async {
                _showDeleteConfirmationDialog(context, clubService, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 모임 삭제 확인 다이얼로그
  void _showDeleteConfirmationDialog(BuildContext context, ClubService clubService, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('모임 삭제'),
          content: const Text('정말로 모임을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                context.pop(); // 다이얼로그 닫기
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await clubService.deleteClub(clubId); // 모임 삭제 API 호출
                  context.go('/clubs?refresh=${DateTime.now().millisecondsSinceEpoch}');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모임이 삭제되었습니다.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모임 삭제에 실패했습니다. 다시 시도해주세요.')),
                  );
                }
              },
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SettingsButton extends StatelessWidget {
  final String text;
  final Color textColor;
  final VoidCallback onPressed;

  const SettingsButton({super.key, 
    required this.text,
    required this.onPressed,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 버튼 간 여백
      child: SizedBox(
        width: double.infinity, // 버튼이 화면 너비를 가득 차지
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200], // 버튼 배경색
            elevation: 0, // 그림자 제거
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // 내부 여백 설정
          ),
          onPressed: onPressed,
          child: Align(
            alignment: Alignment.centerLeft, // 텍스트를 버튼 왼쪽 정렬
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
