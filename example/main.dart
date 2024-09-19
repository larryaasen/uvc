// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:uvc/uvc.dart';

void main() {
  final uvc = UvcLib();

  final camera = uvc.control(vendorId: 0x1532, productId: 0x0E05);

  final value = camera.zoom.min;
  camera.zoom.current = value == null ? 225 : value + 1;

  camera.close();

  uvc.dispose();
}
