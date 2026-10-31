import 'package:flutter/material.dart';
import '../../core/database/firebase_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _selectedMember;
  String _selectedMethod = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPaymentModal(String method) {
    setState(() => _selectedMethod = method);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final nominal = _selectedMember?['kekurangan_iuran']?.toString() ?? '2,000';

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                method == 'QRIS' ? 'Pembayaran via QRIS' : 'Konfirmasi Pembayaran Tunai',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (method == 'QRIS') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, size: 150, color: Color(0xFF145E53)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Scan kode QR untuk pelunasan iuran Rp $nominal',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ] else ...[
                const Icon(Icons.payments_outlined, size: 70, color: Color(0xFF145E53)),
                const SizedBox(height: 12),
                Text(
                  'Pastikan uang tunai sebesar Rp $nominal telah diterima dari mahasiswa bersangkutan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF424242), fontSize: 14),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF145E53),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final nama = _selectedMember!['nama'];
                  final id = _selectedMember!['id'];

                  await DatabaseService.paySubscription(id, method);

                  if (!mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pembayaran $method berhasil! Status $nama kini lunas.'),
                      backgroundColor: const Color(0xFF145E53),
                    ),
                  );

                  setState(() {
                    _selectedMember = null;
                    _selectedMethod = '';
                  });
                },
                child: const Text(
                  'Konfirmasi Lunas',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ornamen Header Melengkung Seragam dengan Beranda
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F364E), // Navy gelap
                    Color(0xFF145E53), // Emerald teal
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
                  child: Column(
                    children: [
                      // Header Logo & Judul
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
                      const SizedBox(height: 18),

                      // Input Cari NPM Mahasiswa
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x10000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: (val) => setState(() {}),
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
                    ],
                  ),
                ),
              ),
            ),

            // 2. Konten Dinamis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HANYA MUNCUL JIKA ADA MAHASISWA YANG DIKLIK
                  if (_selectedMember != null) ...[
                    // Kartu Data Mahasiswa Terpilih
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFEAEAEA),
                            backgroundImage: _selectedMember!['foto'] != null && _selectedMember!['foto'] != ''
                                ? NetworkImage(_selectedMember!['foto'])
                                : null,
                            child: _selectedMember!['foto'] == null || _selectedMember!['foto'] == ''
                                ? const Icon(Icons.person, size: 30, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedMember!['nama'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedMember!['npm'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            tooltip: 'Batal Pilih',
                            onPressed: () {
                              setState(() {
                                _selectedMember = null;
                                _selectedMethod = '';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kotak Nominal Kekurangan Iuran
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Kekurangan Iuran',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rp ${_selectedMember!['kekurangan_iuran'] ?? '2,000'}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tombol Metode Pembayaran (QRIS & Tunai)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showPaymentModal('QRIS'),
                            child: Container(
                              height: 115,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _selectedMethod == 'QRIS' ? const Color(0xFF145E53) : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_2_rounded, size: 46, color: Colors.black87),
                                  SizedBox(height: 8),
                                  Text(
                                    'QRIS',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showPaymentModal('Tunai'),
                            child: Container(
                              height: 115,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _selectedMethod == 'Tunai' ? const Color(0xFF145E53) : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payments_rounded, size: 46, color: Color(0xFF1B6B5D)),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tunai',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // DAFTAR MAHASISWA BELUM BAYAR
                  const Text(
                    'Mahasiswa Belum Bayar Langganan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: DatabaseService.getUnpaidMembers(),
                    builder: (context, snapshot) {
                      final list = snapshot.data ?? [];

                      // Filter realtime dari kolom pencarian NPM
                      final query = _searchController.text.trim().toLowerCase();
                      final filteredList = list.where((item) {
                        final npm = item['npm']?.toString().toLowerCase() ?? '';
                        final nama = item['nama']?.toString().toLowerCase() ?? '';
                        return npm.contains(query) || nama.contains(query);
                      }).toList();

                      if (filteredList.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              'Tidak ada tunggakan iuran yang ditemukan.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            thickness: 0.8,
                            indent: 70,
                            endIndent: 16,
                            color: Color(0xFFEEEEEE),
                          ),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final tagihan = item['tagihan'] ?? '1.990.000,00';

                            return InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () {
                                setState(() {
                                  _selectedMember = item;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: const Color(0xFFEAEAEA),
                                      backgroundImage: item['foto'] != null && item['foto'] != ''
                                          ? NetworkImage(item['foto'])
                                          : null,
                                      child: item['foto'] == null || item['foto'] == ''
                                          ? const Icon(Icons.person, color: Colors.grey)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['nama'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['npm'] ?? '-',
                                            style: const TextStyle(
                                              color: Color(0xFF616161),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Rp $tagihan',
                                      style: const TextStyle(
                                        color: Color(0xFFC02227),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}