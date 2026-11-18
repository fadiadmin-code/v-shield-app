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
        scaffoldBackgroundColor: const Color(0xFF0B111E),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: ShieldDashboard(),
      ),
    );
  }
}

class ShieldDashboard extends StatefulWidget {
  const ShieldDashboard({super.key});

  @override
  State<ShieldDashboard> createState() => _ShieldDashboardState();
}

class _ShieldDashboardState extends State<ShieldDashboard> {
  bool isConnected = false;
  String selectedEngine = 'VOID VPN';

  // حالة الدروع الخمسة
  bool fullConeNat = true;
  bool blockWebRtc = true;
  bool syncTimezone = true;
  bool gpsSpoof = true;
  bool simSpoof = true;

  // بيانات البروكسي
  final TextEditingController hostController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  void _showProxyDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF121A2B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00A8FF), width: 1),
          ),
          title: const Text(
            'إعدادات بروكسي SOCKS5',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInput(hostController, 'IP / Host (مثال: 192.168.1.1)'),
                const SizedBox(height: 10),
                _buildInput(portController, 'Port (مثال: 1080)', isNumber: true),
                const SizedBox(height: 10),
                _buildInput(userController, 'اسم المستخدم (اختياري)'),
                const SizedBox(height: 10),
                _buildInput(passController, 'كلمة المرور (اختياري)', isPassword: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
              onPressed: () {
                Navigator.pop(context);
                setState(() => isConnected = true);
              },
              child: const Text('حفظ واتصال', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, {bool isNumber = false, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0B111E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isConnected ? const Color(0xFF00E676) : const Color(0xFF00A8FF);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الشريط العلوي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'V-SHIELD',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'THE VOID PROTOCOL • V1.0',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00A8FF),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showProxyDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isConnected ? const Color(0x2200E676) : const Color(0x2200A8FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isConnected ? const Color(0xFF00E676) : const Color(0xFF00A8FF),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        isConnected ? 'محمي كلياً' : 'إعداد البروكسي',
                        style: TextStyle(
                          color: isConnected ? const Color(0xFF00E676) : const Color(0xFF00A8FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // زر الاتصال الدائري الرئيسي
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (!isConnected && hostController.text.isEmpty) {
                      _showProxyDialog();
                    } else {
                      setState(() => isConnected = !isConnected);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 185,
                    height: 185,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF070C16),
                      border: Border.all(color: activeColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.28),
                          blurRadius: 28,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isConnected ? Icons.shield : Icons.bolt,
                          size: 48,
                          color: isConnected ? const Color(0xFF00E676) : const Color(0xFFFFC107),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isConnected ? 'متصل الآن' : 'اضغط للاتصال',
                          style: TextStyle(
                            color: isConnected ? const Color(0xFF00E676) : Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // قسم محرك التوجيه الخفي
              const Text(
                'محرك التوجيه الخفي:',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildEngineButton('VOID VPN'),
                  const SizedBox(width: 8),
                  _buildEngineButton('ADB Tunnelling'),
                  const SizedBox(width: 8),
                  _buildEngineButton('SOCKS5 Hotspot'),
                ],
              ),

              const SizedBox(height: 28),

              // قسم دروع تدمير البصمة وتخطي الفحص
              const Text(
                'دروع تدمير البصمة وتخطي الفحص:',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1624),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildShieldRow('توجيه UDP بالكامل (Full Cone NAT)', fullConeNat, (v) => setState(() => fullConeNat = v)),
                    _buildShieldRow('حجب تسريب WebRTC و ICE', blockWebRtc, (v) => setState(() => blockWebRtc = v)),
                    _buildShieldRow('مزامنة المنطقة الزمنية واللغة', syncTimezone, (v) => setState(() => syncTimezone = v)),
                    _buildShieldRow('تمويه الموقع الجغرافي (GPS Spoof)', gpsSpoof, (v) => setState(() => gpsSpoof = v)),
                    _buildShieldRow('محاكاة الشريحة والشبكة (SIM Spoof)', simSpoof, (v) => setState(() => simSpoof = v)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngineButton(String title) {
    final bool isSelected = selectedEngine == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedEngine = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0x1800A8FF) : const Color(0xFF0F1624),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF00A8FF) : Colors.white10,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00A8FF) : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShieldRow(String title, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF00E676) : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: value ? const Color(0xFF00E676) : Colors.white38,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
