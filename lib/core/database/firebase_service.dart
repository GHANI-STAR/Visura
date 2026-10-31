import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class DatabaseService {
  // Cek apakah Firebase sudah diinisialisasi
  static bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  // ===========================================================================
  // 1. STATISTIK DASHBOARD
  // ===========================================================================
  static final _statsController = StreamController<Map<String, dynamic>>.broadcast();
  static Map<String, dynamic> _currentStats = {
    'total_pengunjung': '120',
    'buku_dipinjam': '1',
    'buku_lewat': '26',
    'tunggakan_iuran': '1',
  };

  static Stream<Map<String, dynamic>> getDashboardStats() {
    if (isFirebaseReady) {
      return FirebaseFirestore.instance
          .collection('dashboard')
          .doc('stats')
          .snapshots()
          .map((doc) => doc.exists ? doc.data()! : _currentStats);
    }
    Future.microtask(() => _statsController.add(_currentStats));
    return _statsController.stream;
  }

  // ===========================================================================
  // 2. LOG PENGUNJUNG (PRESENSI KIOSK OTOMATIS)
  // ===========================================================================
// ==========================================
  // LOG PENGUNJUNG (PRESENSI KIOSK OTOMATIS)
  // ==========================================
  static final _visitorLogsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  static final List<Map<String, dynamic>> _visitorLogsList = [];

  // Set untuk mendata NPM mahasiswa yang sedang berada di dalam perpus
  static final Set<String> _activeInsideNPMs = {};

  static Stream<List<Map<String, dynamic>>> getVisitorLogs() {
    if (isFirebaseReady) {
      return FirebaseFirestore.instance
          .collection('visitor_logs')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    }
    Future.microtask(() => _visitorLogsController.add(List.from(_visitorLogsList)));
    return _visitorLogsController.stream;
  }

  // Dipanggil otomatis oleh kamera Kiosk saat wajah terdeteksi
  static Future<String> recordVisitor(String nama, String npm, {String? foto}) async {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 1. Cek apakah mahasiswa sedang berada di dalam perpustakaan
    final bool isInside = _activeInsideNPMs.contains(npm);
    final String aksi = isInside ? 'Keluar' : 'Mengunjungi';

    // 2. Update status keberadaan mahasiswa di perpustakaan
    if (isInside) {
      _activeInsideNPMs.remove(npm); // Mahasiswa keluar
    } else {
      _activeInsideNPMs.add(npm); // Mahasiswa masuk
    }

    // 3. Update counter total orang yang ada di dalam perpus secara real-time
    final int jumlahDiPerpus = _activeInsideNPMs.length;
    _currentStats['total_pengunjung'] = jumlahDiPerpus.toString();
    _statsController.add(_currentStats);

    // Cari foto mahasiswa jika tidak dilempar langsung
    String memberPhoto = foto ?? '';
    if (memberPhoto.isEmpty) {
      final found = _membersList.firstWhere(
        (m) => m['npm'].toString().trim() == npm.trim(),
        orElse: () => {},
      );
      memberPhoto = found['foto']?.toString() ?? '';
    }

    final newLog = {
      'aksi': aksi,
      'user': '${nama}_$npm',
      'nama': nama,
      'npm': npm,
      'foto': memberPhoto,
      'waktu': timeStr,
    };

    if (isFirebaseReady) {
      await FirebaseFirestore.instance.collection('visitor_logs').add({
        ...newLog,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('dashboard').doc('stats').update({
        'total_pengunjung': jumlahDiPerpus,
      });
      return aksi;
    }

    // Log terbaru selalu disisipkan di baris paling atas
    _visitorLogsList.insert(0, newLog);
    _visitorLogsController.add(List.from(_visitorLogsList));

    return aksi;
  }

  // ===========================================================================
  // 3. ANGGOTA & BIOMETRIK (CRUD)
  // ===========================================================================
  static final _membersController = StreamController<List<Map<String, dynamic>>>.broadcast();
  static final List<Map<String, dynamic>> _membersList = [
    {
      'id': 'mem_1',
      'nama': 'Gibran Rakabuming',
      'npm': '5240411167',
      'prodi': 'Marketing',
      'tanggal_lahir': '6 Juli 1967',
      'lunas': true,
      'foto': '',
      'biometrik_terdaftar': true,
      'borrowed_books': <Map<String, dynamic>>[
        {'kode': '67676767', 'judul': 'Super Maharaja King Afif Murtadho'},
      ],
      'kekurangan_iuran': '0',
    },
    {
      'id': 'mem_2',
      'nama': 'Adam Zidane',
      'npm': '5240411161',
      'prodi': 'Informatika',
      'tanggal_lahir': '12 Agustus 2004',
      'lunas': false,
      'foto': '',
      'biometrik_terdaftar': false,
      'borrowed_books': <Map<String, dynamic>>[],
      'kekurangan_iuran': '2,000',
      'tagihan': '1.990.000,00',
    },
  ];

  static Stream<List<Map<String, dynamic>>> getMembers() {
    if (isFirebaseReady) {
      return FirebaseFirestore.instance
          .collection('members')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
    }
    Future.microtask(() => _membersController.add(List.from(_membersList)));
    return _membersController.stream;
  }

  static Future<void> addMember(Map<String, dynamic> data) async {
    final newMember = {
      ...data,
      'id': 'mem_${DateTime.now().millisecondsSinceEpoch}',
      'borrowed_books': <Map<String, dynamic>>[],
    };

    if (isFirebaseReady) {
      await FirebaseFirestore.instance.collection('members').add(newMember);
      return;
    }

    _membersList.insert(0, newMember);
    _membersController.add(List.from(_membersList));
  }

  static Future<void> updateMember(String id, Map<String, dynamic> data) async {
    if (isFirebaseReady) {
      await FirebaseFirestore.instance.collection('members').doc(id).update(data);
      return;
    }

    final index = _membersList.indexWhere((m) => m['id'] == id);
    if (index != -1) {
      _membersList[index] = {..._membersList[index], ...data};
      _membersController.add(List.from(_membersList));
    }
  }

  static Future<void> deleteMember(String id) async {
    if (isFirebaseReady) {
      await FirebaseFirestore.instance.collection('members').doc(id).delete();
      return;
    }

    _membersList.removeWhere((m) => m['id'] == id);
    _membersController.add(List.from(_membersList));
  }

  // ===========================================================================
  // 4. IURAN & LANGGANAN
  // ===========================================================================
  static Stream<List<Map<String, dynamic>>> getUnpaidMembers() {
    return getMembers().map((list) => list.where((m) => m['lunas'] == false).toList());
  }

  static Future<void> paySubscription(String id, String method) async {
    await updateMember(id, {'lunas': true, 'kekurangan_iuran': '0'});

    if (isFirebaseReady) {
      await FirebaseFirestore.instance.collection('dashboard').doc('stats').update({
        'tunggakan_iuran': FieldValue.increment(-1),
      });
      return;
    }

    int sisa = int.tryParse(_currentStats['tunggakan_iuran'].toString()) ?? 1;
    _currentStats['tunggakan_iuran'] = (sisa > 0 ? sisa - 1 : 0).toString();
    _statsController.add(_currentStats);
  }

  // ===========================================================================
  // 5. KATALOG BUKU (CRUD)
  // ===========================================================================
  static final _booksController = StreamController<List<Map<String, dynamic>>>.broadcast();
  static final List<Map<String, dynamic>> _booksList = [
    {
      'id': 'book_1',
      'judul': 'Super Maharaja King Afif Murtadho',
      'kode': '67676767',
      'penulis': 'Odhatrum Fifa',
      'kategori': 'Pendadaran',
      'tahun_terbit': '2067',
      'deskripsi': 'Kisah seorang pewaris terkenal yang dijuluki King Fif, dengan fokus pada sejarah perjalanan dia.',
      'cover': '',
    },
    {
      'id': 'book_2',
      'judul': 'Indonesia Emas Islam ala Prabowo',
      'kode': '17081945',
      'penulis': 'Prabowo Subianto',
      'kategori': 'Sosial Politik',
      'tahun_terbit': '2024',
      'deskripsi': 'Gagasan besar menuju era keemasan Indonesia dengan fondasi kebangsaan dan nilai luhur.',
      'cover': '',
    },
  ];

  static Stream<List<Map<String, dynamic>>> getBooks() {
    if (isFirebaseReady) {
      return FirebaseFirestore.instance
          .collection('books')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
    }
    Future.microtask(() => _booksController.add(List.from(_booksList)));
    return _booksController.stream;
  }

  static Future<void> addBook(Map<String, dynamic> data) async {
    final newBook = {
      ...data,
      'id': 'book_${DateTime.now().millisecondsSinceEpoch}',
    };

    if (isFirebaseReady) {
      await FirebaseFirestore.instance.collection('books').add(newBook);
      return;
    }

    _booksList.insert(0, newBook);
    _booksController.add(List.from(_booksList));
  }

  static Future<void> updateBook(String id, Map<String, dynamic> data) async {
    if (isFirebaseReady) {
      await FirebaseFirestore.instance.collection('books').doc(id).update(data);
      return;
    }

    final index = _booksList.indexWhere((b) => b['id'] == id);
    if (index != -1) {
      _booksList[index] = {..._booksList[index], ...data};
      _booksController.add(List.from(_booksList));
    }
  }

  static Future<void> deleteBook(String id) async {
    if (isFirebaseReady) {
      await FirebaseFirestore.instance.collection('books').doc(id).delete();
      return;
    }

    _booksList.removeWhere((b) => b['id'] == id);
    _booksController.add(List.from(_booksList));
  }

  // ===========================================================================
  // 6. SISTEM SIRKULASI BUKU (PINJAM & KEMBALIKAN)
  // ===========================================================================
  static Future<String?> borrowBookToMember(String memberId, Map<String, dynamic> bookData) async {
    final memberIndex = _membersList.indexWhere((m) => m['id'] == memberId);
    if (memberIndex == -1) return 'Mahasiswa tidak ditemukan!';

    final member = _membersList[memberIndex];
    List<dynamic> rawList = member['borrowed_books'] ?? [];
    List<Map<String, dynamic>> borrowed = rawList.map((e) => Map<String, dynamic>.from(e)).toList();

    final alreadyBorrowed = borrowed.any((b) => b['kode'] == bookData['kode']);
    if (alreadyBorrowed) {
      return 'Mahasiswa ini sudah sedang meminjam buku ini!';
    }

    borrowed.add({
      'kode': bookData['kode'],
      'judul': bookData['judul'],
      'tanggal': DateTime.now().toString().substring(0, 10),
    });

    if (isFirebaseReady) {
      await FirebaseFirestore.instance.collection('members').doc(memberId).update({
        'borrowed_books': borrowed,
      });
      await FirebaseFirestore.instance.collection('dashboard').doc('stats').update({
        'buku_dipinjam': FieldValue.increment(1),
      });
      return null;
    }

    _membersList[memberIndex]['borrowed_books'] = borrowed;
    _membersController.add(List.from(_membersList));

    int total = int.tryParse(_currentStats['buku_dipinjam'].toString()) ?? 0;
    _currentStats['buku_dipinjam'] = (total + 1).toString();
    _statsController.add(_currentStats);

    return null;
  }

  static Future<String?> returnBookFromMember(String memberId, String bookKode) async {
    final memberIndex = _membersList.indexWhere((m) => m['id'] == memberId);
    if (memberIndex == -1) return 'Mahasiswa tidak ditemukan!';

    final member = _membersList[memberIndex];
    List<dynamic> rawList = member['borrowed_books'] ?? [];
    List<Map<String, dynamic>> borrowed = rawList.map((e) => Map<String, dynamic>.from(e)).toList();

    final bookIndex = borrowed.indexWhere((b) => b['kode'] == bookKode);
    if (bookIndex == -1) {
      return 'Mahasiswa ini tidak sedang meminjam buku ini!';
    }

    borrowed.removeAt(bookIndex);

    if (isFirebaseReady) {
      await FirebaseFirestore.instance.collection('members').doc(memberId).update({
        'borrowed_books': borrowed,
      });
      await FirebaseFirestore.instance.collection('dashboard').doc('stats').update({
        'buku_dipinjam': FieldValue.increment(-1),
      });
      return null;
    }

    _membersList[memberIndex]['borrowed_books'] = borrowed;
    _membersController.add(List.from(_membersList));

    int total = int.tryParse(_currentStats['buku_dipinjam'].toString()) ?? 0;
    _currentStats['buku_dipinjam'] = (total > 0 ? total - 1 : 0).toString();
    _statsController.add(_currentStats);

    return null;
  }
}