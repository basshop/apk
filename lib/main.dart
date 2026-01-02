import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class SmsMessage {
  final String address;
  final String body;
  final int date;

  SmsMessage({
    required this.address,
    required this.body,
    required this.date,
  });

  factory SmsMessage.fromMap(Map<dynamic, dynamic> map) {
    return SmsMessage(
      address: map['address']?.toString() ?? 'Unknown',
      body: map['body']?.toString() ?? '',
      date: int.tryParse(map['date']?.toString() ?? '0') ?? 0,
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
  List<SmsMessage> allMessages = [];
  List<SmsMessage> moneyMessages = [];
  bool isLoading = false;
  
  static const platform = MethodChannel('com.smsapp/sms');

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      final smsStatus = await Permission.sms.request();
      
      if (smsStatus.isGranted) {
        await _loadMessages();
      } else if (smsStatus.isPermanentlyDenied) {
        if (mounted) _showPermissionDialog();
      } else {
        if (mounted) _showPermissionDeniedSnackbar();
      }
    } catch (e) {
      debugPrint('Permission error: $e');
      if (mounted) _showErrorSnackbar('เกิดข้อผิดพลาดในการขอสิทธิ์');
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

  void _showPermissionDeniedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'กรุณาอนุญาตสิทธิ์ SMS เพื่อใช้งานแอป',
          style: GoogleFonts.ibmPlexSansThai(),
        ),
        action: SnackBarAction(
          label: 'ตั้งค่า',
          onPressed: () => _requestPermissions(),
        ),
      ),
    );
  }

  Future<void> _loadMessages() async {
    if (isLoading) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      final status = await Permission.sms.status;
      if (!status.isGranted) {
        if (mounted) {
          _showErrorSnackbar('กรุณาอนุญาตสิทธิ์ SMS ก่อน');
        }
        return;
      }

      final List<dynamic> messages = await platform.invokeMethod('getInboxSms');
      
      if (mounted) {
        setState(() {
          allMessages = messages.map((msg) => SmsMessage.fromMap(msg)).toList();
          allMessages.sort((a, b) => b.date.compareTo(a.date));
          moneyMessages = allMessages
              .where((msg) => _isMoneyMessage(msg.body))
              .toList();
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get SMS: ${e.message}");
      if (mounted) {
        _showErrorSnackbar('ไม่สามารถโหลดข้อความได้: ${e.message}');
      }
    } catch (e) {
      debugPrint("Unexpected error: $e");
      if (mounted) {
        _showErrorSnackbar('เกิดข้อผิดพลาดที่ไม่คาดคิด');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.ibmPlexSansThai()),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
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
      'ถอนเงิน',
      'จ่ายเงิน',
      'ชำระเงิน',
      'ยอดคงเหลือ',
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
          _buildComposePage(),
          _buildActivityPage(),
          _buildProfilePage(),
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
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMessages,
              tooltip: 'รีเฟรช',
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
                    isLoading ? 'กำลังโหลด...' : 'ยังไม่มีข้อความ',
                    style: GoogleFonts.ibmPlexSansThai(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isLoading)
                    TextButton.icon(
                      onPressed: _loadMessages,
                      icon: const Icon(Icons.refresh),
                      label: Text('โหลดข้อความ', style: GoogleFonts.ibmPlexSansThai()),
                    ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMessages,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: allMessages.length,
                itemBuilder: (context, index) {
                  final message = allMessages[index];
                  return _buildMessageCard(message);
                },
              ),
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
      ),
      body: moneyMessages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีรายการเงินเข้า',
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
                return _buildMessageCard(message);
              },
            ),
    );
  }

  Widget _buildComposePage() => const Center(child: Text('หน้าสร้างข้อความ'));
  Widget _buildActivityPage() => const Center(child: Text('หน้ากิจกรรม'));
  Widget _buildProfilePage() => const Center(child: Text('หน้าโปรไฟล์'));

  Widget _buildMessageCard(SmsMessage message) {
    final date = DateTime.fromMillisecondsSinceEpoch(message.date);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.grey[100],
          child: const Icon(Icons.message, color: Colors.black),
        ),
        title: Text(
          message.address,
          style: GoogleFonts.ibmPlexSansThai(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message.body,
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
          message.address,
          style: GoogleFonts.ibmPlexSansThai(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.body,
                style: GoogleFonts.ibmPlexSansThai(),
              ),
              const SizedBox(height: 16),
              Text(
                _formatDate(DateTime.fromMillisecondsSinceEpoch(message.date)),
                style: GoogleFonts.ibmPlexSansThai(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
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
