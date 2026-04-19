import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_counter.dart';
import 'geometry_utils.dart';
import 'models.dart';

class PushUpCounter extends ExerciseCounter {
  final MovingAverage _elbowSmoother = MovingAverage(5);
  final MovingAverage _bodySmoother = MovingAverage(5);

  @override
  void onReset() {
    _elbowSmoother.clear();
    _bodySmoother.clear();
  }

  @override
  RepCounterResult process(Pose pose) {
    final ls = readPosePoint(pose, PoseLandmarkType.leftShoulder);
    final le = readPosePoint(pose, PoseLandmarkType.leftElbow);
    final lw = readPosePoint(pose, PoseLandmarkType.leftWrist);
    final lh = readPosePoint(pose, PoseLandmarkType.leftHip);
    final la = readPosePoint(pose, PoseLandmarkType.leftAnkle);

    final rs = readPosePoint(pose, PoseLandmarkType.rightShoulder);
    final re = readPosePoint(pose, PoseLandmarkType.rightElbow);
    final rw = readPosePoint(pose, PoseLandmarkType.rightWrist);
    final rh = readPosePoint(pose, PoseLandmarkType.rightHip);
    final ra = readPosePoint(pose, PoseLandmarkType.rightAnkle);

    final leftScore =
        (ls?.likelihood ?? 0) + (le?.likelihood ?? 0) + (lw?.likelihood ?? 0);
    final rightScore =
        (rs?.likelihood ?? 0) + (re?.likelihood ?? 0) + (rw?.likelihood ?? 0);

    PosePoint? shoulder, elbow, wrist, hip, ankle;

    if (leftScore >= rightScore) {
      shoulder = ls;
      elbow = le;
      wrist = lw;
      hip = lh;
      ankle = la;
    } else {
      shoulder = rs;
      elbow = re;
      wrist = rw;
      hip = rh;
      ankle = ra;
    }

    if (!allReliable([shoulder, elbow, wrist, hip, ankle])) {
      return RepCounterResult(
        reps: reps,
        stage: stage,
        feedback: 'Use side view and keep full body visible',
      );
    }

    final rawElbowAngle = calculateAngle(shoulder!, elbow!, wrist!);
    final rawBodyAngle = calculateAngle(shoulder, hip!, ankle!);

    final elbowAngle = _elbowSmoother.add(rawElbowAngle);
    final bodyAngle = _bodySmoother.add(rawBodyAngle);

    if (bodyAngle < 145) {
      return RepCounterResult(
        reps: reps,
        stage: stage,
        feedback: 'Keep body straight',
      );
    }

    if (elbowAngle < 90 && stage != MotionStage.down) {
      stage = MotionStage.down;
    }

    if (elbowAngle > 155 && stage == MotionStage.down) {
      if (canCount()) reps++;
      stage = MotionStage.up;
      return RepCounterResult(
        reps: reps,
        stage: stage,
        feedback: 'Good push-up',
      );
    }

    String feedback = 'Keep going';
    if (elbowAngle > 110 && stage != MotionStage.down) {
      feedback = 'Go lower';
    } else if (elbowAngle <= 110 && elbowAngle >= 90) {
      feedback = 'Almost down';
    } else if (elbowAngle < 90) {
      feedback = 'Push up';
    }

    return RepCounterResult(
      reps: reps,
      stage: stage,
      feedback: feedback,
    );
  }
}