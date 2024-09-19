// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:uvc/uvc.dart';

Future<void> main() async {
  final uvc = UvcLib(debugLogging: true, debugLoggingLibUsb: false);

  // printUvcDevices(uvc);
  // printUsbDevices(uvc);
  await cameraExample(uvc);

  uvc.dispose();
}

void printUvcDevices(UvcLib uvc) {
  final uvcDevices = uvc.devices.get(onlyUvcDevices: true);
  for (final device in uvcDevices) {
    print('example: UvcDevice: $device');
  }
}

void printUsbDevices(UvcLib uvc) {
  final usbDevices = uvc.devices.get();
  for (final device in usbDevices) {
    print('example: UsbDevice: $device');
  }
}

Future<void> cameraExample(UvcLib uvc) async {
  final camera =
      uvc.control(vendorId: 0x1532, productId: 0x0E05); // Razer Kiyo Pro
  // final camera = uvc.control(vendorId: 0x046D, productId: 0x0825); // Logitech
  print('example: camera is open: ${camera.isOpen()}');

  try {
    // camera.resetDevice();

    // camera.zoom.current;
    // camera.zoom.min;
    // camera.zoom.max;
    // camera.zoom.defaultValue;
    // // camera.zoom.information;
    // // camera.zoom.len;
    // camera.zoom.resolution;
  } catch (e) {
    print('example: camera zoom set error: $e');
    camera.close();
    return;
  }

  try {
    printValues(
        'example: backlight compensation', camera.backlightCompensation);
    printValues('example: brightness', camera.brightness);
    printValues('example: contrast', camera.contrast);
    printValues('example: saturation', camera.saturation);
    printValues('example: sharpness', camera.sharpness);
    printValues('example: whiteBalance', camera.whiteBalance);
    printValues('example: focus (auto)', camera.focusAuto);
    printValues('example: focus', camera.focus);
    printValues('example: pan', camera.pan);
    printValues('example: tilt', camera.tilt);
    printValues('example: zoom', camera.zoom);
    printValues('example: powerline frequency', camera.powerlineFrequency);
  } catch (e) {
    print('example: camera error: $e');
  }

  await animateValue(
      Duration(seconds: 5), 100, 400, (value) => camera.zoom.current = value);

  camera.close();
}

Future<void> animateValue(
  Duration duration,
  int min,
  int max,
  void Function(int value) valueChanged,
) async {
  const int frameRate = 33; // 33 milliseconds per frame (common refresh rate)
  final stepSize = (max - min) / (duration.inMilliseconds / frameRate);

  for (int value = min; value <= max; value += stepSize.round()) {
    valueChanged(value);
    await Future<void>.delayed(Duration(milliseconds: frameRate));
  }
}

void printValues(String name, UvcController controller) {
  try {
    print(
        'example: ${controller.name}: ${controller.current} (${controller.min} to ${controller.max}), '
        'default: ${controller.defaultValue}, resolution: ${controller.resolution}');
  } catch (e) {
    print('example: ${controller.name} error: $e');
  }
}
