import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(const ThreadsApp());

class ThreadsApp extends StatelessWidget {
  const ThreadsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, scaffoldBackgroundColor: Colors.white),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isVisible = true; // ใช้ควบคุมการแสดงผลของแถบเมนู

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ใช้ NotificationListener เพื่อดักจับการเลื่อน
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isVisible) setState(() => _isVisible = false); // เลื่อนลง -> ซ่อน
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isVisible) setState(() => _isVisible = true); // เลื่อนขึ้น -> แสดง
          }
          return true;
        },
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildSampleList("Home Feed"), // หน้าที่เลื่อนได้
            const Center(child: Text('Search')),
            const Center(child: Text('New Thread')),
            const Center(child: Text('Activity')),
            const Center(child: Text('Profile')),
          ],
        ),
      ),
      // ใช้ AnimatedContainer เพื่อทำ Effect เลื่อนเก็บ
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isVisible ? 80.0 : 0.0, // ปรับความสูงตามสถานะ
        child: Wrap( // ใช้ Wrap เพื่อป้องกัน Error เรื่อง Pixel เกินตอนความสูงเป็น 0
          children: [
            BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey.shade400,
              iconSize: 27, // เพิ่มจาก 28 เป็น 34 หรือตามที่คุณต้องการ
              
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Post'),
                BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Activity'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ตัวอย่างหน้า List ที่เลื่อนได้
  Widget _buildSampleList(String title) {
    return ListView.builder(
      itemCount: 50,
      itemBuilder: (context, index) => ListTile(
        title: Text("$title Item $index"),
      ),
    );
  }
}