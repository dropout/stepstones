import 'dart:convert';
import 'dart:io';

import 'package:chanting/src/data/service/default_lyrics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpRequest extends Mock implements HttpClientRequest {}

class MockHttpResponse extends Mock implements HttpClientResponse {}

const lyrics =
    '[Events]\n'
    'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n'
    r'Dialogue: 0,0:00:01.00,0:00:02.00,Default,,0,0,0,,{\k50}hello';

void main() {
  test('reads and parses local lyrics', () async {
    final directory = await Directory.systemTemp.createTemp('lyrics-test');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/lyrics.ass');
    await file.writeAsString(lyrics);

    final document = await DefaultLyricsService().loadLyrics(file.path);

    expect(document.lines, hasLength(1));
    expect(document.lines.single.text, 'hello');
    expect(document.lines.single.start, const Duration(seconds: 1));
    expect(document.lines.single.end, const Duration(seconds: 2));
    expect(document.lines.single.words, hasLength(1));
  });

  test('reports missing files', () async {
    final directory = await Directory.systemTemp.createTemp('lyrics-test');
    addTearDown(() => directory.delete(recursive: true));
    await expectLater(
      DefaultLyricsService().loadLyrics('${directory.path}/missing'),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('reads remote lyrics and reports HTTP errors', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      if (request.uri.path == '/missing') {
        request.response.statusCode = HttpStatus.notFound;
      } else {
        request.response.add(utf8.encode(lyrics));
      }
      await request.response.close();
    });
    final base = 'http://${server.address.address}:${server.port}';
    final service = DefaultLyricsService();
    expect((await service.loadLyrics('$base/lyrics')).lines.single.text, 'hello');
    await expectLater(service.loadLyrics('$base/missing'), throwsA(isA<Exception>()));
  });

  test('closes the client when a remote request fails', () async {
    final client = MockHttpClient();
    final uri = Uri.parse('https://example.test/lyrics');
    when(() => client.getUrl(uri)).thenThrow(const SocketException('network failure'));
    when(() => client.close(force: true)).thenReturn(null);

    await expectLater(
      DefaultLyricsService(httpClientFactory: () => client).loadLyrics(uri.toString()),
      throwsA(isA<SocketException>()),
    );
    verify(() => client.close(force: true)).called(1);
  });

  test('closes the client when the server returns an error', () async {
    final client = MockHttpClient();
    final request = MockHttpRequest();
    final response = MockHttpResponse();
    final uri = Uri.parse('https://example.test/lyrics');
    when(() => client.getUrl(uri)).thenAnswer((_) async => request);
    when(() => request.close()).thenAnswer((_) async => response);
    when(() => response.statusCode).thenReturn(HttpStatus.notFound);
    when(() => client.close(force: true)).thenReturn(null);

    await expectLater(
      DefaultLyricsService(httpClientFactory: () => client).loadLyrics(uri.toString()),
      throwsException,
    );
    verify(() => client.close(force: true)).called(1);
  });
}
