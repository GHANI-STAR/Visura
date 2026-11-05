import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/database/firebase_service.dart';
import 'face_enrollment_screen.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _npmController = TextEditingController();
  final TextEditingController _prodiController = TextEditingController();
  final TextEditingController _tglController = TextEditingController();

  String? _facePhotoPath;
  List<double>? _faceEmbedding;
  dynamic _faceEmbeddingsMulti;

  @override
  void dispose() {
    _namaController.dispose();
    _npmController.dispose();
    _prodiController.dispose();
    _tglController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2004, 1, 1),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF145E53),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      setState(() {
        _tglController.text = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      });
    }
  }

  Future<void> _openFaceScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceEnrollmentScreen(
          memberName: _namaController.text.trim().isNotEmpty
              ? _namaController.text.trim()
              : 'Anggota Baru',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _facePhotoPath = result['photoPath'] ?? result['foto'] ?? result['mainPhotoPath'];

        if (result['embedding'] != null) {
          _faceEmbedding = List<double>.from(result['embedding']);
        }

        if (result['embeddings'] != null) {
          _faceEmbeddingsMulti = result['embeddings'];
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajah berhasil dipindai dan data biometrik disimpan!'),
          backgroundColor: Color(0xFF145E53),
        ),
      );
    }
  }

  Future<void> _saveMember() async {
    if (_namaController.text.trim().isEmpty || _npmController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan NPM wajib diisi!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newMemberData = {
      'nama': _namaController.text.trim(),
      'npm': _npmController.text.trim(),
      'prodi': _prodiController.text.trim().isEmpty ? 'Informatika' : _prodiController.text.trim(),
      'tanggal_lahir': _tglController.text.trim().isEmpty ? '-' : _tglController.text.trim(),
      'lunas': true,
      'biometrik_terdaftar': _faceEmbedding != null || _faceEmbeddingsMulti != null,
      'foto': _facePhotoPath ?? '',
      'face_embedding': _faceEmbedding, // Format lama
      'embedding': _faceEmbedding,      // Format baru tunggal
      'embeddings': _faceEmbeddingsMulti, // Format multi-angle
      'kekurangan_iuran': '0',
      'borrowed_books': [],
    };

    await DatabaseService.addMember(newMemberData);

    if (!mounted) return;
    Navigator.pop(context, 'Anggota "${_namaController.text.trim()}" berhasil ditambahkan!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F364E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F364E), Color(0xFF145E53)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Tambah Anggota',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lengkapi Data',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildFieldLabel('Nama'),
                        _buildTextField(_namaController, 'Masukan Nama'),
                        const SizedBox(height: 14),
                        _buildFieldLabel('NPM'),
                        _buildTextField(
                          _npmController,
                          'Masukan NPM',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),
                        _buildFieldLabel('Program Studi'),
                        _buildTextField(_prodiController, 'Masukan Program Studi'),
                        const SizedBox(height: 14),
                        _buildFieldLabel('Tanggal Lahir'),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCFD4DC)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _tglController.text.isEmpty
                                      ? 'Pilih Tanggal'
                                      : _tglController.text,
                                  style: TextStyle(
                                    color: _tglController.text.isEmpty
                                        ? Colors.grey
                                        : Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Color(0xFF145E53),
                                  size: 22,
                                ),
                                onPressed: _pickDate,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Rekam Wajah (Biometrik)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD6E2EC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: _facePhotoPath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: kIsWeb
                                            ? Image.network(_facePhotoPath!, fit: BoxFit.cover)
                                            : Image.file(File(_facePhotoPath!), fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.person, size: 54, color: Color(0xFF1B4965)),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _openFaceScanner,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _facePhotoPath != null
                                            ? Icons.check_circle_rounded
                                            : Icons.photo_camera_rounded,
                                        size: 46,
                                        color: _facePhotoPath != null
                                            ? const Color(0xFF145E53)
                                            : const Color(0xFFE17585),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _facePhotoPath != null ? 'Ubah Wajah' : 'Scan Wajah',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: _facePhotoPath != null
                                              ? const Color(0xFF145E53)
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F364E), Color(0xFF145E53)],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _saveMember,
                            child: const Text(
                              'Daftarkan Anggota',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCFD4DC)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}