import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
      title: 'V-SHIELD V4.2',
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
    super.initState();
    _loadSavedProxy();
    _checkIdentity();
  }

  Future<void> _loadSavedProxy() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      proxyType = prefs.getString('proxyType') ?? 'SOCKS5';
      proxyHost = prefs.getString('proxyHost') ?? '';
      proxyPort = prefs.getString('proxyPort') ?? '';
      proxyUser = prefs.getString('proxyUser') ?? '';
      proxyPass = prefs.getString('proxyPass') ?? '';
      proxyPing = prefs.getString('proxyPing') ?? 'محفوظ ✅';
    });
  }

  Future<void> _saveProxy(String type, String host, String port, String user, String pass, String ping) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('proxyType', type);
    await prefs.setString('proxyHost', host);
    await prefs.setString('proxyPort', port);
    await prefs.setString('proxyUser', user);
    await prefs.setString('proxyPass', pass);
    await prefs.setString('proxyPing', ping);
  }

  Future<void> _checkIdentity({String? targetIp}) async {
    setState(() => isChecking = true);
    try {
      final url = (targetIp != null && targetIp.isNotEmpty)
          ? 'http://ip-api.com/json/$targetIp'
          : 'http://ip-api.com/json/';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          currentIp = data['query'] ?? 'غير معروف';
          country = data['country'] ?? '---';
          city = data['city'] ?? '---';
          timezone = data['timezone'] ?? 'UTC';
          isp = data['isp'] ?? '---';
          lat = (data['lat'] ?? 0.0).toDouble();
          lon = (data['lon'] ?? 0.0).toDouble();
        });
      }
    } catch (_) {
      setState(() => currentIp = 'تعذر الاتصال بالخادم');
    } finally {
      setState(() => isChecking = false);
    }
  }

  void _rotateDeviceIdentity() {
    final rnd = Random();
    setState(() {
      activeProfile = kDeviceProfiles[rnd.nextInt(kDeviceProfiles.length)];
      noiseSeed = rnd.nextInt(999999);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم توليد هوية جديدة: ${activeProfile.name} (Seed #$noiseSeed)'),
        backgroundColor: const Color(0xFF00E676),
      ),
    );
  }

  void _updateProxy(String type, String host, String port, String user, String pass, String ping) {
    setState(() {
      proxyType = type;
      proxyHost = host;
      proxyPort = port;
      proxyUser = user;
      proxyPass = pass;
      proxyPing = ping;
    });
    _saveProxy(type, host, port, user, pass, ping);
    if (host.isNotEmpty) {
      _checkIdentity(targetIp: host);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ShieldDashboard(
        ip: currentIp,
        country: country,
        city: city,
        timezone: timezone,
        isp: isp,
        isChecking: isChecking,
        proxyType: proxyType,
        proxyHost: proxyHost,
        proxyPort: proxyPort,
        proxyUser: proxyUser,
        proxyPass: proxyPass,
        proxyPing: proxyPing,
        activeProfile: activeProfile,
        onRefresh: () => _checkIdentity(),
        onCheckProxyIp: () => _checkIdentity(targetIp: proxyHost),
        onUpdateProxy: _updateProxy,
        onRotateIdentity: _rotateDeviceIdentity,
      ),
      StealthBrowserTab(
        targetTimezone: timezone,
        profile: activeProfile,
        noiseSeed: noiseSeed,
        onRotateIdentity: _rotateDeviceIdentity,
      ),
      SystemSpoofTab(timezone: timezone, lat: lat, lon: lon, country: country),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF0F1624),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white54,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'الدرع والبروكسي'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'المتصفح الخفي'),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'النظام و ADB'),
        ],
      ),
    );
  }
}

// ==================== التبويب الأول: الدرع والبروكسي ====================
class ShieldDashboard extends StatefulWidget {
  final String ip, country, city, timezone, isp;
  final String proxyType, proxyHost, proxyPort, proxyUser, proxyPass, proxyPing;
  final DeviceProfile activeProfile;
  final bool isChecking;
  final VoidCallback onRefresh, onCheckProxyIp, onRotateIdentity;
  final Function(String, String, String, String, String, String) onUpdateProxy;

  const ShieldDashboard({
    super.key,
    required this.ip,
    required this.country,
    required this.city,
    required this.timezone,
    required this.isp,
    required this.isChecking,
    required this.proxyType,
    required this.proxyHost,
    required this.proxyPort,
    required this.proxyUser,
    required this.proxyPass,
    required this.proxyPing,
    required this.activeProfile,
    required this.onRefresh,
    required this.onCheckProxyIp,
    required this.onUpdateProxy,
    required this.onRotateIdentity,
  });

  @override
  State<ShieldDashboard> createState() => _ShieldDashboardState();
}

class _ShieldDashboardState extends State<ShieldDashboard> {
  static const MethodChannel _vpnChannel = MethodChannel('v_shield/vpn');
  bool isConnected = false;
  String selectedEngine = 'VOID VPN';
  bool fullConeNat = true;
  bool blockWebRtc = true;
  bool canvasNoise = true;
  bool syncTimezone = true;
  bool gpsSpoof = true;

  void _openProxyDialog() {
    String tempType = widget.proxyType;
    final quickCtrl = TextEditingController();
    final hostCtrl = TextEditingController(text: widget.proxyHost);
    final portCtrl = TextEditingController(text: widget.proxyPort);
    final userCtrl = TextEditingController(text: widget.proxyUser);
    final passCtrl = TextEditingController(text: widget.proxyPass);
    String testStatus = widget.proxyPing;
    bool testing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF121A2B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF00A8FF)),
            ),
            title: const Text('إعداد وفحص البروكسي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: quickCtrl,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'لصق سريع: ip:port:user:pass',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF0B111E),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.auto_fix_high, color: Color(0xFF00E676), size: 18),
                        onPressed: () {
                          final parts = quickCtrl.text.trim().split(':');
                          if (parts.length >= 2) {
                            hostCtrl.text = parts[0];
                            portCtrl.text = parts[1];
                            if (parts.length >= 4) {
                              userCtrl.text = parts[2];
                              passCtrl.text = parts[3];
                            }
                          }
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['SOCKS5', 'HTTP'].map((t) {
                      final sel = tempType == t;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setDlgState(() => tempType = t),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: sel ? const Color(0x2200E676) : const Color(0xFF0B111E),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: sel ? const Color(0xFF00E676) : Colors.white12),
                            ),
                            child: Text(t, style: TextStyle(color: sel ? const Color(0xFF00E676) : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  _input(hostCtrl, 'Host / IP'),
                  const SizedBox(height: 8),
                  _input(portCtrl, 'Port', isNum: true),
                  const SizedBox(height: 8),
                  _input(userCtrl, 'Username (اختياري)'),
                  const SizedBox(height: 8),
                  _input(passCtrl, 'Password (اختياري)', isPass: true),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الحالة: $testStatus', style: const TextStyle(fontSize: 12, color: Color(0xFF00A8FF))),
                      TextButton.icon(
                        onPressed: testing
                            ? null
                            : () async {
                                final h = hostCtrl.text.trim();
                                final p = int.tryParse(portCtrl.text.trim()) ?? 0;
                                if (h.isEmpty || p == 0) {
                                  setDlgState(() => testStatus = 'أدخل IP و Port');
                                  return;
                                }
                                setDlgState(() {
                                  testing = true;
                                  testStatus = 'جاري الفحص...';
                                });
                                final sw = Stopwatch()..start();
                                try {
                                  final sock = await Socket.connect(h, p, timeout: const Duration(seconds: 4));
                                  sw.stop();
                                  sock.destroy();
                                  setDlgState(() => testStatus = 'شغال ✅ (${sw.elapsedMilliseconds}ms)');
                                } catch (_) {
                                  setDlgState(() => testStatus = 'فشل الاتصال ❌');
                                } finally {
                                  setDlgState(() => testing = false);
                                }
                              },
                        icon: const Icon(Icons.speed, size: 16, color: Color(0xFF00E676)),
                        label: const Text('فحص البينغ', style: TextStyle(color: Color(0xFF00E676), fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                onPressed: () {
                  widget.onUpdateProxy(tempType, hostCtrl.text.trim(), portCtrl.text.trim(), userCtrl.text.trim(), passCtrl.text.trim(), testStatus);
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ البروكسي', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, {bool isNum = false, bool isPass = false}) {
    return TextField(
      controller: c,
      obscureText: isPass,
      textDirection: TextDirection.ltr,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0B111E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isConnected ? const Color(0xFF00E676) : const Color(0xFF00A8FF);
    final bool hasProxy = widget.proxyHost.isNotEmpty && widget.proxyPort.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('V-SHIELD', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('THE VOID PROTOCOL • V4.2 CORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00A8FF))),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0x2200A8FF),
                        side: const BorderSide(color: Color(0xFF00A8FF)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: _openProxyDialog,
                      icon: const Icon(Icons.vpn_key, size: 15, color: Color(0xFF00A8FF)),
                      label: Text(hasProxy ? 'تعديل البروكسي' : 'إضافة بروكسي', style: const TextStyle(color: Color(0xFF00A8FF), fontSize: 12)),
                    ),
                    IconButton(
                      onPressed: isConnected ? widget.onCheckProxyIp : widget.onRefresh,
                      icon: widget.isChecking
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E676)))
                          : const Icon(Icons.refresh, color: Color(0xFF00E676)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1624),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: activeColor.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  _infoRow('عنوان الـ IP:', widget.ip, const Color(0xFF00E676)),
                  _infoRow('الموقع والمنطقة:', '${widget.country} (${widget.timezone})', const Color(0xFF00A8FF)),
                  _infoRow('البروكسي المحفوظ:', hasProxy ? '${widget.proxyType} | ${widget.proxyHost}:${widget.proxyPort}' : 'لم يتم الإضافة بعد', hasProxy ? Colors.amber : Colors.white38),
                  _infoRow('حالة البينغ:', widget.proxyPing, Colors.white70),
                  const Divider(color: Colors.white12, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('الجهاز المحاكى: ${widget.activeProfile.name}', style: const TextStyle(fontSize: 11, color: Colors.white70))),
                      GestureDetector(
                        onTap: widget.onRotateIdentity,
                        child: const Text('تغيير الهوية ↻', style: TextStyle(fontSize: 12, color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            Center(
              child: GestureDetector(
                onTap: () async {
                  if (!isConnected && !hasProxy) {
                    _openProxyDialog();
                    return;
                  }
                  try {
                    if (!isConnected) {
                      final bool started = await _vpnChannel.invokeMethod('startVpn', {
                        'type': widget.proxyType.toLowerCase(),
                        'host': widget.proxyHost,
                        'port': int.tryParse(widget.proxyPort) ?? 1080,
                        'user': widget.proxyUser,
                        'pass': widget.proxyPass,
                      });
                      if (started) {
                        setState(() => isConnected = true);
                        widget.onCheckProxyIp();
                      }
                    } else {
                      await _vpnChannel.invokeMethod('stopVpn');
                      setState(() => isConnected = false);
                      widget.onRefresh();
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ في النفق: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF070C16),
                    border: Border.all(color: activeColor, width: 2.5),
                    boxShadow: [BoxShadow(color: activeColor.withOpacity(0.28), blurRadius: 25, spreadRadius: 2)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isConnected ? Icons.shield : Icons.bolt, size: 42, color: isConnected ? const Color(0xFF00E676) : const Color(0xFFFFC107)),
                      const SizedBox(height: 8),
                      Text(isConnected ? 'محمي كلياً' : 'اضغط للاتصال', style: TextStyle(color: isConnected ? const Color(0xFF00E676) : Colors.white70, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            const Text('محرك التوجيه الخفي:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                _engineBtn('VOID VPN'),
                const SizedBox(width: 8),
                _engineBtn('ADB Tunnelling'),
                const SizedBox(width: 8),
                _engineBtn('SOCKS5 Hotspot'),
              ],
            ),
            const SizedBox(height: 20),

            const Text('دروع تدمير البصمة وتخطي Verisoul:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF0F1624), borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  _shieldRow('توجيه UDP بالكامل (Full Cone NAT)', fullConeNat, (v) => setState(() => fullConeNat = v)),
                  _shieldRow('حجب تسريب WebRTC و ICE', blockWebRtc, (v) => setState(() => blockWebRtc = v)),
                  _shieldRow('تشويش بصمة Canvas و WebGL و Audio', canvasNoise, (v) => setState(() => canvasNoise = v)),
                  _shieldRow('مزامنة المنطقة الزمنية واللغة', syncTimezone, (v) => setState(() => syncTimezone = v)),
                  _shieldRow('تمويه الموقع الجغرافي (GPS Spoof)', gpsSpoof, (v) => setState(() => gpsSpoof = v)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Flexible(child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(color: valColor, fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _engineBtn(String title) {
    final bool selected = selectedEngine == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedEngine = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0x1800A8FF) : const Color(0xFF0F1624),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? const Color(0xFF00A8FF) : Colors.white10),
          ),
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? const Color(0xFF00A8FF) : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _shieldRow(String title, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13))),
            Icon(value ? Icons.check_box : Icons.check_box_outline_blank, color: value ? const Color(0xFF00E676) : Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}

// ==================== التبويب الثاني: المتصفح الخفي المطور ====================
class StealthBrowserTab extends StatefulWidget {
  final String targetTimezone;
  final DeviceProfile profile;
  final int noiseSeed;
  final VoidCallback onRotateIdentity;

  const StealthBrowserTab({
    super.key,
    required this.targetTimezone,
    required this.profile,
    required this.noiseSeed,
    required this.onRotateIdentity,
  });

  @override
  State<StealthBrowserTab> createState() => _StealthBrowserTabState();
}

class _StealthBrowserTabState extends State<StealthBrowserTab> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://browserleaks.com/webrtc');

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(widget.profile.userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _injectVoidCloak(),
        ),
      )
      ..loadRequest(Uri.parse(_urlController.text));
  }

  void _injectVoidCloak() {
    final p = widget.profile;
    final seed = (widget.noiseSeed % 5) + 1;
    final js = '''
      (function() {
        window.RTCPeerConnection = undefined;
        window.webkitRTCPeerConnection = undefined;
        window.mozRTCPeerConnection = undefined;

        Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
        Object.defineProperty(navigator, 'hardwareConcurrency', {get: () => ${p.cores}});
        Object.defineProperty(navigator, 'deviceMemory', {get: () => ${p.memory}});
        Object.defineProperty(navigator, 'language', {get: () => 'en-US'});
        Object.defineProperty(navigator, 'languages', {get: () => ['en-US', 'en']});
        if (navigator.getBattery) navigator.getBattery = undefined;

        const origResolved = Intl.DateTimeFormat.prototype.resolvedOptions;
        Intl.DateTimeFormat.prototype.resolvedOptions = function() {
          const res = origResolved.apply(this, arguments);
          res.timeZone = '${widget.targetTimezone}';
          return res;
        };

        const origToDataURL = HTMLCanvasElement.prototype.toDataURL;
        HTMLCanvasElement.prototype.toDataURL = function() {
          const ctx = this.getContext('2d');
          if (ctx) {
            ctx.fillStyle = 'rgba(0,0,0,0.01)';
            ctx.fillRect(0, 0, $seed, $seed);
          }
          return origToDataURL.apply(this, arguments);
        };

        const origGetParam = WebGLRenderingContext.prototype.getParameter;
        WebGLRenderingContext.prototype.getParameter = function(param) {
          if (param === 37445) return '${p.gpuVendor}';
          if (param === 37446) return '${p.gpuRenderer}';
          return origGetParam.apply(this, arguments);
        };
      })();
    ''';
    _controller.runJavaScript(js);
  }

  void _go() {
    String url = _urlController.text.trim();
    if (!url.startsWith('http')) url = 'https://$url';
    _controller.setUserAgent(widget.profile.userAgent);
    _controller.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF0F1624),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => _controller.goBack()),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onSubmitted: (_) => _go(),
                    decoration: InputDecoration(
                      hintText: 'أدخل الرابط...',
                      filled: true,
                      fillColor: const Color(0xFF0B111E),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'توليد هوية جهاز جديدة',
                  icon: const Icon(Icons.fingerprint, color: Color(0xFF00A8FF)),
                  onPressed: () {
                    widget.onRotateIdentity();
                    _controller.reload();
                  },
                ),
                IconButton(icon: const Icon(Icons.search, color: Color(0xFF00E676)), onPressed: _go),
              ],
            ),
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}

// ==================== التبويب الثالث: أدوات النظام و ADB ====================
class SystemSpoofTab extends StatelessWidget {
  final String timezone, country;
  final double lat, lon;

  const SystemSpoofTab({super.key, required this.timezone, required this.lat, required this.lon, required this.country});

  void _copy(BuildContext context, String cmd) {
    Clipboard.setData(ClipboardData(text: cmd));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الأمر بنجاح!'), backgroundColor: Color(0xFF00E676)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tzCmd = 'adb shell service call alarm 3 s16 $timezone';
    final gpsCmd = 'adb emu geo fix $lon $lat';
    final simCmd = 'adb shell setprop gsm.sim.operator.alpha "T-Mobile" && adb shell setprop gsm.sim.operator.iso-country "us"';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('أدوات تمويه النظام (بدون روت / للمحاكي و ADB)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('يتم توليد هذه الأوامر تلقائياً لتطابق دولة وإحداثيات البروكسي الحالي:', style: TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 20),
          _cmdCard(context, '1. مزامنة المنطقة الزمنية ($timezone)', tzCmd),
          _cmdCard(context, '2. تمويه إحداثيات الـ GPS ($lat, $lon)', gpsCmd),
          _cmdCard(context, '3. محاكاة شريحة SIM والشبكة ($country)', simCmd),
        ],
      ),
    );
  }

  Widget _cmdCard(BuildContext context, String title, String cmd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1624),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF00A8FF), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF070C16), borderRadius: BorderRadius.circular(8)),
            child: Text(cmd, textDirection: TextDirection.ltr, style: const TextStyle(color: Color(0xFF00E676), fontFamily: 'monospace', fontSize: 11)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _copy(context, cmd),
              icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
              label: const Text('نسخ الأمر', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
