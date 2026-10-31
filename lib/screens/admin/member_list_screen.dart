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

  void _showEnlargedPhoto(BuildContext context, String photo, String nama) {
    if (photo.isEmpty) {
      AppNotification.show(
        context,
        'Mahasiswa $nama belum memiliki foto profil terdaftar.',
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InteractiveViewer(
                        maxScale: 4.0,
                        child: kIsWeb || photo.startsWith('http')
                            ? Image.network(photo, fit: BoxFit.contain)
                            : Image.file(File(photo), fit: BoxFit.contain),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          nama,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F364E),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: AppNotification.isVisible,
        builder: (context, isNotifVisible, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(bottom: isNotifVisible ? 68.0 : 0.0),
            child: child,
          );
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E3D48),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            label: const Text(
              'Tambah Anggota',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
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
      ),
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
                      'Pengelola Anggota',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

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
                              hintText: 'Input NPM / Nama Mahasiswa',
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

                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: DatabaseService.getMembers(),
                          builder: (context, snapshot) {
                            final members = snapshot.data ?? [];
                            final filtered = members.where((m) {
                              final nama = m['nama']?.toString().toLowerCase() ?? '';
                              final npm = m['npm']?.toString().toLowerCase() ?? '';
                              final q = _searchQuery.toLowerCase();
                              return nama.contains(q) || npm.contains(q);
                            }).toList();

                            if (filtered.isEmpty) {
                              return const Center(
                                child: Text('Belum ada data anggota.', style: TextStyle(color: Colors.grey)),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final member = filtered[index];
                                final foto = member['foto']?.toString() ?? '';
                                final nama = member['nama'] ?? '-';
                                final hasPhoto = foto.isNotEmpty;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
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
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditMemberScreen(member: member),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _showEnlargedPhoto(context, foto, nama),
                                              child: Stack(
                                                alignment: Alignment.bottomRight,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 26,
                                                    backgroundColor: const Color(0xFFDCE8F5),
                                                    backgroundImage: hasPhoto
                                                        ? (foto.startsWith('http')
                                                            ? NetworkImage(foto)
                                                            : (kIsWeb
                                                                ? NetworkImage(foto)
                                                                : FileImage(File(foto)) as ImageProvider))
                                                        : null,
                                                    child: !hasPhoto
                                                        ? const Icon(Icons.person, color: Color(0xFF1B4965), size: 28)
                                                        : null,
                                                  ),
                                                  if (hasPhoto)
                                                    Container(
                                                      padding: const EdgeInsets.all(3),
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xFF145E53),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(Icons.zoom_in, color: Colors.white, size: 12),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 14),

                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    nama,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14.5,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'NPM: ${member['npm'] ?? '-'}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF616161),
                                                    ),
                                                  ),
                                                  Text(
                                                    member['prodi'] ?? 'Informatika',
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color: Color(0xFF8A9099),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 16,
                                              color: Color(0xFFB0B7C3),
                                            ),
                                          ],
                                        ),
                                      ),
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