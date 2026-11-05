import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/database/firebase_service.dart';
import 'member_list_screen.dart';
import 'book_list_screen.dart';
import 'subscription_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardTab(),
    MemberListScreen(),
    BookListScreen(),
    SubscriptionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0E000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.groups_rounded, 'Anggota'),
                _buildNavItem(2, Icons.menu_book_rounded, 'Buku'),
                _buildNavItem(3, Icons.account_balance_wallet_rounded, 'Langganan'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF145E53) : const Color(0xFF9E9E9E);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: 315, 
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F364E), 
                    Color(0xFF145E53), 
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.swap_horiz_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: 'Ganti Perangkat',
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    StreamBuilder<Map<String, dynamic>>(
                      stream: DatabaseService.getDashboardStats(),
                      builder: (context, snapshot) {
                        final stats = snapshot.data ?? {};
                        final diPerpus = stats['total_pengunjung']?.toString() ?? '0';
                        final pinjam = stats['buku_dipinjam']?.toString() ?? '0';
                        final lewat = stats['buku_lewat']?.toString() ?? '0';
                        final tunggakan = stats['tunggakan_iuran']?.toString() ?? '0';

                        return GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.08,
                          children: [
                            _buildStatBox(
                              value: diPerpus,
                              title: 'Pengunjung di Perpus',
                              icon: Icons.people_alt_rounded,
                              circleColor: const Color(0xFF0F364E),
                            ),
                            _buildStatBox(
                              value: pinjam,
                              title: 'Buku Dipinjam',
                              icon: Icons.menu_book_rounded,
                              circleColor: const Color(0xFF145E53),
                            ),
                            _buildStatBox(
                              value: lewat,
                              title: 'Buku Tenggat',
                              icon: Icons.access_time_filled_rounded,
                              circleColor: const Color(0xFFBA1A1A),
                            ),
                            _buildStatBox(
                              value: tunggakan,
                              title: 'Tunggakan Iuran',
                              icon: Icons.account_balance_wallet_rounded,
                              circleColor: const Color(0xFFBA1A1A),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 26),

                    const Text(
                      'LOG PENGUNJUNG',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: DatabaseService.getVisitorLogs(),
                        builder: (context, snapshot) {
                          final logs = snapshot.data ?? [];

                          if (logs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  'Belum ada aktivitas presensi pengunjung.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: logs.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              thickness: 0.8,
                              indent: 68,
                              endIndent: 16,
                              color: Color(0xFFEEEEEE),
                            ),
                            itemBuilder: (context, index) {
                              final log = logs[index];
                              final foto = log['foto']?.toString() ?? '';
                              final bool isKeluar = (log['aksi'] ?? '').toString() == 'Keluar';

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFFD6E2EC),
                                      backgroundImage: foto.isNotEmpty
                                          ? (foto.startsWith('http')
                                              ? NetworkImage(foto)
                                              : (kIsWeb
                                                  ? NetworkImage(foto)
                                                  : FileImage(File(foto)) as ImageProvider))
                                          : null,
                                      child: foto.isEmpty
                                          ? const Icon(Icons.person, color: Color(0xFF1B4965), size: 22)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            log['aksi'] ?? 'Mengunjungi',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: isKeluar ? const Color(0xFFE65100) : const Color(0xFF145E53),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            log['user'] ?? '-',
                                            style: const TextStyle(
                                              color: Color(0xFF757575),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      log['waktu'] ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String value,
    required String title,
    required IconData icon,
    required Color circleColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25), 
          Text(
            title,
            style: const TextStyle(
              fontSize: 13, 
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2B2B),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}