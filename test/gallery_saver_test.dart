import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:http/http.dart' as http;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('gallery_saver');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'saveImage':
          return true;
        case 'saveVideo':
          return false;
      }
      return 'unknown method';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('save image', () async {
    expect(await GallerySaver.saveImage('/storage/emulated/image.jpg'), true);
  });

  test('save video', () async {
    expect(await GallerySaver.saveVideo('/storage/emulated/video.mov'), false);
  });

  test(
      '#getFileNameFromUri should correctly determine the filename from '
      'the given URI', () {
    expect(
      GallerySaver.getFileNameFromUri(
        uri: Uri.parse('https://my-fake-origin.com/file.mp4'),
        response: http.Response('', 200),
      ),
      'file.mp4',
    );

    expect(
      GallerySaver.getFileNameFromUri(
        uri: Uri.parse('https://my-fake-origin.com/foo/bar/file.mp4'),
        response: http.Response('', 200),
      ),
      'file.mp4',
    );

    expect(
      GallerySaver.getFileNameFromUri(
        uri: Uri.parse('https://my-fake-origin.com/foo/bar/file.mp4?param1=value1&param2=value2'),
        response: http.Response('', 200),
      ),
      'file.mp4',
    );

    expect(
      GallerySaver.getFileNameFromUri(
        uri: Uri.parse('https://my-fake-origin.com/foo/bar/file?param1=value1&param2=value2'),
        response: http.Response(
          '',
          200,
          headers: {
            'content-type': 'video/mp4',
          },
        ),
      ),
      'file.mp4',
    );

    expect(
      GallerySaver.getFileNameFromUri(
        uri: Uri.parse('https://my-fake-origin.com/foo/bar/file?param1=value1&param2=value2'),
        response: http.Response(
          '',
          200,
          headers: {
            'content-type': 'image/jpg',
          },
        ),
      ),
      'file.jpg',
    );

    expect(
      () => GallerySaver.getFileNameFromUri(
        uri: Uri.parse('https://my-fake-origin.com/foo/bar/file?param1=value1&param2=value2'),
        response: http.Response(
          '',
          200,
          headers: {},
        ),
      ),
      throwsArgumentError,
    );

    expect(
      () => GallerySaver.getFileNameFromUri(
        uri: Uri.parse('https://my-fake-origin.com/foo/bar/file?param1=value1&param2=value2'),
        response: http.Response(
          '',
          200,
          headers: {
            'content-type': 'application/json',
          },
        ),
      ),
      throwsArgumentError,
    );
  });
}
