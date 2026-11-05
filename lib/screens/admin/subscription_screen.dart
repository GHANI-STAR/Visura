import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/database/firebase_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Tagihan Semester?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Semua anggota akan diubah statusnya menjadi Belum Lunas untuk memulai tagihan semester baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC02227),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.resetSemesterSubscriptions();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tagihan semester berhasil di-reset untuk seluruh anggota!'),
                    backgroundColor: Color(0xFF145E53),
                  ),
                );
              }
            },
            child: const Text('Ya, Reset Semua', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetailModal(Map<String, dynamic> member) {
    final tagihan = member['tagihan'] ?? '2.000,00';
    final foto = member['foto']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6DBE2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Rincian Pembayaran Iuran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E4E8)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFDCE8F5),
                        backgroundImage: foto.isNotEmpty
                            ? (foto.startsWith('http')
                                ? NetworkImage(foto)
                                : (kIsWeb
                                    ? NetworkImage(foto)
                                    : FileImage(File(foto)) as ImageProvider))
                            : null,
                        child: foto.isEmpty
                            ? const Icon(Icons.person, color: Color(0xFF1B4965))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member['nama'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'NPM: ${member['npm'] ?? '-'} • ${member['prodi'] ?? 'Informatika'}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Iuran Semester',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF145E53)),
                      ),
                      Text(
                        'Rp $tagihan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF145E53),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Pilih Metode Pembayaran',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pop(bCtx);
                    _showQrisPaymentDialog(member);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF145E53), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF145E53), size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QRIS (E-Wallet / M-Banking)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Scan barcode instan GoPay, OVO, ShopeePay, BCA',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    Navigator.pop(bCtx);
                    await _processPayment(member, 'Tunai');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD6DBE2), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.payments_rounded, color: Color(0xFF0F364E), size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tunai / Cash',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Bayar langsung melalui kasir perpus',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQrisPaymentDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (qCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pembayaran QRIS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(qCtx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${member['nama']} (${member['npm']})',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E4E8)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 160, color: Color(0xFF0F364E)),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${member['tagihan'] ?? '2.000,00'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF145E53)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF145E53),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(qCtx);
                  await _processPayment(member, 'QRIS');
                },
                child: const Text(
                  'Konfirmasi Pembayaran Selesai',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(Map<String, dynamic> member, String method) async {
    await DatabaseService.paySubscription(member['id'], method);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iuran ${member['nama']} berhasil dilunasi via $method!'),
        backgroundColor: const Color(0xFF145E53),
      ),
    );
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
                      'Pembayaran',
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
                    children: [
                      const SizedBox(height: 18),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2E4E8), width: 1.2),
                          ),
                          child: TextField(
                            controller: _searchController,
                            textAlignVertical: TextAlignVertical.center,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Input NPM Mahasiswa',
                              hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13.5),
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

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: _showResetConfirmDialog,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFA39E)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restart_alt_rounded, color: Color(0xFFC02227), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Reset Tagihan Semester Baru',
                                  style: TextStyle(
                                    color: Color(0xFFC02227),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: DatabaseService.getUnpaidMembers(),
                          builder: (context, snapshot) {
                            final list = snapshot.data ?? [];
                            final filtered = list.where((m) {
                              final npm = m['npm']?.toString().toLowerCase() ?? '';
                              final nama = m['nama']?.toString().toLowerCase() ?? '';
                              final q = _searchQuery.toLowerCase();
                              return npm.contains(q) || nama.contains(q);
                            }).toList();

                            if (filtered.isEmpty) {
                              return const Center(
                                child: Text('Tidak ada tunggakan iuran.', style: TextStyle(color: Colors.grey)),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final member = filtered[index];
                                final foto = member['foto']?.toString() ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: const Color(0xFFDCE8F5),
                                        backgroundImage: foto.isNotEmpty
                                            ? (foto.startsWith('http')
                                                ? NetworkImage(foto)
                                                : (kIsWeb
                                                    ? NetworkImage(foto)
                                                    : FileImage(File(foto)) as ImageProvider))
                                            : null,
                                        child: foto.isEmpty
                                            ? const Icon(Icons.person, color: Color(0xFF1B4965))
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              member['nama'] ?? '-',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            Text(
                                              'NPM: ${member['npm'] ?? '-'}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Kekurangan: Rp ${member['kekurangan_iuran'] ?? '2,000'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFC02227),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF145E53),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                        onPressed: () => _showPaymentDetailModal(member),
                                        child: const Text('Bayar', style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ),
                                    ],
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