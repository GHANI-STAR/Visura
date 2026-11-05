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
  late Map<String, dynamic> _currentMember;

  @override
  void initState() {
    super.initState();
    _currentMember = Map<String, dynamic>.from(widget.member);
  }

  void _showEnlargedPhoto(String photo) {
    if (photo.isEmpty) {
      AppNotification.show(
        context,
        'Anggota ini belum memiliki foto biometrik terdaftar.',
        backgroundColor: const Color(0xFFC02227),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: Colors.black87,
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    child: kIsWeb || photo.startsWith('http')
                        ? Image.network(photo, fit: BoxFit.contain)
                        : Image.file(File(photo), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditDialog() {
    final namaCtrl = TextEditingController(text: _currentMember['nama']);
    final npmCtrl = TextEditingController(text: _currentMember['npm']);
    final prodiCtrl = TextEditingController(text: _currentMember['prodi']);
    final tglCtrl = TextEditingController(text: _currentMember['tanggal_lahir']);
    String editPhoto = _currentMember['foto']?.toString() ?? '';
    List<double>? editEmbedding = _currentMember['face_embedding'] != null
        ? List<double>.from(_currentMember['face_embedding'])
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Data Anggota', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFDCE8F5),
                          backgroundImage: editPhoto.isNotEmpty
                              ? (editPhoto.startsWith('http')
                                  ? NetworkImage(editPhoto)
                                  : (kIsWeb
                                      ? NetworkImage(editPhoto)
                                      : FileImage(File(editPhoto)) as ImageProvider))
                              : null,
                          child: editPhoto.isEmpty
                              ? const Icon(Icons.person, size: 40, color: Color(0xFF1B4965))
                              : null,
                        ),
                        InkWell(
                          onTap: () async {
                            final res = await Navigator.push<Map<String, dynamic>>(
                              context,
                              MaterialPageRoute(builder: (_) => const FaceEnrollmentScreen()),
                            );
                            if (res != null) {
                              setModalState(() {
                                editPhoto = res['photoPath'];
                                editEmbedding = res['embedding'];
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF145E53),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
                  TextField(controller: npmCtrl, decoration: const InputDecoration(labelText: 'NPM')),
                  TextField(controller: prodiCtrl, decoration: const InputDecoration(labelText: 'Program Studi')),
                  TextField(controller: tglCtrl, decoration: const InputDecoration(labelText: 'Tanggal Lahir')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF145E53)),
                onPressed: () async {
                  final updated = {
                    'nama': namaCtrl.text.trim(),
                    'npm': npmCtrl.text.trim(),
                    'prodi': prodiCtrl.text.trim(),
                    'tanggal_lahir': tglCtrl.text.trim(),
                    'foto': editPhoto,
                    'face_embedding': editEmbedding,
                    'biometrik_terdaftar': editEmbedding != null || editPhoto.isNotEmpty,
                  };

                  await DatabaseService.updateMember(_currentMember['id'], updated);
                  setState(() => _currentMember.addAll(updated));
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  AppNotification.show(context, 'Data anggota berhasil diperbarui!');
                },
                child: const Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteMember() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Anggota', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "${_currentMember['nama']}" dari daftar anggota perpustakaan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC02227),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteMember(_currentMember['id']);
      if (!mounted) return;
      AppNotification.show(
        context,
        'Anggota telah dihapus.',
        backgroundColor: const Color(0xFFC02227),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = _currentMember['foto']?.toString() ?? '';
    final hasPhoto = photo.isNotEmpty;
    final npm = _currentMember['npm']?.toString() ?? '';

    final bool isLunas = _currentMember['lunas'] == true;
    final bool isInside = DatabaseService.isMemberInside(npm);

    final borrowedRaw = _currentMember['borrowed_books'] as List? ?? [];
    final List<Map<String, dynamic>> borrowedBooks = borrowedRaw.map((b) {
      if (b is Map) return Map<String, dynamic>.from(b);
      return {'judul': b.toString(), 'kode': '-', 'borrowed_at': null};
    }).toList();

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
                      'Detail Anggota',
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
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _showEnlargedPhoto(photo),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 46,
                                      backgroundColor: const Color(0xFFDCE8F5),
                                      backgroundImage: hasPhoto
                                          ? (photo.startsWith('http')
                                              ? NetworkImage(photo)
                                              : (kIsWeb
                                                  ? NetworkImage(photo)
                                                  : FileImage(File(photo)) as ImageProvider))
                                          : null,
                                      child: !hasPhoto
                                          ? const Icon(Icons.person, size: 48, color: Color(0xFF1B4965))
                                          : null,
                                    ),
                                    if (hasPhoto)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isLunas ? const Color(0xFFE6F4EA) : const Color(0xFFFDE8E8),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLunas ? Icons.check_circle_rounded : Icons.error_rounded,
                                          color: isLunas ? const Color(0xFF145E53) : const Color(0xFFC02227),
                                          size: 15,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          isLunas ? 'Iuran: LUNAS' : 'Iuran: BELUM LUNAS',
                                          style: TextStyle(
                                            color: isLunas ? const Color(0xFF145E53) : const Color(0xFFC02227),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isInside ? const Color(0xFFE8F0FE) : const Color(0xFFF1F3F4),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isInside ? Icons.meeting_room_rounded : Icons.no_meeting_room_rounded,
                                          color: isInside ? const Color(0xFF1A73E8) : const Color(0xFF5F6368),
                                          size: 15,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          isInside ? 'Di Dalam Perpus' : 'Di Luar Perpus',
                                          style: TextStyle(
                                            color: isInside ? const Color(0xFF1A73E8) : const Color(0xFF5F6368),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              _buildDetailRow('Nama', _currentMember['nama'] ?? '-'),
                              _buildDetailRow('NPM', _currentMember['npm'] ?? '-'),
                              _buildDetailRow('Program Studi', _currentMember['prodi'] ?? '-'),
                              _buildDetailRow('Tgl Lahir', _currentMember['tanggal_lahir'] ?? '-'),
                              _buildDetailRow('Biometrik', hasPhoto ? 'Wajah Terdaftar' : 'Belum Rekam Wajah'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        const Text(
                          'Buku yang Sedang Dipinjam',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E4E8)),
                          ),
                          child: borrowedBooks.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      'Tidak ada buku yang sedang dipinjam.',
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: borrowedBooks.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (ctx, i) {
                                    final b = borrowedBooks[i];
                                    final due = DatabaseService.checkDueStatus(b['borrowed_at']);

                                    return ListTile(
                                      leading: const Icon(Icons.menu_book, color: Color(0xFF145E53)),
                                      title: Text(
                                        b['judul'] ?? 'Buku',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      subtitle: Text('Kode: ${b['kode']}', style: const TextStyle(fontSize: 11)),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: due['isOverdue'] ? const Color(0xFFFDE8E8) : const Color(0xFFE6F4EA),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          due['text'],
                                          style: TextStyle(
                                            color: due['isOverdue'] ? const Color(0xFFC02227) : const Color(0xFF145E53),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 26),

                        Container(
                          width: double.infinity,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(colors: [Color(0xFF0F364E), Color(0xFF145E53)]),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                            label: const Text(
                              'Edit Anggota',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            onPressed: _openEditDialog,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC02227),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [BoxShadow(color: Color(0x33C02227), blurRadius: 6, offset: Offset(0, 3))],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                            label: const Text(
                              'Hapus Anggota',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            onPressed: _deleteMember,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
          ),
          const Text(' :  '),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF2B2B2B)))),
        ],
      ),
    );
  }
}