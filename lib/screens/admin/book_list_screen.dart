import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/database/firebase_service.dart';
import 'add_book_screen.dart';
import 'book_detail_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F364E),
      floatingActionButton: Container(
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F364E), Color(0xFF145E53)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          icon: const Icon(Icons.add, color: Colors.white, size: 20),
          label: const Text(
            'Tambah Buku',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddBookScreen()),
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F364E),
              Color(0xFF145E53),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 32,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'Visura',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Text(
                      'Pengelola Buku',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

                      // Kolom Pencarian Judul / Kode Buku
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFE2E4E8),
                              width: 1.2,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            textAlignVertical: TextAlignVertical.center,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Input Judul /Kode Buku',
                              hintStyle: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 13.5,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(left: 20),
                              suffixIcon: Padding(
                                padding: EdgeInsets.only(right: 14),
                                child: Icon(Icons.search, color: Color(0xFF757575), size: 24),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          'Buku Perpus',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF8A9099))),
                            Text('Buku', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF8A9099))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // List Container Buku
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF145E53).withOpacity(0.7),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: StreamBuilder<List<Map<String, dynamic>>>(
                                stream: DatabaseService.getBooks(),
                                builder: (context, snapshot) {
                                  final bookList = snapshot.data ?? [];

                                  final filteredBooks = bookList.where((item) {
                                    final judul = item['judul']?.toString().toLowerCase() ?? '';
                                    final kode = item['kode']?.toString().toLowerCase() ?? '';
                                    final q = _searchQuery.toLowerCase();
                                    return judul.contains(q) || kode.contains(q);
                                  }).toList();

                                  if (filteredBooks.isEmpty) {
                                    return const Center(
                                      child: Text('Koleksi buku belum tersedia.', style: TextStyle(color: Colors.grey)),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: const EdgeInsets.all(10),
                                    itemCount: filteredBooks.length,
                                    itemBuilder: (context, index) {
                                      final book = filteredBooks[index];
                                      final cover = book['cover']?.toString() ?? '';

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BookDetailScreen(book: book),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x08000000),
                                                blurRadius: 6,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              // Thumbnail Cover
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  width: 58,
                                                  height: 64,
                                                  color: const Color(0xFFEFF2F5),
                                                  child: cover.isNotEmpty
                                                      ? (cover.startsWith('http')
                                                          ? Image.network(cover, fit: BoxFit.cover)
                                                          : (kIsWeb ? Image.network(cover, fit: BoxFit.cover) : Image.file(File(cover), fit: BoxFit.cover)))
                                                      : const Icon(Icons.menu_book_rounded, color: Color(0xFF145E53)),
                                                ),
                                              ),
                                              const SizedBox(width: 14),

                                              // Label Detail
                                              const Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Judul Buku',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2B2B2B)),
                                                  ),
                                                  SizedBox(height: 14),
                                                  Text(
                                                    'Kode Buku',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2B2B2B)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 10),

                                              // Nilai Buku
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      book['judul'] ?? '-',
                                                      textAlign: TextAlign.right,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF2B2B2B),
                                                        height: 1.2,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      book['kode'] ?? '-',
                                                      textAlign: TextAlign.right,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF2B2B2B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}