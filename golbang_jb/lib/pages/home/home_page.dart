import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/models/club.dart';
import 'package:golbang/models/user_account.dart';
import 'package:golbang/models/get_statistics_overall.dart';
import 'package:golbang/pages/setting/setting_page.dart';
import 'package:golbang/services/event_service.dart';
import 'package:golbang/utils/reponsive_utils.dart';
import 'package:golbang/widgets/sections/bookmark_section.dart';
import 'package:golbang/widgets/sections/groups_section.dart';
import 'package:golbang/widgets/common/section_with_scroll.dart';
import 'package:golbang/widgets/sections/upcoming_events.dart';
import 'package:golbang/pages/event/event_main.dart';
import 'package:golbang/pages/club/club_main.dart';
import 'package:golbang/pages/profile/profile_screen.dart';
import 'package:golbang/services/group_service.dart';
import 'package:golbang/services/user_service.dart';
import 'package:golbang/services/statistics_service.dart';
import '../../repoisitory/secure_storage.dart';

import 'package:golbang/pages/notification/notification_history_page.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = Get.arguments?['initialIndex'] ?? 0;
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeContent(),
    const EventPage(),
    const ClubMainPage(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    Orientation orientation = MediaQuery.of(context).orientation;
    double appBarSize = ResponsiveUtils.getAppBarHeight(screenWidth, orientation);
    double appBarIconSize = ResponsiveUtils.getAppBarIconSize(screenWidth, orientation);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Image.asset(
          'assets/images/text-logo-green.webp', // 텍스트 로고 이미지 경로
          height: appBarSize, // 이미지 높이 조정
          fit: BoxFit.contain, // 이미지 비율 유지
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.black, size:appBarIconSize),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationHistoryPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.black, size:appBarIconSize),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()), // SettingsPage로 이동
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note),
              label: '일정',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded),
              label: '모임',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: '내 정보',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  // Fetching services
  late final UserService userService;
  late final GroupService groupService;
  late final EventService eventService;
  late final StatisticsService statisticsService;

  late String date;
  late Future<List<dynamic>> _dataFuture;
  late List<Event> _events;

  Future<List<dynamic>> _loadData() {
    return Future.wait([
      userService.getUserInfo(),
      eventService.getEventsForMonth(date: date),
      groupService.getUserGroups(),
      statisticsService.fetchOverallStatistics().catchError((e) {
        log('Error fetching overall statistics: $e');
        return OverallStatistics(
          averageScore: 0.0,
          bestScore: 0,
          handicapBestScore: 0,
          gamesPlayed: 0,
        );
      }),
    ]);
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  Future<void> _loadEventsForMonth() async {

    try {
      List<Event> events = await eventService.getEventsForMonth(date: date);
      setState(() {
        _events = events;
      });
    } catch (e) {
      log("Error loading events: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    final storage = ref.read(secureStorageProvider);
    userService = UserService(storage);
    groupService = GroupService(storage);
    eventService = EventService(storage);
    statisticsService = StatisticsService(storage);

    final DateTime focusedDay = DateTime.now();
    date = '${focusedDay.year}-${focusedDay.month.toString().padLeft(2, '0')}-01';

    _dataFuture = _loadData();
  }


  @override
  Widget build(BuildContext context) {

    // 화면 크기 설정
    double screenHeight = MediaQuery.of(context).size.height; // 화면 높이
    Orientation orientation = MediaQuery.of(context).orientation;
    double bookmarkSectionHeight = orientation == Orientation.landscape ? screenHeight * 0.15 : screenHeight * 0.15;

    return Scaffold(
      body: FutureBuilder(
          future: _dataFuture,
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No data available'));
            }
            // 데이터 추출
            UserAccount userAccount = snapshot.data![0];
            List<Event> events = snapshot.data![1];
            events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
            List<Club> clubs = snapshot.data![2];
            OverallStatistics overallStatistics = snapshot.data![3] ?? OverallStatistics(
              averageScore: 0.0,
              bestScore: 0,
              handicapBestScore: 0,
              gamesPlayed: 0,
            );

            // UpcomingEvents 위젯의 필터링 로직과 동일하게 개수 계산
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final upcomingEventsCount = events.where((event) {
              final eventDay = DateTime(event.startDateTime.year, event.startDateTime.month, event.startDateTime.day);
              return !eventDay.isBefore(today); // 오늘 이전은 제외, 오늘 포함
            }).length;

            return Column(
              children: <Widget>[
                SizedBox(
                  height: bookmarkSectionHeight,
                  child: SectionWithScroll(
                    title: '대시보드',
                    child: BookmarkSection(
                      userAccount: userAccount,
                      overallStatistics: overallStatistics, // Pass overall statistics
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: SectionWithScroll(
                    title: '다가오는 일정 $upcomingEventsCount',
                    child: UpcomingEvents(
                        events: events, // 필터링하지 않은 전체 리스트 전달
                        date: date,
                        onEventUpdated: () async {
                          await _refreshData(); // 데이터 다시 로드
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: screenHeight * 0.18,
                  child: SectionWithScroll(
                    title: '내 모임 ${clubs.length}',
                    child: GroupsSection(clubs: clubs),
                  ),
                ),
              ],
            );
          }

      ),
    );
  }
}