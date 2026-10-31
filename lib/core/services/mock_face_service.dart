import 'face_recognition_service.dart';

class MockFaceRecognitionService implements FaceRecognitionService {
  @override
  Future<Map<String, dynamic>?> recognizeFace(dynamic cameraImage) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'npm': '5240411016',
      'nama': 'Fadhlur Rohman',
      'jurusan': 'Informatika',
      'statusAkses': 'DIIZINKAN',
      'statusIuran': 'LUNAS',
      'bukuDipinjam': [
        'Algoritma Pemrograman (Sisa 1 hari)',
        'Dasar Sains Teknologi (Sisa 2 hari)',
      ],
    };
  }
}
