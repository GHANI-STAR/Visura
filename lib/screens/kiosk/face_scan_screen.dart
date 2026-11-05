import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:visura/main.dart';
import '../../core/database/firebase_service.dart';
import '../../core/services/face_recognition_service.dart';

// Alias tipe agar aman dari pemotongan kurung generics saat copy-paste
typedef JsonMap = Map<String, dynamic>;

class FaceScanScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;
  const FaceScanScreen({super.key, this.cameras});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  Timer? _autoScanTimer;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  JsonMap? _recognizedMember;
  String? _scanAction;
  List<JsonMap> _registeredMembers = [];
  StreamSubscription? _membersSubscription;
  late AnimationController _animController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _initScannerAnimation();
    _initCamera();
    _listenToMembers();
  }

  void _initScannerAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  void _listenToMembers() {
    _membersSubscription = DatabaseService.getMembers().listen((members) {
      if (mounted) {
        setState(() {
          _registeredMembers = List<JsonMap>.from(members);
        });
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      cameras = widget.cameras ?? await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        final frontCam = cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras!.first,
        );

        _controller = CameraController(
          frontCam,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() => _isCameraReady = true);
          _startContinuousFaceScanning();
        }
      }
    } catch (e) {
      debugPrint('Kamera Kiosk gagal dinyalakan: $e');
    }
  }

  void _startContinuousFaceScanning() {
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (_isCameraReady &&
          !_isProcessing &&
          _controller != null &&
          _controller!.value.isInitialized) {
        _detectAndRecognizeFace();
      }
    });
  }

  Future<void> _detectAndRecognizeFace() async {
    // 1. Cek apakah daftar anggota ada isinya
    if (_registeredMembers.isEmpty) {
      debugPrint('⚠️ Scanner: Belum ada data anggota yang terdaftar di database!');
      return;
    }

    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();

      final currentEmbedding =
          await FaceRecognitionService.extractEmbedding(bytes);

      if (currentEmbedding.isEmpty) {
        debugPrint('⚠️ Scanner: Wajah tidak ditemukan dalam frame kamera.');
        return;
      }

      // Gunakan threshold 0.60 agar lebih fleksibel di kondisi ruangan
      final match = FaceRecognitionService.matchFace(
        currentEmbedding,
        _registeredMembers,
        threshold: 0.60, // <-- DITURUNKAN DARI 0.70 KE 0.60
      );

      if (match != null && mounted) {
        debugPrint('✅ Presensi Cocok: ${match['nama']} (NPM: ${match['npm']})');
        _autoScanTimer?.cancel();

        final action = await DatabaseService.recordVisitor(
          match['nama'],
          match['npm'],
          foto: match['foto'],
        );

        setState(() {
          _recognizedMember = match;
          _scanAction = action;
        });

        await Future.delayed(const Duration(seconds: 4));

        if (mounted) {
          setState(() {
            _recognizedMember = null;
            _scanAction = null;
          });
          _startContinuousFaceScanning();
        }
      } else {
        debugPrint('❌ Wajah terdeteksi tapi belum melewati batas skor kemiripan.');
      }
    } catch (e) {
      debugPrint('Error proses pemindaian: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _showExitKioskDialog() async {
    final TextEditingController passController = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: Color(0xFF0F364E)),
                  SizedBox(width: 10),
                  Text(
                    'Keluar Mode Tablet',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan password staf untuk menutup terminal presensi:',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Password (123)',
                      errorText: errorText,
                      prefixIcon: const Icon(Icons.password_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F364E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (passController.text.trim() == '123') {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const DeviceModeScreen()),
                      );
                    } else {
                      setDialogState(() {
                        errorText = 'Password salah!';
                      });
                    }
                  },
                  child: const Text('Verifikasi', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    _membersSubscription?.cancel();
    _animController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitKioskDialog();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (_isCameraReady && _controller != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize?.height ?? 1,
                    height: _controller!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_controller!),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF145E53)),
              ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: 32,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                            'Visura',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF00E676),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Auto Scanner Aktif',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 28),
                          onPressed: _showExitKioskDialog,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 270,
                          height: 350,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(160),
                            border: Border.all(
                              color: _recognizedMember != null
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF145E53),
                              width: 3.5,
                            ),
                          ),
                        ),
                        if (_recognizedMember == null)
                          AnimatedBuilder(
                            animation: _laserAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: 20 + (_laserAnimation.value * 300),
                                child: Container(
                                  width: 230,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676)
                                        .withValues(alpha: 0.8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFF00E676),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_recognizedMember == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Dekatkan wajah Anda ke kamera untuk presensi otomatis',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  const Spacer(),
                  const SizedBox(height: 110),
                ],
              ),
            ),
            if (_recognizedMember != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 24,
                child: _buildBottomIdentityCard(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomIdentityCard() {
    final member = _recognizedMember!;
    final foto = member['foto']?.toString() ?? '';
    final nama = member['nama'] ?? 'Mahasiswa';
    final npm = member['npm'] ?? '-';
    final jurusan = member['prodi'] ?? 'Informatika';
    final bool isMasuk = _scanAction != 'Keluar';
    final bool isLunas = member['lunas'] == true;
    final rawBorrowed = (member['borrowed_books'] as List?) ?? [];
    final List<JsonMap> borrowedBooks = rawBorrowed.map((b) {
      if (b is Map) return Map<String, dynamic>.from(b);
      return {'judul': b.toString(), 'kode': '-'};
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 38,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFDCE8F5),
                  backgroundImage: foto.isNotEmpty
                      ? (foto.startsWith('http')
                          ? NetworkImage(foto)
                          : (kIsWeb
                              ? NetworkImage(foto)
                              : FileImage(File(foto)) as ImageProvider))
                      : null,
                  child: foto.isEmpty
                      ? const Icon(Icons.person,
                          size: 28, color: Color(0xFF1B4965))
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NPM: $npm',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF424242),
                        ),
                      ),
                      Text(
                        'Jurusan: $jurusan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 64,
            color: const Color(0xFFE2E4E8),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            flex: 25,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Status Akses',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isMasuk
                        ? const Color(0xFF1B6B5D)
                        : const Color(0xFFC02227),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isMasuk ? 'MASUK' : 'KELUAR',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Status Iuran',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isLunas
                        ? const Color(0xFF1B6B5D)
                        : const Color(0xFFC02227),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isLunas ? 'LUNAS' : 'BELUM',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 64,
            color: const Color(0xFFE2E4E8),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            flex: 37,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Buku Dipinjam',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                if (borrowedBooks.isEmpty)
                  const Text(
                    'Tidak ada pinjaman',
                    style: TextStyle(fontSize: 9.5, color: Colors.grey),
                  )
                else ...[
                  Text(
                    '1. ${borrowedBooks[0]['judul'] ?? 'Buku'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    'Terlambat',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (borrowedBooks.length > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      '2. ${borrowedBooks[1]['judul'] ?? 'Buku'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'Sisa 2 hari',
                      style: TextStyle(
                        fontSize: 8.5,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}