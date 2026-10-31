import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/database/firebase_service.dart';
import 'camera_capture_screen.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _judulController = TextEditingController();
  final _kodeController = TextEditingController();
  final _penulisController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _tahunController = TextEditingController();
  final _deskripsiController = TextEditingController();

  String? _coverPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _judulController.dispose();
    _kodeController.dispose();
    _penulisController.dispose();
    _kategoriController.dispose();
    _tahunController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF145E53)),
                title: const Text('Buka Kamera Langsung'),
                onTap: () async {
                  Navigator.pop(context);
                  final photoPath = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraCaptureScreen()),
                  );
                  if (photoPath != null) setState(() => _coverPath = photoPath);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_rounded, color: Color(0xFF145E53)),
                title: const Text('Pilih dari File / Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) setState(() => _coverPath = picked.path);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveBook() async {
    if (_judulController.text.trim().isEmpty || _kodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan Kode Buku wajib diisi!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newBook = {
      'judul': _judulController.text.trim(),
      'kode': _kodeController.text.trim(),
      'penulis': _penulisController.text.trim().isEmpty ? 'Anonim' : _penulisController.text.trim(),
      'kategori': _kategoriController.text.trim().isEmpty ? 'Umum' : _kategoriController.text.trim(),
      'tahun_terbit': _tahunController.text.trim().isEmpty ? '2024' : _tahunController.text.trim(),
      'deskripsi': _deskripsiController.text.trim(),
      'cover': _coverPath ?? '',
    };

    await DatabaseService.addBook(newBook);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Buku "${_judulController.text}" berhasil disimpan!'),
        backgroundColor: const Color(0xFF145E53),
      ),
    );
    Navigator.pop(context);
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
                      'Tambah Buku',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
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
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _showImagePickerModal,
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFF145E53), width: 1.5),
                            ),
                            child: _coverPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: kIsWeb
                                        ? Image.network(_coverPath!, fit: BoxFit.cover)
                                        : Image.file(File(_coverPath!), fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt, size: 62, color: Color(0xFF145E53)),
                                      SizedBox(height: 12),
                                      Text(
                                        'Upload Cover Buku',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildFormRow('Judul', _judulController, 'Input Judul Buku'),
                        _buildFormRow('Kode', _kodeController, 'Input Kode Buku', keyboardType: TextInputType.number),
                        _buildFormRow('Penulis', _penulisController, 'Input Nama Penulis'),
                        _buildFormRow('Kategori', _kategoriController, 'Input Kategori Buku'),
                        _buildFormRow('Tahun Terbit', _tahunController, 'Input Tahun Terbit', keyboardType: TextInputType.number),
                        _buildFormRow('Deskripsi', _deskripsiController, 'Input Deskripsi', maxLines: 3),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F364E), Color(0xFF145E53)],
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            onPressed: _saveBook,
                            child: const Text(
                              'Simpan Buku Baru',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildFormRow(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD6DBE2)),
              ),
              child: TextField(
                controller: controller,
                maxLines: maxLines,
                keyboardType: keyboardType,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  hintStyle: const TextStyle(color: Color(0xFFB0B6C1), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}