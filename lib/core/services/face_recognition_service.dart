import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

typedef JsonMap = Map<String, dynamic>;

class FaceRecognitionService {
  static const double similarityThreshold = 0.60;

  static Future<List<double>> extractEmbedding(Uint8List imageBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 16,
        targetHeight: 16,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return [];

      final pixels = byteData.buffer.asUint8List();
      List<double> rawVector = [];

      for (int i = 0; i < pixels.length; i += 4) {
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];
        final gray = (0.299 * r + 0.587 * g + 0.114 * b);
        rawVector.add(gray);
      }

      double sumSquares = 0.0;
      for (var val in rawVector) {
        sumSquares += val * val;
      }
      final norm = sqrt(sumSquares);
      if (norm == 0) return rawVector;

      return rawVector.map((v) => v / norm).toList();
    } catch (e) {
      debugPrint('Error extractEmbedding: $e');
      return [];
    }
  }

  static double calculateCosineSimilarity(
    List<double> vectorA,
    List<double> vectorB,
  ) {
    if (vectorA.length != vectorB.length || vectorA.isEmpty) return 0.0;

    double dotProduct = 0.0;
    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
    }
    return dotProduct;
  }

  static JsonMap? matchFace(
    List<double> currentEmbedding,
    List<JsonMap> registeredMembers, {
    double threshold = 0.60,
  }) {
    if (currentEmbedding.isEmpty || registeredMembers.isEmpty) return null;

    JsonMap? bestMatch;
    double highestScore = -1.0;

    for (final member in registeredMembers) {
      double maxMemberScore = -1.0;

      // 1. Cek kunci 'embeddings' (Multi-angle List)
      final dynamic rawMulti = member['embeddings'];
      if (rawMulti is List && rawMulti.isNotEmpty) {
        for (final rawEmb in rawMulti) {
          if (rawEmb is List && rawEmb.isNotEmpty) {
            final vector = rawEmb.map((e) => (e as num).toDouble()).toList();
            final score = calculateCosineSimilarity(currentEmbedding, vector);
            if (score > maxMemberScore) maxMemberScore = score;
          }
        }
      }

      // 2. Cek kunci 'face_embedding' (Format default yang disimpan AddMember)
      final dynamic rawFaceEmb = member['face_embedding'];
      if (rawFaceEmb is List && rawFaceEmb.isNotEmpty) {
        final vector = rawFaceEmb.map((e) => (e as num).toDouble()).toList();
        final score = calculateCosineSimilarity(currentEmbedding, vector);
        if (score > maxMemberScore) maxMemberScore = score;
      }

      // 3. Cek kunci 'embedding' (Format tunggal alternatif)
      final dynamic rawSingle = member['embedding'];
      if (rawSingle is List && rawSingle.isNotEmpty) {
        final vector = rawSingle.map((e) => (e as num).toDouble()).toList();
        final score = calculateCosineSimilarity(currentEmbedding, vector);
        if (score > maxMemberScore) maxMemberScore = score;
      }

      // Evaluasi skor tertinggi untuk anggota ini
      if (maxMemberScore > highestScore) {
        highestScore = maxMemberScore;
        bestMatch = member;
      }
    }

    debugPrint('📊 Skor tertinggi yang didapat: $highestScore (Target minimal: $threshold)');

    if (highestScore >= threshold) {
      return bestMatch;
    }

    return null;
  }
}