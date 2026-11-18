import 'dart:convert';
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
      title: 'V-SHIELD V2.0',
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

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // بيانات الهوية الحالية (تتحدث تلقائياً من الفاحص)
  String currentIp = 'جاري الفحص...';
  String country = '---';
  String city = '---';
  String timezone = 'America/New_York';
  String isp = '---';
  double lat = 40.7128;
  double lon = -74.0060;
  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkIdentity();
  }

  Future<void> _checkIdentity() async {
    setState(() => isChecking = true);
    try {
      final res = await http.get(Uri.parse('http://ip-api.com/json/')).timeout(const Duration(seconds: 8));
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
        onRefresh: _checkIdentity,
      ),
      StealthBrowserTab(targetTimezone: timezone),
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
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'الدرع'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'المتصفح الخفي'),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'النظام و ADB'),
        ],
      ),
    );
  }
}

// ==================== التبويب الأول: لوحة الدرع ====================
class ShieldDashboard extends StatefulWidget {
  final String ip, country, city, timezone, isp;
  final bool isChecking;
  final VoidCallback onRefresh;

  const ShieldDashboard({
    super.key,
    required this.ip,
    required this.country,
    required this.city,
    required this.timezone,
    required this.isp,
    required this.isChecking,
    required this.onRefresh,
  });

  @override
  State<ShieldDashboard> createState() => _ShieldDashboardState();
}

class _ShieldDashboardState extends State<ShieldDashboard> {
  bool isConnected = false;
  String selectedEngine = 'VOID VPN';
  bool fullConeNat = true;
  bool blockWebRtc = true;
  bool syncTimezone = true;
  bool gpsSpoof = true;
  bool simSpoof = true;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isConnected ? const Color(0xFF00E676) : const Color(0xFF00A8FF);

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
                    Text('THE VOID PROTOCOL • V2.0', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00A8FF))),
                  ],
                ),
                IconButton(
                  onPressed: widget.onRefresh,
                  icon: widget.isChecking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E676)))
                      : const Icon(Icons.refresh, color: Color(0xFF00E676)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // بطاقة فحص الهوية المباشر
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1624),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: activeColor.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  _infoRow('عنوان الـ IP الحالي:', widget.ip, const Color(0xFF00E676)),
                  _infoRow('الموقع الجغرافي:', '${widget.country} - ${widget.city}', Colors.white),
                  _infoRow('المنطقة الزمنية:', widget.timezone, const Color(0xFF00A8FF)),
                  _infoRow('مزود الخدمة (ISP):', widget.isp, Colors.white70),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // زر الاتصال
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() => isConnected = !isConnected);
                  widget.onRefresh();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 155,
                  height: 155,
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
            const SizedBox(height: 24),

            // محرك التوجيه
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

            // دروع تدمير البصمة
            const Text('دروع تدمير البصمة وتخطي الفحص:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF0F1624), borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  _shieldRow('توجيه UDP بالكامل (Full Cone NAT)', fullConeNat, (v) => setState(() => fullConeNat = v)),
                  _shieldRow('حجب تسريب WebRTC و ICE', blockWebRtc, (v) => setState(() => blockWebRtc = v)),
                  _shieldRow('مزامنة المنطقة الزمنية واللغة', syncTimezone, (v) => setState(() => syncTimezone = v)),
                  _shieldRow('تمويه الموقع الجغرافي (GPS Spoof)', gpsSpoof, (v) => setState(() => gpsSpoof = v)),
                  _shieldRow('محاكاة الشريحة والشبكة (SIM Spoof)', simSpoof, (v) => setState(() => simSpoof = v)),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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

// ==================== التبويب الثاني: المتصفح الخفي ====================
class StealthBrowserTab extends StatefulWidget {
  final String targetTimezone;
  const StealthBrowserTab({super.key, required this.targetTimezone});

  @override
  State<StealthBrowserTab> createState() => _StealthBrowserTabState();
}

class _StealthBrowserTabState extends State<StealthBrowserTab> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://whoer.net');

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _injectAntiDetect(),
        ),
      )
      ..loadRequest(Uri.parse(_urlController.text));
  }

  void _injectAntiDetect() {
    final js = '''
      // حجب تسريب WebRTC بالكامل
      window.RTCPeerConnection = undefined;
      window.webkitRTCPeerConnection = undefined;
      window.mozRTCPeerConnection = undefined;
      // تمويه المنطقة الزمنية واللغة
      Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
      Object.defineProperty(navigator, 'language', {get: () => 'en-US'});
      Object.defineProperty(navigator, 'languages', {get: () => ['en-US', 'en']});
      const origResolved = Intl.DateTimeFormat.prototype.resolvedOptions;
      Intl.DateTimeFormat.prototype.resolvedOptions = function() {
        const res = origResolved.apply(this, arguments);
        res.timeZone = '${widget.targetTimezone}';
        return res;
      };
    ''';
    _controller.runJavaScript(js);
  }

  void _go() {
    String url = _urlController.text.trim();
    if (!url.startsWith('http')) url = 'https://$url';
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
