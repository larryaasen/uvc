// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:uvc/uvc.dart';

void main() {
  final uvc = UvcLib();

  final camera = uvc.control(vendorId: 0x1532, productId: 0x0E05);

  print('zoom: ${camera.zoom.current}');

  camera.zoom.current = 225;

  uvc.dispose();
}
