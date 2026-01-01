import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const SMSApp());

class SMSApp extends StatelessWidget {
  const SMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.ibmPlexSansThaiTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: GoogleFonts.ibmPlexSansThai(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
  final Telephony telephony = Telephony.instance;
  List<SmsMessage> allMessages = [];
  List<SmsMessage> moneyMessages = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _setupSmsListener();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      _loadMessages();
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ต้องการสิทธิ์ SMS',
          style: GoogleFonts.ibmPlexSansThai(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'แอปต้องการสิทธิ์เข้าถึง SMS เพื่ออ่านข้อความแจ้งเตือน',
          style: GoogleFonts.ibmPlexSansThai(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.ibmPlexSansThai()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('ตั้งค่า', style: GoogleFonts.ibmPlexSansThai()),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMessages() async {
    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    setState(() {
      allMessages = messages;
      moneyMessages = messages.where((msg) => _isMoneyMessage(msg.body ?? '')).toList();
    });
  }

  void _setupSmsListener() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        setState(() {
          allMessages.insert(0, message);
          if (_isMoneyMessage(message.body ?? '')) {
            moneyMessages.insert(0, message);
          }
        });
      },
      listenInBackground: false,
    );
  }

  bool _isMoneyMessage(String body) {
    final moneyKeywords = [
      'เงินเข้า',
      'โอนเข้า',
      'ฝากเงิน',
      'ยอดเงิน',
      'บาท',
      'THB',
      'เครดิต',
      'deposit',
      'transfer',
      'received',
      'บัญชี',
    ];
    
    return moneyKeywords.any((keyword) => 
      body.toLowerCase().contains(keyword.toLowerCase())
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildAllNotifications(),
          _buildMoneyNotifications(),
          Center(
            child: Text(
              'สร้างข้อความใหม่',
              style: GoogleFonts.ibmPlexSansThai(fontSize: 18),
            ),
          ),
          Center(
            child: Text(
              'กิจกรรม',
              style: GoogleFonts.ibmPlexSansThai(fontSize: 18),
            ),
          ),
          Center(
            child: Text(
              'โปรไฟล์',
              style: GoogleFonts.ibmPlexSansThai(fontSize: 18),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color.fromARGB(179, 173, 173, 173),
        selectedLabelStyle: GoogleFonts.ibmPlexSansThai(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.ibmPlexSansThai(fontSize: 12),
        iconSize: 28,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'ทั้งหมด',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'เงินเข้า',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'สร้าง',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'กิจกรรม',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }

  Widget _buildAllNotifications() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'แจ้งเตือนทั้งหมด',
          style: GoogleFonts.ibmPlexSansThai(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: allMessages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.message_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีข้อความ',
                    style: GoogleFonts.ibmPlexSansThai(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: allMessages.length,
              itemBuilder: (context, index) {
                final message = allMessages[index];
                return _buildMessageCard(message);
              },
            ),
    );
  }

  Widget _buildMoneyNotifications() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'แจ้งเตือนเงินเข้า',
          style: GoogleFonts.ibmPlexSansThai(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: moneyMessages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีการแจ้งเตือนเงินเข้า',
                    style: GoogleFonts.ibmPlexSansThai(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: moneyMessages.length,
              itemBuilder: (context, index) {
                final message = moneyMessages[index];
                return _buildMessageCard(message, isMoneyMessage: true);
              },
            ),
    );
  }

  Widget _buildMessageCard(SmsMessage message, {bool isMoneyMessage = false}) {
    final date = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: isMoneyMessage ? Colors.green : Colors.blue,
          child: Icon(
            isMoneyMessage ? Icons.attach_money : Icons.message,
            color: Colors.white,
          ),
        ),
        title: Text(
          message.address ?? 'ไม่ทราบผู้ส่ง',
          style: GoogleFonts.ibmPlexSansThai(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message.body ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ibmPlexSansThai(),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(date),
              style: GoogleFonts.ibmPlexSansThai(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: () => _showMessageDetail(message),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} นาทีที่แล้ว';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} ชั่วโมงที่แล้ว';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} วันที่แล้ว';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showMessageDetail(SmsMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          message.address ?? 'ไม่ทราบผู้ส่ง',
          style: GoogleFonts.ibmPlexSansThai(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            message.body ?? '',
            style: GoogleFonts.ibmPlexSansThai(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด', style: GoogleFonts.ibmPlexSansThai()),
          ),
        ],
      ),
    );
  }
}