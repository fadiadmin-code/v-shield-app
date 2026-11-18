import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const VShieldApp());
}

class VShieldApp extends StatelessWidget {
  const VShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'V-SHIELD V4.0',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B111E),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainNavigation(),
      ),
    );
  }
}

class DeviceProfile {
  final String name;
  final String userAgent;
  final String gpuVendor;
  final String gpuRenderer;
  final int cores;
  final int memory;

  const DeviceProfile({
    required this.name,
    required this.userAgent,
    required this.gpuVendor,
    required this.gpuRenderer,
    required this.cores,
    required this.memory,
  });
}

const List<DeviceProfile> kDeviceProfiles = [
  DeviceProfile(
    name: 'Samsung Galaxy S24 Ultra',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.122 Mobile Safari/537.36',
    gpuVendor: 'Qualcomm',
    gpuRenderer: 'Adreno (TM) 750',
    cores: 8,
    memory: 12,
  ),
  DeviceProfile(
    name: 'Google Pixel 8 Pro',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.6422.165 Mobile Safari/537.36',
    gpuVendor: 'ARM',
    gpuRenderer: 'Mali-G715',
    cores: 8,
    memory: 12,
  ),
  DeviceProfile(
    name: 'OnePlus 12 5G',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; CPH2581) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.71 Mobile Safari/537.36',
    gpuVendor: 'Qualcomm',
    gpuRenderer: 'Adreno (TM) 750',
    cores: 8,
    memory: 16,
  ),
  DeviceProfile(
    name: 'Xiaomi 14 Pro',
    userAgent: 'Mozilla/5.0 (Linux; Android 14; 23116PN5BC) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.6367.179 Mobile Safari/537.36',
    gpuVendor: 'Qualcomm',
    gpuRenderer: 'Adreno (TM) 750',
    cores: 8,
    memory: 12,
  ),
];

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  String currentIp = 'جاري الفحص...';
  String country = '---';
  String city = '---';
  String timezone = 'America/New_York';
  String isp = '---';
  double lat = 40.7128;
  double lon = -74.0060;
  bool isChecking = false;

  String proxyType = 'SOCKS5';
  String proxyHost = '';
  String proxyPort = '';
  String proxyUser = '';
  String proxyPass = '';
  String proxyPing = 'غير مفحوص';

  DeviceProfile activeProfile = kDeviceProfiles[0];
  int noiseSeed = Random().nextInt(99999);

  @override
  void initState() {
