import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/database/firebase_service.dart';
import 'camera_capture_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Map<String, dynamic> _currentBook;
  final TextEditingController _searchMemberController = TextEditingController();
  Map<String, dynamic>? _selectedMember;

  @override
  void initState() {
    super.initState();
    _currentBook = Map<String, dynamic>.from(widget.book);
  }

  @override
  void dispose() {
    _searchMemberController.dispose();
    super.dispose();
  }

  void _showEnlargedCover(String cover) {
    if (cover.isEmpty) return;

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
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: kIsWeb || cover.startsWith('http')
                      ? Image.network(cover, fit: BoxFit.contain)
                      : Image.file(File(cover), fit: BoxFit.contain),
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

  Future<void> _handleBorrow() async {
    if (_selectedMember == null) return;
    final err = await DatabaseService.borrowBookToMember(_selectedMember!['id'], _currentBook);
    if (!mounted) return;

    if (err != null) {
      AppNotification.show(context, err, backgroundColor: const Color(0xFFC02227));
    } else {
      AppNotification.show(context, 'Buku berhasil dipinjamkan ke ${_selectedMember!['nama']}!');
      setState(() {});
    }
  }

  Future<void> _handleReturn() async {
    if (_selectedMember == null) return;
    final err = await DatabaseService.returnBookFromMember(_selectedMember!['id'], _currentBook['kode']);
    if (!mounted) return;

    if (err != null) {
      AppNotification.show(context, err, backgroundColor: const Color(0xFFC02227));
    } else {
      AppNotification.show(context, 'Buku berhasil dikembalikan oleh ${_selectedMember!['nama']}!');
      setState(() {});
    }
  }

  void _openEditDialog() {
    final judulCtrl = TextEditingController(text: _currentBook['judul']);
    final kodeCtrl = TextEditingController(text: _currentBook['kode']);
    final penulisCtrl = TextEditingController(text: _currentBook['penulis']);
    final kategoriCtrl = TextEditingController(text: _currentBook['kategori']);
    final tahunCtrl = TextEditingController(text: _currentBook['tahun_terbit']);
    final deskripsiCtrl = TextEditingController(text: _currentBook['deskripsi']);
    String editCover = _currentBook['cover']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          void pickCoverOption() {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (bCtx) => SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF145E53)),
                      title: const Text('Buka Kamera Langsung'),
                      onTap: () async {
                        Navigator.pop(bCtx);
                        final photoPath = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
                        );
                        if (photoPath != null) {
                          setModalState(() => editCover = photoPath);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.folder_open_rounded, color: Color(0xFF145E53)),
                      title: const Text('Pilih dari File / Galeri'),
                      onTap: () async {
                        Navigator.pop(bCtx);
                        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setModalState(() => editCover = picked.path);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Informasi Buku', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: pickCoverOption,
                    child: Container(
                      height: 100,
                      width: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF2F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF145E53), width: 1.5),
                      ),
                      child: editCover.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb || editCover.startsWith('http')
                                  ? Image.network(editCover, fit: BoxFit.cover)
                                  : Image.file(File(editCover), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Color(0xFF145E53), size: 28),
                                SizedBox(height: 4),
                                Text(
                                  'Ubah Cover',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF145E53),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(controller: judulCtrl, decoration: const InputDecoration(labelText: 'Judul Buku')),
                  TextField(controller: kodeCtrl, decoration: const InputDecoration(labelText: 'Kode Buku')),
                  TextField(controller: penulisCtrl, decoration: const InputDecoration(labelText: 'Penulis')),
                  TextField(controller: kategoriCtrl, decoration: const InputDecoration(labelText: 'Kategori')),
                  TextField(controller: tahunCtrl, decoration: const InputDecoration(labelText: 'Tahun Terbit')),
                  TextField(controller: deskripsiCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi')),
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
                    'judul': judulCtrl.text.trim(),
                    'kode': kodeCtrl.text.trim(),
                    'penulis': penulisCtrl.text.trim(),
                    'kategori': kategoriCtrl.text.trim(),
                    'tahun_terbit': tahunCtrl.text.trim(),
                    'deskripsi': deskripsiCtrl.text.trim(),
                    'cover': editCover,
                  };
                  await DatabaseService.updateBook(_currentBook['id'], updated);
                  setState(() => _currentBook.addAll(updated));
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  AppNotification.show(context, 'Buku berhasil diperbarui!');
                },
                child: const Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Buku', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "${_currentBook['judul']}" dari katalog perpustakaan?'),
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
      await DatabaseService.deleteBook(_currentBook['id']);
      if (!mounted) return;
      AppNotification.show(
        context,
        'Buku telah dihapus dari perpustakaan.',
        backgroundColor: const Color(0xFFC02227),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cover = _currentBook['cover']?.toString() ?? '';
    final borrowers = DatabaseService.getBorrowersOfBook(_currentBook['kode']);

    bool isCurrentBookBorrowedBySelected = false;
    if (_selectedMember != null) {
      final raw = _selectedMember!['borrowed_books'] as List? ?? [];
      isCurrentBookBorrowedBySelected = raw.any((b) => b['kode'] == _currentBook['kode']);
    }

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
                      'Detail Buku',
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
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _showEnlargedCover(cover),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 95,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE9EDF2),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                        ],
                                      ),
                                      child: cover.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: kIsWeb || cover.startsWith('http')
                                                  ? Image.network(cover, fit: BoxFit.cover)
                                                  : Image.file(File(cover), fit: BoxFit.cover),
                                            )
                                          : const Icon(Icons.menu_book_rounded, size: 52, color: Color(0xFF145E53)),
                                    ),
                                    if (cover.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        margin: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildDetailRow('Judul', _currentBook['judul'] ?? '-'),
                              _buildDetailRow('Kode', _currentBook['kode'] ?? '-'),
                              _buildDetailRow('Penulis', _currentBook['penulis'] ?? '-'),
                              _buildDetailRow('Kategori', _currentBook['kategori'] ?? '-'),
                              _buildDetailRow('Tahun', _currentBook['tahun_terbit'] ?? '-'),
                              _buildDetailRow('Deskripsi', _currentBook['deskripsi'] ?? '-', isMultiLine: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        const Text(
                          'Sedang Dipinjam Oleh:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E4E8)),
                          ),
                          child: borrowers.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text('Belum ada yang meminjam buku ini.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: borrowers.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (ctx, i) {
                                    final b = borrowers[i];
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Color(0xFFDCE8F5),
                                        child: Icon(Icons.person, color: Color(0xFF145E53)),
                                      ),
                                      title: Text(b['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      subtitle: Text('NPM: ${b['npm']} • ${b['prodi']}', style: const TextStyle(fontSize: 11)),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: b['isOverdue'] ? const Color(0xFFFDE8E8) : const Color(0xFFE6F4EA),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          b['status_tenggat'],
                                          style: TextStyle(
                                            color: b['isOverdue'] ? const Color(0xFFC02227) : const Color(0xFF145E53),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF145E53), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _searchMemberController,
                                onChanged: (val) => setState(() {}),
                                decoration: const InputDecoration(
                                  hintText: 'Cari Mahasiswa peminjam...',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: DatabaseService.getMembers(),
                                builder: (context, snapshot) {
                                  final members = snapshot.data ?? [];
                                  final q = _searchMemberController.text.trim().toLowerCase();
                                  final filtered = members.where((m) => m['nama'].toLowerCase().contains(q) || m['npm'].contains(q)).toList();

                                  return Container(
                                    constraints: const BoxConstraints(maxHeight: 120),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: filtered.length,
                                      itemBuilder: (ctx, i) {
                                        final m = filtered[i];
                                        final isSel = _selectedMember?['id'] == m['id'];
                                        return ListTile(
                                          dense: true,
                                          selected: isSel,
                                          selectedTileColor: const Color(0xFFEAF5F2),
                                          title: Text(m['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text(m['npm']),
                                          onTap: () => setState(() => _selectedMember = m),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              if (_selectedMember != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF145E53)),
                                        onPressed: !isCurrentBookBorrowedBySelected ? _handleBorrow : null,
                                        child: const Text('Pinjamkan', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: isCurrentBookBorrowedBySelected ? _handleReturn : null,
                                        child: const Text('Kembalikan'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
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
                            label: const Text('Edit Buku', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
                            label: const Text('Hapus Buku', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            onPressed: _deleteBook,
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

  Widget _buildDetailRow(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
          ),
          const Text(' :  '),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF2B2B2B)))),
        ],
      ),
    );
  }
}