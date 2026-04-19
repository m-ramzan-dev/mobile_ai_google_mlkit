import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum ExerciseType { squat, pushUp, lunge }

enum MotionStage {
  unknown,
  standing,
  bottom,
  up,
  down,
  leftDown,
  rightDown,
}

class PosePoint {
  final double x;
  final double y;
  final double likelihood;

  const PosePoint({
    required this.x,
    required this.y,
    required this.likelihood,
  });

  bool get isReliable => likelihood >= 0.6;
}

class RepCounterResult {
  final int reps;
  final MotionStage stage;
  final String feedback;

  const RepCounterResult({
    required this.reps,
    required this.stage,
    required this.feedback,
  });
}

PosePoint? readPosePoint(Pose pose, PoseLandmarkType type) {
  final landmark = pose.landmarks[type];
  if (landmark == null) return null;

  return PosePoint(
    x: landmark.x.toDouble(),
    y: landmark.y.toDouble(),
    likelihood: landmark.likelihood ?? 0.0,
  );
}