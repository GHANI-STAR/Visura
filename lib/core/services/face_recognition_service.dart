import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

class FaceRecognitionService {
  static const double similarityThreshold = 0.80;

  static Future<List<double>> extractEmbedding(Uint8List imageBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 16,
        targetHeight: 16,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
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
      return [];
    }
  }

  static double calculateCosineSimilarity(List<double> vectorA, List<double> vectorB) {
    if (vectorA.length != vectorB.length || vectorA.isEmpty) return 0.0;
    double dotProduct = 0.0;
    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
    }
    return dotProduct;
  }

  static Map<String, dynamic>? matchFace(
    List<double> currentEmbedding,
    List<Map<String, dynamic>> registeredMembers,
  ) {
    if (currentEmbedding.isEmpty) return null;

    Map<String, dynamic>? bestMatch;
    double highestSimilarity = -1.0;

    for (var member in registeredMembers) {
      if (member['face_embedding'] == null) continue;

      final raw = member['face_embedding'] as List;
      final savedEmbedding = raw.map((e) => (e as num).toDouble()).toList();

      final similarity = calculateCosineSimilarity(currentEmbedding, savedEmbedding);

      if (similarity >= similarityThreshold && similarity > highestSimilarity) {
        highestSimilarity = similarity;
        bestMatch = member;
      }
    }

    return bestMatch;
  }
}