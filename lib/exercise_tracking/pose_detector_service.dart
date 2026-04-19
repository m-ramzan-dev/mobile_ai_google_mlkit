import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectorService {
  late final PoseDetector _poseDetector;

  PoseDetectorService() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
  }

  Future<List<Pose>> processImage(InputImage inputImage) async {
    return _poseDetector.processImage(inputImage);
  }

  Future<void> dispose() async {
    await _poseDetector.close();
  }
}