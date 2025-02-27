import 'package:flutter/material.dart';
import 'create_test_page.dart';
import 'test_details_page.dart';
import 'setting_page.dart';

class HomeScreen extends StatefulWidget {
  final String userId; // إضافة userId كمعامل

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // تمرير userId إلى الصفحات الفرعية
    _pages = [
      CreateTestPage(userId: widget.userId), // صفحة إنشاء الاختبارات
      TestDetailsPage(userId: widget.userId), // صفحة تفاصيل الاختبارات
      SettingPage(userId: widget.userId), // صفحة الإعدادات
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Quiz Oluştur',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Quiz Detayları',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarları',
          ),
        ],
      ),
    );
  }
}
