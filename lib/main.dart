import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/kiosk/face_scan_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'package:visura/screens/admin/admin_login_screen.dart';
import 'dart:async';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Kamera belum terdeteksi: $e');
  }
  runApp(const VisuraApp());
}

class VisuraApp extends StatelessWidget {
  const VisuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF145E53)),
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Animasi denyut halus (breathing animation) untuk logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    // Otomatis pindah ke pemilihan mode setelah 3 detik
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DeviceModeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F364E), Color(0xFF145E53)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animasi Logo Visura Membesar-Mengecil & Pendar Cahaya
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/icon/logo_visura.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Jika path logo_visura belum terdeteksi, coba logo alternatif tanpa memunculkan icon buku
                  return Image.asset(
                    'assets/logo.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                      'VISURA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Indikator Loading Minimalis di Bawah
            Positioned(
              bottom: 60,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'MEMUAT SISTEM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceModeScreen extends StatelessWidget {
  const DeviceModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F364E), Color(0xFF145E53)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Image.asset(
                  'assets/logo.png',
                  height: 64,
                  errorBuilder: (context, error, stackTrace) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Visura',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                _buildModeCard(
                  context: context,
                  title: 'Presensi Tablet',
                  subtitle: 'Untuk presensi perpus',
                  iconWidget: Container(
                    width: 58,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF145E53), width: 2.2),
                    ),
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5F2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FaceScanScreen()),
                    );
                  },
                ),
                const SizedBox(height: 18),

                _buildModeCard(
                  context: context,
                  title: 'Admin Panel',
                  subtitle: 'Menejemen perpus',
                  iconWidget: Container(
                    width: 36,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF145E53), width: 2.2),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 3),
                        Container(
                          width: 12,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF145E53),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 26,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5F2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                    ),
                  ),
                  onTap: () {

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                    );
                  },
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 54,
                  child: Center(child: iconWidget),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF757575), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}