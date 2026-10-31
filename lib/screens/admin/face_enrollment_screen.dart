import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/services/face_recognition_service.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInit = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Prioritaskan kamera depan (front camera)
        final frontCam = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _controller = CameraController(
          frontCam,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) setState(() => _isInit = true);
      }
    } catch (e) {
      debugPrint('Kamera tidak dapat diakses: $e');
    }
  }

  Future<void> _captureAndProcessFace() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();

      // Ekstraksi vektor fitur visual asli
      final embedding = await FaceRecognitionService.extractEmbedding(bytes);

      if (!mounted) return;

      Navigator.pop(context, {
        'photoPath': photo.path,
        'embedding': embedding,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal merekam wajah: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Preview Kamera Penuh
          if (_isInit && _controller != null)
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF145E53)),
                  SizedBox(height: 16),
                  Text('Menyiapkan sensor kamera...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

          // 2. Overlay Panduan Oval Wajah
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Pindai Biometrik Wajah',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),

                // Bingkai Oval Wajah
                Container(
                  width: 250,
                  height: 330,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(160),
                    border: Border.all(color: const Color(0xFF145E53), width: 3.5),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Posisikan wajah Anda tepat di dalam bingkai oval',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const Spacer(),

                // Tombol Jepret Wajah
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: GestureDetector(
                    onTap: _isCapturing ? null : _captureAndProcessFace,
                    child: Container(
                      height: 76,
                      width: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isCapturing ? Colors.grey : const Color(0xFF145E53),
                      ),
                      child: _isCapturing
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}