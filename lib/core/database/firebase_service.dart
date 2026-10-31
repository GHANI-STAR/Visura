import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static bool isMemberInside(String npm) {
    return _activeInsideNPMs.contains(npm.trim());
  }
  static bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  static final _statsController = StreamController<Map<String, dynamic>>.broadcast();
  static Map<String, dynamic> _currentStats = {
    'total_pengunjung': '0',
    'buku_dipinjam': '1',
    'buku_lewat': '0',
    'tunggakan_iuran': '1',
  };

  static void _updateStats() {
    _currentStats['buku_lewat'] = getOverdueCount().toString();
    _currentStats['tunggakan_iuran'] = _membersList.where((m) => m['lunas'] == false).length.toString();
    _currentStats['total_pengunjung'] = _activeInsideNPMs.length.toString();
    _statsController.add(Map.from(_currentStats));
  }

  static Stream<Map<String, dynamic>> getDashboardStats() {
    Timer.periodic(const Duration(seconds: 10), (_) => _updateStats());
    Future.microtask(() => _updateStats());
    return _statsController.stream;
  }

  static final _visitorLogsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  static final List<Map<String, dynamic>> _visitorLogsList = [];
  static final Set<String> _activeInsideNPMs = {};

  static Stream<List<Map<String, dynamic>>> getVisitorLogs() {
    Future.microtask(() => _visitorLogsController.add(List.from(_visitorLogsList)));
    return _visitorLogsController.stream;
  }

  static Future<String> recordVisitor(String nama, String npm, {String? foto}) async {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final bool isInside = _activeInsideNPMs.contains(npm);
    final String aksi = isInside ? 'Keluar' : 'Mengunjungi';

    if (isInside) {
      _activeInsideNPMs.remove(npm);
    } else {
      _activeInsideNPMs.add(npm);
    }

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

    _visitorLogsList.insert(0, newLog);
    _visitorLogsController.add(List.from(_visitorLogsList));
    _updateStats();

    return aksi;
  }

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
        {
          'kode': '67676767',
          'judul': 'Super Maharaja King Afif Murtadho',
          'borrowed_at': DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(),
        },
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
      'tagihan': '2.000,00',
    },
  ];

  static Stream<List<Map<String, dynamic>>> getMembers() {
    Future.microtask(() => _membersController.add(List.from(_membersList)));
    return _membersController.stream;
  }

  static Future<void> addMember(Map<String, dynamic> data) async {
    final newMember = {
      ...data,
      'id': 'mem_${DateTime.now().millisecondsSinceEpoch}',
      'lunas': false, 
      'kekurangan_iuran': '2,000',
      'tagihan': '2.000,00',
      'borrowed_books': <Map<String, dynamic>>[],
    };
    _membersList.insert(0, newMember);
    _membersController.add(List.from(_membersList));
    _updateStats();
  }

  static Future<void> updateMember(String id, Map<String, dynamic> data) async {
    final index = _membersList.indexWhere((m) => m['id'] == id);
    if (index != -1) {
      _membersList[index] = {..._membersList[index], ...data};
      _membersController.add(List.from(_membersList));
      _updateStats();
    }
  }

  static Future<void> deleteMember(String id) async {
    _membersList.removeWhere((m) => m['id'] == id);
    _membersController.add(List.from(_membersList));
    _updateStats();
  }

  static Future<void> resetSemesterSubscriptions() async {
    for (var member in _membersList) {
      member['lunas'] = false;
      member['kekurangan_iuran'] = '2,000';
      member['tagihan'] = '2.000,00';
    }
    _membersController.add(List.from(_membersList));
    _updateStats();
  }

  static Stream<List<Map<String, dynamic>>> getUnpaidMembers() {
    return getMembers().map((list) => list.where((m) => m['lunas'] == false).toList());
  }

  static Future<void> paySubscription(String id, String method) async {
    await updateMember(id, {'lunas': true, 'kekurangan_iuran': '0'});
  }

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
    Future.microtask(() => _booksController.add(List.from(_booksList)));
    return _booksController.stream;
  }

  static Future<void> addBook(Map<String, dynamic> data) async {
    final newBook = {
      ...data,
      'id': 'book_${DateTime.now().millisecondsSinceEpoch}',
    };
    _booksList.insert(0, newBook);
    _booksController.add(List.from(_booksList));
  }

  static Future<void> updateBook(String id, Map<String, dynamic> data) async {
    final index = _booksList.indexWhere((b) => b['id'] == id);
    if (index != -1) {
      _booksList[index] = {..._booksList[index], ...data};
      _booksController.add(List.from(_booksList));
    }
  }

  static Future<void> deleteBook(String id) async {
    _booksList.removeWhere((b) => b['id'] == id);
    _booksController.add(List.from(_booksList));
  }

  static Future<String?> borrowBookToMember(String memberId, Map<String, dynamic> bookData) async {
    final memberIndex = _membersList.indexWhere((m) => m['id'] == memberId);
    if (memberIndex == -1) return 'Mahasiswa tidak ditemukan!';

    final member = _membersList[memberIndex];
    List<dynamic> rawList = member['borrowed_books'] ?? [];
    List<Map<String, dynamic>> borrowed = rawList.map((e) => Map<String, dynamic>.from(e)).toList();

    if (borrowed.any((b) => b['kode'] == bookData['kode'])) {
      return 'Mahasiswa ini sedang meminjam buku ini!';
    }

    borrowed.add({
      'kode': bookData['kode'],
      'judul': bookData['judul'],
      'borrowed_at': DateTime.now().toIso8601String(),
    });

    _membersList[memberIndex]['borrowed_books'] = borrowed;
    _membersController.add(List.from(_membersList));
    _updateStats();
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
    _membersList[memberIndex]['borrowed_books'] = borrowed;
    _membersController.add(List.from(_membersList));
    _updateStats();
    return null;
  }

  static int getOverdueCount() {
    int overdue = 0;
    final now = DateTime.now();
    for (var member in _membersList) {
      final list = member['borrowed_books'] as List? ?? [];
      for (var b in list) {
        final at = DateTime.tryParse(b['borrowed_at']?.toString() ?? '');
        if (at != null && now.difference(at).inSeconds >= 120) {
          overdue++;
        }
      }
    }
    return overdue;
  }

  static Map<String, dynamic> checkDueStatus(String? borrowedAtStr) {
    if (borrowedAtStr == null) return {'isOverdue': false, 'text': '-'};
    final borrowedAt = DateTime.tryParse(borrowedAtStr);
    if (borrowedAt == null) return {'isOverdue': false, 'text': '-'};

    final diffSeconds = DateTime.now().difference(borrowedAt).inSeconds;
    const limitSeconds = 120; 

    if (diffSeconds >= limitSeconds) {
      final lateMin = (diffSeconds - limitSeconds) ~/ 60;
      return {
        'isOverdue': true,
        'text': lateMin > 0 ? 'Terlambat ($lateMin mnt)' : 'Terlambat (>2 mnt)',
      };
    } else {
      final sisa = limitSeconds - diffSeconds;
      return {
        'isOverdue': false,
        'text': 'Sisa ${sisa}s',
      };
    }
  }

  static List<Map<String, dynamic>> getBorrowersOfBook(String bookKode) {
    final List<Map<String, dynamic>> list = [];
    for (var m in _membersList) {
      final bList = m['borrowed_books'] as List? ?? [];
      for (var b in bList) {
        if (b['kode'] == bookKode) {
          final due = checkDueStatus(b['borrowed_at']);
          list.add({
            'nama': m['nama'],
            'npm': m['npm'],
            'prodi': m['prodi'],
            'foto': m['foto'],
            'status_tenggat': due['text'],
            'isOverdue': due['isOverdue'],
          });
        }
      }
    }
    return list;
  }
}
class AppNotification {
  static final ValueNotifier<bool> isVisible = ValueNotifier<bool>(false);

  static void show(
    BuildContext context,
    String message, {
    Color backgroundColor = const Color(0xFF145E53),
    Duration duration = const Duration(seconds: 3),
  }) {
    isVisible.value = true;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );

    controller.closed.then((_) {
      isVisible.value = false;
    });
  }
}