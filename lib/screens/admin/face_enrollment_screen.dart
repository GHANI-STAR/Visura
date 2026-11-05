// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import '../../core/services/face_recognition_service.dart';

// class FaceEnrollmentScreen extends StatefulWidget {
//   const FaceEnrollmentScreen({super.key});

//   @override
//   State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
// }

// class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
//   CameraController? _controller;
//   List<CameraDescription>? _cameras;
//   bool _isInit = false;
//   bool _isCapturing = false;

//   @override
//   void initState() {
//     super.initState();
//     _setupCamera();
//   }

//   Future<void> _setupCamera() async {
//     try {
//       _cameras = await availableCameras();
//       if (_cameras != null && _cameras!.isNotEmpty) {
//         final frontCam = _cameras!.firstWhere(
//           (c) => c.lensDirection == CameraLensDirection.front,
//           orElse: () => _cameras!.first,
//         );

//         _controller = CameraController(
//           frontCam,
//           ResolutionPreset.medium,
//           enableAudio: false,
//         );

//         await _controller!.initialize();
//         if (mounted) setState(() => _isInit = true);
//       }
//     } catch (e) {
//       debugPrint('Kamera tidak dapat diakses: $e');
//     }
//   }

//   Future<void> _captureAndProcessFace() async {
//     if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

//     setState(() => _isCapturing = true);

//     try {
//       final XFile photo = await _controller!.takePicture();
//       final bytes = await photo.readAsBytes();

//       final embedding = await FaceRecognitionService.extractEmbedding(bytes);

//       if (!mounted) return;

//       Navigator.pop(context, {
//         'photoPath': photo.path,
//         'embedding': embedding,
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Gagal merekam wajah: $e'), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isCapturing = false);
//     }
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           if (_isInit && _controller != null)
//             SizedBox.expand(
//               child: FittedBox(
//                 fit: BoxFit.cover,
//                 child: SizedBox(
//                   width: _controller!.value.previewSize?.height ?? 1,
//                   height: _controller!.value.previewSize?.width ?? 1,
//                   child: CameraPreview(_controller!),
//                 ),
//               ),
//             )
//           else
//             const Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircularProgressIndicator(color: Color(0xFF145E53)),
//                   SizedBox(height: 16),
//                   Text('Menyiapkan sensor kamera...', style: TextStyle(color: Colors.white)),
//                 ],
//               ),
//             ),

//           SafeArea(
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       const Text(
//                         'Pindai Biometrik Wajah',
//                         style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(width: 48),
//                     ],
//                   ),
//                 ),
//                 const Spacer(),

//                 Container(
//                   width: 250,
//                   height: 330,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(160),
//                     border: Border.all(color: const Color(0xFF145E53), width: 3.5),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.black54,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: const Text(
//                     'Posisikan wajah Anda tepat di dalam bingkai oval',
//                     style: TextStyle(color: Colors.white, fontSize: 13),
//                   ),
//                 ),
//                 const Spacer(),

//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 36),
//                   child: GestureDetector(
//                     onTap: _isCapturing ? null : _captureAndProcessFace,
//                     child: Container(
//                       height: 76,
//                       width: 76,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 4),
//                         color: _isCapturing ? Colors.grey : const Color(0xFF145E53),
//                       ),
//                       child: _isCapturing
//                           ? const Center(child: CircularProgressIndicator(color: Colors.white))
//                           : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/services/face_recognition_service.dart';

// Alias tipe agar aman dari pemotongan kurung generics saat copy-paste
typedef StepData = Map<String, String>;
typedef DoubleList = List<double>;
typedef JsonMap = Map<String, dynamic>;

class FaceEnrollmentScreen extends StatefulWidget {
  final String? memberName;
  // Parameter dijadikan opsional agar tidak memicu error di add_member & edit_member screen
  const FaceEnrollmentScreen({super.key, this.memberName});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isProcessing = false;

  int _currentStep = 0;
  final List<String> _capturedPhotoPaths = [];
  final List<DoubleList> _extractedEmbeddings = [];

  final List<StepData> _enrollmentSteps = const [
    {
      'title': 'Hadap Lurus ke Depan',
      'instruction': 'Posisikan wajah tepat di tengah bingkai oval',
    },
    {
      'title': 'Tengok Sedikit ke Kiri',
      'instruction': 'Miringkan kepala sekitar 15-20° ke arah kiri',
    },
    {
      'title': 'Tengok Sedikit ke Kanan',
      'instruction': 'Miringkan kepala sekitar 15-20° ke arah kanan',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final frontCam = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCam,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraReady = true);
        }
      }
    } catch (e) {
      debugPrint('Kamera gagal diinisialisasi: $e');
    }
  }

  Future<void> _captureCurrentAngle() async {
    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile photo = await _cameraController!.takePicture();
      final bytes = await photo.readAsBytes();

      final embedding = await FaceRecognitionService.extractEmbedding(bytes);

      if (embedding.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Wajah tidak terdeteksi jelas! Pastikan pencahayaan cukup.'),
              backgroundColor: Color(0xFFC02227),
            ),
          );
        }
        return;
      }

      _capturedPhotoPaths.add(photo.path);
      _extractedEmbeddings.add(List<double>.from(embedding));

      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
        });
      } else {
        // 3 Sudut selesai: mengembalikan data yang kompatibel baik dengan format lama maupun baru
        if (mounted) {
          Navigator.pop(context, {
            'photoPath': _capturedPhotoPaths[0],
            'foto': _capturedPhotoPaths[0],
            'mainPhotoPath': _capturedPhotoPaths[0],
            'allPhotoPaths': _capturedPhotoPaths,
            'embedding': _extractedEmbeddings[0],
            'embeddings': _extractedEmbeddings,
          });
        }
      }
    } catch (e) {
      debugPrint('Gagal mengambil pose wajah: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.memberName != null
        ? 'Perekaman Wajah: ${widget.memberName}'
        : 'Perekaman Wajah (3 Sudut)';

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
        child: SafeArea(
          child: Stack(
            children: [
              // Kamera Oval
              if (_isCameraReady && _cameraController != null)
                Center(
                  child: Container(
                    width: 270,
                    height: 360,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(160),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF145E53).withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(157),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width:
                              _cameraController!.value.previewSize?.height ?? 1,
                          height:
                              _cameraController!.value.previewSize?.width ?? 1,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),

              // Header Atas
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        titleText,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Kontrol Bawah
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isDone = index < _currentStep;
                        final isCurrent = index == _currentStep;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isCurrent ? 28 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFF00E676)
                                : (isCurrent ? Colors.white : Colors.white24),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Langkah ${_currentStep + 1} dari 3: ${_enrollmentSteps[_currentStep]['title']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _enrollmentSteps[_currentStep]['instruction']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureCurrentAngle,
                      child: Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.5),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isProcessing ? Colors.grey : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _isProcessing
                              ? const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation(
                                          Color(0xFF0F364E)),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Color(0xFF0F364E),
                                  size: 32,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}