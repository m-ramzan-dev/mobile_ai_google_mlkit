import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_counter.dart';
import 'geometry_utils.dart';
import 'models.dart';

class SquatCounter extends ExerciseCounter {
  final MovingAverage _kneeSmoother = MovingAverage(5);

  @override
  void onReset() {
    _kneeSmoother.clear();
  }

  @override
  RepCounterResult process(Pose pose) {
    final lHip = readPosePoint(pose, PoseLandmarkType.leftHip);
    final lKnee = readPosePoint(pose, PoseLandmarkType.leftKnee);
    final lAnkle = readPosePoint(pose, PoseLandmarkType.leftAnkle);

    final rHip = readPosePoint(pose, PoseLandmarkType.rightHip);
    final rKnee = readPosePoint(pose, PoseLandmarkType.rightKnee);
    final rAnkle = readPosePoint(pose, PoseLandmarkType.rightAnkle);

    final leftOk = allReliable([lHip, lKnee, lAnkle]);
    final rightOk = allReliable([rHip, rKnee, rAnkle]);

    if (!leftOk && !rightOk) {
      return RepCounterResult(
        reps: reps,
        stage: stage,
        feedback: 'Move back so legs are fully visible',
      );
    }

    final angles = <double>[];
    if (leftOk) angles.add(calculateAngle(lHip!, lKnee!, lAnkle!));
    if (rightOk) angles.add(calculateAngle(rHip!, rKnee!, rAnkle!));

    final rawKneeAngle = angles.reduce((a, b) => a + b) / angles.length;
    final kneeAngle = _kneeSmoother.add(rawKneeAngle);

    if (kneeAngle < 100 && stage != MotionStage.bottom) {
      stage = MotionStage.bottom;
    }

    if (kneeAngle > 165 && stage == MotionStage.bottom) {
      if (canCount()) reps++;
      stage = MotionStage.standing;
      return RepCounterResult(
        reps: reps,
        stage: stage,
        feedback: 'Good squat',
      );
    }

    String feedback = 'Stand tall';
    if (kneeAngle > 120 && stage != MotionStage.bottom) {
      feedback = 'Go lower';
    } else if (kneeAngle <= 120 && kneeAngle >= 100) {
      feedback = 'Almost there';
    } else if (kneeAngle < 100) {
      feedback = 'Push up';
    }

    return RepCounterResult(
      reps: reps,
      stage: stage,
      feedback: feedback,
    );
  }
}