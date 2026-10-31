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

  // --- PINJAM BUKU ---
  Future<void> _handleBorrow() async {
    if (_selectedMember == null) return;

    final err = await DatabaseService.borrowBookToMember(_selectedMember!['id'], _currentBook);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: const Color(0xFFC02227)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buku "${_currentBook['judul']}" berhasil dipinjamkan ke ${_selectedMember!['nama']}!'),
          backgroundColor: const Color(0xFF145E53),
        ),
      );
      setState(() {
        final list = List<Map<String, dynamic>>.from(_selectedMember!['borrowed_books'] ?? []);
        list.add({'kode': _currentBook['kode'], 'judul': _currentBook['judul']});
        _selectedMember!['borrowed_books'] = list;
      });
    }
  }

  // --- KEMBALIKAN BUKU ---
  Future<void> _handleReturn() async {
    if (_selectedMember == null) return;

    final err = await DatabaseService.returnBookFromMember(_selectedMember!['id'], _currentBook['kode']);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: const Color(0xFFC02227)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buku "${_currentBook['judul']}" berhasil dikembalikan oleh ${_selectedMember!['nama']}!'),
          backgroundColor: const Color(0xFF145E53),
        ),
      );
      setState(() {
        final list = List<Map<String, dynamic>>.from(_selectedMember!['borrowed_books'] ?? []);
        list.removeWhere((b) => b['kode'] == _currentBook['kode']);
        _selectedMember!['borrowed_books'] = list;
      });
    }
  }

  // --- EDIT BUKU DENGAN GANTI COVER ---
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
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void pickCoverModal() {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                      onTap: pickCoverModal,
                      child: Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF2F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF145E53)),
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
                                  Icon(Icons.camera_alt, color: Color(0xFF145E53)),
                                  SizedBox(height: 4),
                                  Text('Ganti Cover', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Buku berhasil diperbarui!'), backgroundColor: Color(0xFF145E53)),
                    );
                  },
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- HAPUS BUKU ---
  Future<void> _deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Buku', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Hapus "${_currentBook['judul']}" dari katalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC02227)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteBook(_currentBook['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buku telah dihapus.'), backgroundColor: Color(0xFFC02227)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cover = _currentBook['cover']?.toString() ?? '';

    // Cek apakah mahasiswa terpilih sedang meminjam buku ini
    bool isCurrentBookBorrowedBySelected = false;
    List<Map<String, dynamic>> borrowedList = [];
    if (_selectedMember != null) {
      final raw = _selectedMember!['borrowed_books'] as List? ?? [];
      borrowedList = raw.map((e) => Map<String, dynamic>.from(e)).toList();
      isCurrentBookBorrowedBySelected = borrowedList.any((b) => b['kode'] == _currentBook['kode']);
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
              // Header Seragam (Back di kiri, Judul di kanan)
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

              // Sheet Putih Konten
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
                        const Text(
                          'Informasi Buku',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 14),

                        // Kartu Rincian Buku (Tanpa status lokasi)
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Center(
                                child: Container(
                                  width: 85,
                                  height: 95,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9EDF2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: cover.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: kIsWeb || cover.startsWith('http')
                                              ? Image.network(cover, fit: BoxFit.cover)
                                              : Image.file(File(cover), fit: BoxFit.cover),
                                        )
                                      : const Icon(Icons.menu_book_rounded, size: 48, color: Color(0xFF145E53)),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildDetailRow('Judul', _currentBook['judul'] ?? '-'),
                              _buildDetailRow('Kode', _currentBook['kode'] ?? '-'),
                              _buildDetailRow('Penulis', _currentBook['penulis'] ?? '-'),
                              _buildDetailRow('Kategori', _currentBook['kategori'] ?? '-'),
                              _buildDetailRow('Tahun Terbit', _currentBook['tahun_terbit'] ?? '-'),
                              _buildDetailRow('Deskripsi', _currentBook['deskripsi'] ?? '-', isMultiLine: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // BAGIAN LOG PENCARIAN MAHASISWA & PEMINJAMAN
                        const Text(
                          'Peminjaman Mahasiswa',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),

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
                              // Input Search Mahasiswa
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFD6DBE2)),
                                ),
                                child: TextField(
                                  controller: _searchMemberController,
                                  textAlignVertical: TextAlignVertical.center,
                                  onChanged: (val) => setState(() {}),
                                  style: const TextStyle(fontSize: 13),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'Cari Nama atau NPM Mahasiswa...',
                                    hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                                    border: InputBorder.none,
                                    suffixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Log List Mahasiswa yang Terdaftar
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: DatabaseService.getMembers(),
                                builder: (context, snapshot) {
                                  final allMembers = snapshot.data ?? [];
                                  final query = _searchMemberController.text.trim().toLowerCase();

                                  final filtered = allMembers.where((m) {
                                    final nama = m['nama']?.toString().toLowerCase() ?? '';
                                    final npm = m['npm']?.toString().toLowerCase() ?? '';
                                    return nama.contains(query) || npm.contains(query);
                                  }).toList();

                                  if (filtered.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Text('Mahasiswa tidak ditemukan.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    );
                                  }

                                  return Container(
                                    constraints: const BoxConstraints(maxHeight: 140),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAFAFA),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE5E5E5)),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, idx) {
                                        final m = filtered[idx];
                                        final isSelected = _selectedMember?['id'] == m['id'];

                                        return ListTile(
                                          dense: true,
                                          selected: isSelected,
                                          selectedTileColor: const Color(0xFFE6F4EA),
                                          title: Text(m['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          subtitle: Text('NPM: ${m['npm'] ?? '-'}', style: const TextStyle(fontSize: 11)),
                                          trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF145E53), size: 18) : null,
                                          onTap: () {
                                            setState(() => _selectedMember = m);
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),

                              // Tampilan Detail Mahasiswa Terpilih
                              if (_selectedMember != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F7F6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF145E53).withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Peminjam: ${_selectedMember!['nama']}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                            onPressed: () => setState(() => _selectedMember = null),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Buku sedang dipinjam: ${borrowedList.isEmpty ? "Tidak ada" : borrowedList.map((b) => b['judul']).join(", ")}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF424242)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Tombol Aksi Pinjam & Kembalikan
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: !isCurrentBookBorrowedBySelected ? const Color(0xFF145E53) : Colors.grey[400],
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          padding: const EdgeInsets.symmetric(vertical: 11),
                                        ),
                                        onPressed: !isCurrentBookBorrowedBySelected ? _handleBorrow : null,
                                        child: const Text('Pinjamkan Buku', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: isCurrentBookBorrowedBySelected ? const Color(0xFFC02227) : Colors.grey[400]!,
                                            width: 1.2,
                                          ),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          padding: const EdgeInsets.symmetric(vertical: 11),
                                        ),
                                        onPressed: isCurrentBookBorrowedBySelected ? _handleReturn : null,
                                        child: Text(
                                          'Kembalikan Buku',
                                          style: TextStyle(
                                            color: isCurrentBookBorrowedBySelected ? const Color(0xFFC02227) : Colors.grey[400],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // TOMBOL EDIT & HAPUS BUKU DI BAGIAN BAWAH
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
          ),
          const Text(' :  ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isMultiLine ? FontWeight.normal : FontWeight.w600,
                color: const Color(0xFF2B2B2B),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}