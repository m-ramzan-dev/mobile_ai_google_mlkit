import 'dart:math';
import 'models.dart';

class Vec2 {
  final double x;
  final double y;

  const Vec2(this.x, this.y);
}

double pointDistance(PosePoint a, PosePoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return sqrt(dx * dx + dy * dy);
}

/// Returns angle ABC in degrees.
double calculateAngle(PosePoint a, PosePoint b, PosePoint c) {
  final ab = Vec2(a.x - b.x, a.y - b.y);
  final cb = Vec2(c.x - b.x, c.y - b.y);

  final dot = ab.x * cb.x + ab.y * cb.y;
  final mag1 = sqrt(ab.x * ab.x + ab.y * ab.y);
  final mag2 = sqrt(cb.x * cb.x + cb.y * cb.y);

  if (mag1 == 0 || mag2 == 0) return 0.0;

  final cosine = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
  return acos(cosine) * 180 / pi;
}

bool allReliable(List<PosePoint?> points, {double minLikelihood = 0.6}) {
  for (final p in points) {
    if (p == null || p.likelihood < minLikelihood) return false;
  }
  return true;
}

class MovingAverage {
  final int size;
  final List<double> _values = [];

  MovingAverage(this.size);

  double add(double value) {
    _values.add(value);
    if (_values.length > size) {
      _values.removeAt(0);
    }
    return average;
  }

  double get average {
    if (_values.isEmpty) return 0;
    return _values.reduce((a, b) => a + b) / _values.length;
  }

  void clear() {
    _values.clear();
  }
}