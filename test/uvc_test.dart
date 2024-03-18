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

  test('Uvc devices has a list', () {
    final uvc = UvcLib();
    expect(uvc.isLibraryLoaded, isTrue);

    expect(uvc.devices.libusb, isNotNull);
    expect(uvc.devices.get().length, greaterThanOrEqualTo(0));

    uvc.dispose();
    expect(uvc.isLibraryLoaded, isFalse);
  });
}
