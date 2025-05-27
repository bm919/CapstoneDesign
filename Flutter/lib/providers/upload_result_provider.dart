import 'package:flutter_riverpod/flutter_riverpod.dart';

final uploadResultProvider = StateProvider<({String label, String rule})?>(
      (ref) => null,
);
