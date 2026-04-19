import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_counter.dart';
import 'geometry_utils.dart';
import 'models.dart';

class LungeCounter extends ExerciseCounter {
  final MovingAverage _leftKneeSmoother = MovingAverage(5);
  final MovingAverage _rightKneeSmoother = MovingAverage(5);

  @override
  void onReset() {
    _leftKneeSmoother.clear();
    _rightKneeSmoother.clear();
  }

  @override
  RepCounterResult process(Pose pose) {
    final lHip = readPosePoint(pose, PoseLandmarkType.leftHip);
    final lKnee = readPosePoint(pose, PoseLandmarkType.leftKnee);
    final lAnkle = readPosePoint(pose, PoseLandmarkType.leftAnkle);

    final rHip = readPosePoint(pose, PoseLandmarkType.rightHip);
    final rKnee = readPosePoint(pose, PoseLandmarkType.rightKnee);
    final rAnkle = readPosePoint(pose, PoseLandmarkType.rightAnkle);

    if (!allReliable([lHip, lKnee, lAnkle, rHip, rKnee, rAnkle])) {
      return RepCounterResult(
        reps: reps,
        stage: stage,
        feedback: 'Keep lower body fully visible',
      );
    }

    final leftKneeAngle =
    _leftKneeSmoother.add(calculateAngle(lHip!, lKnee!, lAnkle!));
    final rightKneeAngle =
    _rightKneeSmoother.add(calculateAngle(rHip!, rKnee!, rAnkle!));

    final standing = leftKneeAngle > 155 && rightKneeAngle > 155;
    final leftDown = leftKneeAngle < 110 && rightKneeAngle < 130;
    final rightDown = rightKneeAngle < 110 && leftKneeAngle < 130;

    if (leftDown && stage != MotionStage.leftDown) {
      stage = MotionStage.leftDown;
    } else if (rightDown && stage != MotionStage.rightDown) {
      stage = MotionStage.rightDown;
    }

    if (standing &&
        (stage == MotionStage.leftDown || stage == MotionStage.rightDown)) {
      if (canCount()) reps++;
      stage = MotionStage.standing;
      return RepCounterResult(
        reps: reps,
        stage: stage,
        feedback: 'Good lunge',
      );
    }

    String feedback = 'Step into lunge';
    if (leftDown || rightDown) {
      feedback = 'Push back up';
    }

    return RepCounterResult(
      reps: reps,
      stage: stage,
      feedback: feedback,
    );
  }
}