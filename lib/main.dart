import 'package:flutter/material.dart';

void main() {
  runApp(const VShieldApp());
}

class VShieldApp extends StatelessWidget {
  const VShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'V-SHIELD',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050B14),
        primaryColor: const Color(0xFF00E676),
      ),
      home: const ShieldHomeScreen(),
    );
  }
}

class ShieldHomeScreen extends StatefulWidget {
  const ShieldHomeScreen({super.key});

  @override
  State<ShieldHomeScreen> createState() => _ShieldHomeScreenState();
}

class _ShieldHomeScreenState extends State<ShieldHomeScreen> {
  bool isConnected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('V-SHIELD : The Void Protocol'),
        backgroundColor: const Color(0xFF0D1527),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  isConnected = !isConnected;
                });
              },
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF070D19),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF00E676) : const Color(0xFF00B0FF),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isConnected ? const Color(0x5500E676) : const Color(0x3300B0FF),
                      blurRadius: 25,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isConnected ? '🛡️' : '⚡',
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isConnected ? 'متصل ومحمي' : 'اضغط للاتصال',
                      style: TextStyle(
                        color: isConnected ? const Color(0xFF00E676) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
