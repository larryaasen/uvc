import 'package:uvc/uvc.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Uvc library is loaded', () {
      final uvc = UvcLib();
      expect(uvc.isLibraryLoaded, isTrue);
      uvc.dispose();
      expect(uvc.isLibraryLoaded, isFalse);
    });
  });
}
