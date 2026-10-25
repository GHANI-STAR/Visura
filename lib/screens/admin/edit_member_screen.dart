import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/database/firebase_service.dart';
import 'face_enrollment_screen.dart';

class EditMemberScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const EditMemberScreen({super.key, required this.member});

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  late TextEditingController _namaController;
  late TextEditingController _npmController;
  late TextEditingController _prodiController;
  late TextEditingController _tglController;

  String? _currentPhoto;
  List<double>? _faceEmbedding;
  bool _isFaceUpdated = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.member['nama'] ?? '');
    _npmController = TextEditingController(text: widget.member['npm'] ?? '');
    _prodiController = TextEditingController(text: widget.member['prodi'] ?? 'Marketing');
    _tglController = TextEditingController(text: widget.member['tanggal_lahir'] ?? '6 Juli 1967');

    _currentPhoto = widget.member['foto']?.toString() ?? '';
    if (widget.member['face_embedding'] != null) {
      _faceEmbedding = List<double>.from(widget.member['face_embedding']);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _npmController.dispose();
    _prodiController.dispose();
    _tglController.dispose();
    super.dispose();
  }

  // Buka kamera untuk update wajah & biometrik
  Future<void> _openFaceScannerForEdit() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const FaceEnrollmentScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _currentPhoto = result['photoPath'];
        _faceEmbedding = result['embedding'];
        _isFaceUpdated = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajah baru berhasil dipindai! Tekan "Simpan Perubahan" untuk menyimpan.'),
          backgroundColor: Color(0xFF145E53),
        ),
      );
    }
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
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      setState(() {
        _tglController.text = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      });
    }
  }

  Future<void> _saveChanges() async {
    final id = widget.member['id'];
    await DatabaseService.updateMember(id, {
      'nama': _namaController.text.trim(),
      'npm': _npmController.text.trim(),
      'prodi': _prodiController.text.trim(),
      'tanggal_lahir': _tglController.text.trim(),
      'foto': _currentPhoto ?? '',
      'face_embedding': _faceEmbedding,
      'biometrik_terdaftar': _faceEmbedding != null || (_currentPhoto != null && _currentPhoto!.isNotEmpty),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perubahan data anggota berhasil disimpan!'),
        backgroundColor: Color(0xFF145E53),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _deleteMember() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Hapus Anggota', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Yakin ingin menghapus ${widget.member['nama']} dari sistem?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC02227),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await DatabaseService.deleteMember(widget.member['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anggota ${widget.member['nama']} berhasil dihapus.'),
          backgroundColor: const Color(0xFFC02227),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = _currentPhoto != null && _currentPhoto!.isNotEmpty;

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
              // Header
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
                      'Detail & Edit Anggota',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Sheet Formulir
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Biometrik & Foto Profil Atas
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: const Color(0xFFDCE8F5),
                                backgroundImage: hasPhoto
                                    ? (_currentPhoto!.startsWith('http')
                                        ? NetworkImage(_currentPhoto!)
                                        : (kIsWeb
                                            ? NetworkImage(_currentPhoto!)
                                            : FileImage(File(_currentPhoto!)) as ImageProvider))
                                    : null,
                                child: !hasPhoto
                                    ? const Icon(Icons.person, size: 48, color: Color(0xFF1B4965))
                                    : null,
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Biometrik',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isFaceUpdated
                                          ? 'Wajah baru terpilih'
                                          : (hasPhoto ? 'Wajah terdaftar' : 'Belum rekam wajah'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _isFaceUpdated ? const Color(0xFF145E53) : const Color(0xFF616161),
                                        fontWeight: _isFaceUpdated ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF145E53),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                        ),
                                        icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 18),
                                        label: const Text(
                                          'Edit Wajah',
                                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: _openFaceScannerForEdit,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form Data
                        _buildFieldLabel('Nama'),
                        _buildTextField(_namaController),
                        const SizedBox(height: 14),

                        _buildFieldLabel('NPM'),
                        _buildTextField(_npmController),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Program Studi'),
                        _buildTextField(_prodiController),
                        const SizedBox(height: 14),

                        // Tanggal Lahir
                        Row(
                          children: [
                            const Text(
                              'Tanggal Lahir',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
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
                                        _tglController.text,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF145E53), size: 22),
                                      onPressed: _pickDate,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Tombol Simpan Perubahan
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            onPressed: _saveChanges,
                            child: const Text(
                              'Simpan Perubahan',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tombol Hapus Anggota
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC02227),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33C02227), blurRadius: 6, offset: Offset(0, 3)),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            onPressed: _deleteMember,
                            child: const Text(
                              'Hapus Anggota',
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCFD4DC)),
      ),
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}