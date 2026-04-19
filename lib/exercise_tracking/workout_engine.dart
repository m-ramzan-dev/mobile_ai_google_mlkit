import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_counter.dart';
import 'lunge_counter.dart';
import 'models.dart';
import 'pushup_counter.dart';
import 'squat_counter.dart';

class WorkoutEngine {
  ExerciseType exerciseType;
  late ExerciseCounter _counter;

  WorkoutEngine(this.exerciseType) {
    _counter = _buildCounter(exerciseType);
  }

  ExerciseCounter _buildCounter(ExerciseType type) {
    switch (type) {
      case ExerciseType.squat:
        return SquatCounter();
      case ExerciseType.pushUp:
        return PushUpCounter();
      case ExerciseType.lunge:
        return LungeCounter();
    }
  }

  void changeExercise(ExerciseType type) {
    exerciseType = type;
    _counter = _buildCounter(type);
  }

  void reset() {
    _counter.reset();
  }

  RepCounterResult process(Pose pose) {
    return _counter.process(pose);
  }
}