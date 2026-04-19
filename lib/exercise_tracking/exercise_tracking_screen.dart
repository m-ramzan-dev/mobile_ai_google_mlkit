import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'models.dart';
import 'pose_detector_service.dart';
import 'pose_painter.dart';
import 'workout_engine.dart';

class ExerciseTrackingScreen extends StatefulWidget {
  const ExerciseTrackingScreen({super.key});

  @override
  State<ExerciseTrackingScreen> createState() => _ExerciseTrackingScreenState();
}

class _ExerciseTrackingScreenState extends State<ExerciseTrackingScreen> {
  CameraController? _cameraController;
  late PoseDetectorService _poseService;
  late WorkoutEngine _workoutEngine;

  bool _isBusy = false;
  bool _isCameraInitialized = false;
  bool _isFrontCamera = false;

  Pose? _currentPose;
  int _repCount = 0;
  String _feedback = 'Get ready';
  String _stageText = 'unknown';
  ExerciseType _exerciseType = ExerciseType.squat;

  Size _imageSize = const Size(480, 640);

  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _poseService = PoseDetectorService();
    _workoutEngine = WorkoutEngine(_exerciseType);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    CameraDescription selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _isFrontCamera = selectedCamera.lensDirection == CameraLensDirection.front;

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
      Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();

    _imageSize = Size(
      _cameraController!.value.previewSize!.height,
      _cameraController!.value.previewSize!.width,
    );

    await _cameraController!.startImageStream(_processCameraImage);

    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy) return;

    final now = DateTime.now();
    if (now.difference(_lastProcessed).inMilliseconds < 100) {
      return;
    }
    _lastProcessed = now;

    _isBusy = true;

    try {
      final camera = _cameraController?.description;
      if (camera == null) {
        _isBusy = false;
        return;
      }

      final rotation = _rotationIntToImageRotation(camera.sensorOrientation);

      final inputImage = _inputImageFromCameraImage(image, rotation);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final poses = await _poseService.processImage(inputImage);

      if (poses.isNotEmpty) {
        final pose = poses.first;
        final result = _workoutEngine.process(pose);

        if (mounted) {
          setState(() {
            _currentPose = pose;
            _repCount = result.reps;
            _feedback = result.feedback;
            _stageText = result.stage.name;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentPose = null;
            _feedback = 'No pose detected';
            _stageText = 'unknown';
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(
      CameraImage image,
      InputImageRotation rotation,
      ) {
    final camera = _cameraController?.description;
    if (camera == null) return null;

    if (Platform.isIOS) {
      final bytes = image.planes.first.bytes;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    if (Platform.isAndroid) {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    return null;
  }

  void _changeExercise(ExerciseType type) {
    setState(() {
      _exerciseType = type;
      _workoutEngine.changeExercise(type);
      _repCount = 0;
      _feedback = 'Get ready';
      _stageText = 'unknown';
    });
  }

  void _resetCounter() {
    _workoutEngine.reset();
    setState(() {
      _repCount = 0;
      _feedback = 'Reset complete';
      _stageText = 'unknown';
    });
  }

  String _exerciseLabel(ExerciseType type) {
    switch (type) {
      case ExerciseType.squat:
        return 'Squat';
      case ExerciseType.pushUp:
        return 'Push-up';
      case ExerciseType.lunge:
        return 'Lunge';
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),

            Positioned.fill(
              child: CustomPaint(
                painter: PosePainter(
                  pose: _currentPose,
                  imageSize: _imageSize,
                  isFrontCamera: _isFrontCamera,
                ),
              ),
            ),

            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildTopPanel(),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildBottomPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            _exerciseLabel(_exerciseType),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reps: $_repCount',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Stage: $_stageText',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            _feedback,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.orangeAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            children: ExerciseType.values.map((type) {
              final selected = type == _exerciseType;
              return ChoiceChip(
                label: Text(_exerciseLabel(type)),
                selected: selected,
                onSelected: (_) => _changeExercise(type),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _resetCounter,
              child: const Text('Reset Counter'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tips:\n'
                '• Squat: full lower body visible\n'
                '• Push-up: side view works best\n'
                '• Lunge: keep both legs visible',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}