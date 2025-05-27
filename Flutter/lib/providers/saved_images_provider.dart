import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 예: ['/data/user/0/…/image_001.jpg', …]
final savedImagesProvider = StateProvider<List<String>>((_) => []);
