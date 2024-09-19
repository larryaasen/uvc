[![GitHub main workflow](https://github.com/larryaasen/uvc/actions/workflows/main.yml/badge.svg)](https://github.com/larryaasen/uvc/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/larryaasen/uvc/branch/main/graph/badge.svg)](https://app.codecov.io/gh/larryaasen/uvc)
[![pub package](https://img.shields.io/pub/v/uvc.svg)](https://pub.dartlang.org/packages/uvc)
[![GitHub Stars](https://img.shields.io/github/stars/larryaasen/uvc.svg)](https://github.com/larryaasen/uvc/stargazers)
<a href="https://www.buymeacoffee.com/larryaasen">
  <img alt="Buy me a coffee" src="https://img.shields.io/badge/Donate-Buy%20Me%20A%20Coffee-yellow.svg">
</a>

A Dart package for controlling UVC compliant webcams.

You can find more information about UVC USB devices [here on Wikipedia](https://en.wikipedia.org/wiki/List_of_USB_video_class_devices).

## Platform Support

| Android |  iOS  | MacOS |  Web  | Linux | Windows |
| :-----: | :---: | :---: | :---: | :---: | :-----: |
|❌       |❌     |✅     |❌     |❌     |✅       |


## Example

```
import 'package:uvc/uvc.dart';

void main() {
  final uvc = UvcLib(); // Load the libusb library

  final camera = UVCControl(vendorId: 0x1532, productId: 0x0E05);

  final value = camera.zoom.min;
  camera.zoom.current = value == null ? 225 : value + 1;

  camera.close();

  uvc.dispose();
}
```

## Usage

First, add `uvc` as a dependency in your pubspec.yaml file. Then run `dart pub get` or `flutter pub get`.

Next, you need to instantiate the `UvcLib` class which will open and setup the libusb
library for use in the app.
```
final uvc = UvcLib();
```

To open a camera and start controlling it, you must use `UVCControl`. Include the
vendor ID and product ID of the camera to control.
```
final camera = UVCControl(vendorId: 0x1532, productId: 0x0E05);
```

To find a list of cameras with their IDs, you can use:
```
final uvcDevices = uvc.getDevices(onlyUvcDevices: true);
final device = uvcDevices.first;
final vendorId = device.deviceDescriptor.vendorId;
final productId = device.deviceDescriptor.productId;
```

To get the zoom current value:
```
final value = camera.zoom.current;
```

To set the zoom current value:
```
camera.zoom.current = 225;
```

Close the camera when you are done.
```
camera.close();
```

It is always a good idea to unload the library when you are done using it.
```
uvc.dispose();
```

To get the range of valid values for zoom:
```
final min = camera.zoom.min;
final max = camera.zoom.max;
```

To use the pan or tilt values, just use the same code as zoom, but substitute
the name pan and tilt for zoom:
```
camera.pan.current;
camera.pan.min;
camera.tilt.current;
camera.tilt.min;
```

## Controls

### Pan
```
camera.pan.current;
```

### Tilt
```
camera.tilt.current;
```

### Zoom 
```
final camera = UVCControl(vendorId: 0x1532, productId: 0x0E05);

camera.zoom.current;
camera.zoom.defaultValue;
camera.zoom.max;
camera.zoom.min;
camera.zoom.resolution;
```

### Backlight Compensation
```
camera.backlightCompensation.current;
```

### Brightness
```
camera.brightness.current;
```

### Contrast
```
camera.contrast.current;
```

### Saturation
```
camera.contrast.saturation;
```

### Sharpness
```
camera.contrast.sharpness;
```

### White Balance
```
camera.contrast.whitebalance;
```

### Focus
```
camera.zoom.current;
```

### Focus (auto)
```
camera.focusAuto.current;
```

### Powerline Frequency
```
camera.powerlineFrequency.current;
```

## Debugging

You can enable logging in `UvcLib` for troubleshooting. Just pass `true` to `debugLogging` when creating `UvcLib`.
```
final uvc = UvcLib(debugLogging: true);
```

You can also enable `libusb` logging in `UvcLib` for troubleshooting. Just pass `true` to `debugLoggingLibUsb` when creating `UvcLib`.
```
final uvc = UvcLib(debugLoggingLibUsb: true);
```

## libusb

This `uvc` package utilizes the [libusb library](https://github.com/libusb/libusb/)
via [Dart FFI](https://dart.dev/interop/c-interop) and it is
included as a dependency with the [libusb Dart package](https://pub.dev/packages/libusb).

## Contributing
All [comments](https://github.com/larryaasen/uvc/issues) and [pull requests](https://github.com/larryaasen/uvc/pulls) are welcome.

## Donations / Sponsor

Please sponsor or donate to the creator of `uvc` on [Patreon](https://www.patreon.com/larryaasen).
