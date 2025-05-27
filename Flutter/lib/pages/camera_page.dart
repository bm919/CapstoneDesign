import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dummy_result_provider.dart';

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  late List<CameraDescription> _cameras;
  late CameraController _controller;
  bool _ready = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
    );
    await _controller.initialize();
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _controller.dispose();
    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
    );
    await _controller.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _onShutterPressed() async {
    if (!_ready) return;
    final XFile shot = await _controller.takePicture();
    context.push('/home/photo/save', extra: shot.path);
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // GalleryPage로 이동
      context.push('/home/photo/save', extra: pickedFile.path);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color seedColor = const Color(0xFF5B8B4B);

    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        title: const Text('사진을 촬영합니다.'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ✅ 중간: 카메라 화면
          Expanded(
            child: CameraPreview(_controller),
          ),

          // ✅ 하단 버튼 영역
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library, size: 36),
                  onPressed: _pickImageFromGallery,
                ),
                GestureDetector(
                  onTap: _onShutterPressed,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF5B8B4B),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, size: 36),
                  onPressed: _switchCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}