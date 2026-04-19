import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'models.dart';

abstract class ExerciseCounter {
  int reps = 0;
  MotionStage stage = MotionStage.unknown;
  DateTime _lastCountTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool canCount({int cooldownMs = 600}) {
    final now = DateTime.now();
    if (now.difference(_lastCountTime).inMilliseconds < cooldownMs) {
      return false;
    }
    _lastCountTime = now;
    return true;
  }

  void reset() {
    reps = 0;
    stage = MotionStage.unknown;
    _lastCountTime = DateTime.fromMillisecondsSinceEpoch(0);
    onReset();
  }

  void onReset() {}

  RepCounterResult process(Pose pose);
}