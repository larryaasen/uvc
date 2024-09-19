import 'package:uvc/uvc.dart';
import 'package:test/test.dart';

void main() {
  test('Uvc library is loaded', () {
    final uvc = UvcLib();
    expect(uvc.isLibraryLoaded, isTrue);

    expect(uvc.debugLogging, isFalse);
    expect(uvc.debugLoggingLibUsb, isFalse);

    uvc.dispose();
    expect(uvc.isLibraryLoaded, isFalse);
  });

  test('USB devices has a list', () {
    final uvc = UvcLib();
    expect(uvc.isLibraryLoaded, isTrue);

    expect(uvc.devices.libusb, isNotNull);
    expect(uvc.devices.get().length, greaterThanOrEqualTo(0));

    uvc.dispose();
    expect(uvc.isLibraryLoaded, isFalse);
  });

  test('UVC devices has a list', () {
    final uvc = UvcLib();
    expect(uvc.isLibraryLoaded, isTrue);

    expect(uvc.devices.libusb, isNotNull);
    final devices = uvc.devices.get(onlyUvcDevices: true);
    expect(devices.length, greaterThanOrEqualTo(0));

    if (devices.isNotEmpty) {
      expect(devices.first.path, isNotEmpty);
      expect(devices.first.deviceDescriptor.manufacturerName, isNotEmpty);
      expect(devices.first.deviceDescriptor.serialNumber, greaterThanOrEqualTo(0));
    }

    uvc.dispose();
    expect(uvc.isLibraryLoaded, isFalse);
  });
}
