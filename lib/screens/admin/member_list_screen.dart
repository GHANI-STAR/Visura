import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/database/firebase_service.dart';
import 'add_member_screen.dart';
import 'edit_member_screen.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
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
            'Tambah Anggota',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddMemberScreen()),
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
                      'Daftar Anggota',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Sheet Konten
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
                    children: [
                      const SizedBox(height: 18),

                      // Kolom Pencarian NPM
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
                              hintText: 'Input NPM Mahasiswa',
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
                      const SizedBox(height: 14),

                      // List Mahasiswa
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: DatabaseService.getMembers(),
                          builder: (context, snapshot) {
                            final memberList = snapshot.data ?? [];

                            final filteredList = memberList.where((item) {
                              final npm = item['npm']?.toString().toLowerCase() ?? '';
                              final nama = item['nama']?.toString().toLowerCase() ?? '';
                              final q = _searchQuery.toLowerCase();
                              return npm.contains(q) || nama.contains(q);
                            }).toList();

                            if (filteredList.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Belum ada data anggota.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 75),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final member = filteredList[index];
                                final bool isLunas = member['lunas'] == true;
                                final foto = member['foto']?.toString() ?? '';

                                return InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditMemberScreen(member: member),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x0A000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Foto Profil Asli atau Icon Default
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor: const Color(0xFFDCE8F5),
                                          backgroundImage: foto.isNotEmpty
                                              ? (foto.startsWith('http')
                                                  ? NetworkImage(foto)
                                                  : (kIsWeb
                                                      ? NetworkImage(foto)
                                                      : FileImage(File(foto)) as ImageProvider))
                                              : null,
                                          child: foto.isEmpty
                                              ? const Icon(Icons.person, size: 28, color: Color(0xFF1B4965))
                                              : null,
                                        ),
                                        const SizedBox(width: 14),

                                        // Keterangan Mahasiswa
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                member['nama'] ?? 'Tanpa Nama',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                member['npm'] ?? '-',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF424242),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    isLunas ? Icons.check_circle : Icons.error,
                                                    color: isLunas
                                                        ? const Color(0xFF145E53)
                                                        : const Color(0xFFC02227),
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 2.5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isLunas
                                                          ? const Color(0xFF145E53)
                                                          : const Color(0xFFC02227),
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    child: Text(
                                                      isLunas ? 'Lunas' : 'Belum Lunas',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
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