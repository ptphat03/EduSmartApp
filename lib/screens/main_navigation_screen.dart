import 'package:flutter/material.dart';
import 'tracking_board_screen.dart';
import 'schedule_screen_editable.dart';
import 'report_card_screen.dart';
import 'settings_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../services/premium_service.dart'; // ✅ import service

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TrackingBoardScreen(),
    EditableScheduleScreen(),
    ReportCardScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = [
    'Theo dõi hành trình',
    'Lịch học',
    'Bảng điểm',
    'Cài đặt',
  ];

  final List<IconData> _icons = [
    Icons.route,
    Icons.calendar_today,
    Icons.bar_chart,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(_titles[_currentIndex], _icons[_currentIndex]),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.blue[700],
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: (index) async {
          setState(() {
            _currentIndex = index;
          });
        },
        items: List.generate(
          _titles.length,
              (index) => BottomNavigationBarItem(
            icon: Icon(_icons[index]),
            label: _titles[index],
          ),
        ),
      ),
    );
  }
}
