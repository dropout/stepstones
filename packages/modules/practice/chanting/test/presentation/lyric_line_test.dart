import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:chanting/src/domain/entity/chanting_state_entity.dart';
import 'package:chanting/src/domain/entity/lyrics_document_entity.dart';
import 'package:chanting/src/domain/entity/lyrics_line_entity.dart';
import 'package:chanting/src/domain/entity/lyrics_word_entity.dart';
import 'package:chanting/src/presentation/view/player/lyric_line.dart';
import 'package:chanting/src/presentation/view/player/lyric_text_style.dart';
import 'package:chanting/src/presentation/view/player/lyrics_effects_config.dart';
import 'package:chanting/src/presentation/view/player/lyrics_view.dart';
import 'package:chanting/src/public/model/chanting_settings.dart';
import 'package:core/core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() async {
    var directory = Directory.current;
    late File font;
    while (true) {
      font = File('${directory.path}/packages/assets/fonts/Roboto_Slab/static/RobotoSlab-Bold.ttf');
      if (font.existsSync()) break;
      final parent = directory.parent;
      if (parent.path == directory.path) {
        throw StateError('Roboto Slab font not found');
      }
      directory = parent;
    }
    final loader = FontLoader(DesignSpec.fontFamilyName)..addFont(font.readAsBytes().then(ByteData.sublistView));
    await loader.load();
  });

  LyricsWordEntity word(String text) =>
      LyricsWordEntity(text: text, start: Duration.zero, end: const Duration(seconds: 1));

  test('display text converts escaped line breaks to paragraph spacing', () {
    final line = LyricsLineEntity(
      text: r'First \n second',
      start: Duration.zero,
      end: const Duration(seconds: 2),
      words: [word('First'), word(r'\n'), word('second')],
    );

    expect(LyricLine.displayText(line), 'First\n\nsecond');
  });

  test('display text handles breaks embedded in a word', () {
    final line = LyricsLineEntity(
      text: r'First\nsecond',
      start: Duration.zero,
      end: const Duration(seconds: 2),
      words: [word(r'First\nsecond')],
    );

    expect(LyricLine.displayText(line), 'First\n\nsecond');
  });

  test('display text leaves ordinary lyrics unchanged', () {
    final line = LyricsLineEntity(
      text: 'First second',
      start: Duration.zero,
      end: const Duration(seconds: 2),
      words: [word('First'), word('second')],
    );

    expect(LyricLine.displayText(line), 'First second');
  });

  testWidgets('measured extent matches the rendered inline words', (tester) async {
    final lines = [
      ['bu-jung-bul-gam', 'shi-go', 'gong-jung-mu-saek'],
      ['ordinary', 'lyrics'],
      [r'first\nsecond', 'third'],
      ['extraordinarilylongunbrokenword'],
      <String>[],
    ];
    final state = ChantingStateEntity(chantingSettings: const ChantingSettings(), playbackState: PlaybackState());

    for (final width in [200.0, 390.0, 480.0]) {
      for (final media in [
        const MediaQueryData(),
        const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        const MediaQueryData(
          boldText: true,
          lineHeightScaleFactorOverride: 1.3,
          letterSpacingOverride: 2,
          wordSpacingOverride: 3,
        ),
      ]) {
        for (final fragments in lines) {
          final line = LyricsLineEntity(
            text: fragments.join(' '),
            start: Duration.zero,
            end: const Duration(seconds: 2),
            words: fragments.map(word).toList(),
          );
          late double measured;
          await tester.pumpWidget(
            MaterialApp(
              theme: DesignSpec().themeData,
              home: MediaQuery(
                data: media,
                child: Builder(
                  builder: (context) {
                    final style = LyricTextStyle.resolve(LyricLine.getLyricsTextStyle(context), width);
                    measured = LyricLine.calculateHeight(context, line, style, width);
                    return SingleChildScrollView(
                      child: Center(
                        child: SizedBox(
                          width: width,
                          child: LyricTextStyle(
                            style: style,
                            child: LyricLine(
                              line: line,
                              position: Duration.zero,
                              isActive: true,
                              chantingState: state,
                              maxWidth: width,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
          expect(
            measured,
            closeTo(tester.getSize(find.byType(LyricLine)).height, 0.01),
            reason: 'width=$width media=$media text=$fragments',
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('sliver reserves space for the wrapped final word', (tester) async {
    final words = ['bu-jung-bul-gam', 'shi-go', 'gong-jung-mu-saek'];
    final line = LyricsLineEntity(
      text: words.join(' '),
      start: Duration.zero,
      end: const Duration(seconds: 2),
      words: words.map(word).toList(),
    );
    final nextLine = LyricsLineEntity(
      text: 'next',
      start: const Duration(seconds: 2),
      end: const Duration(seconds: 4),
      words: [word('next')],
    );
    final state = ChantingStateEntity(
      chantingSettings: const ChantingSettings(),
      playbackState: PlaybackState(),
      lyricsLoadingState: ProcessingState.completed,
      lyricsDocument: LyricsDocumentEntity(lines: [line, nextLine]),
    );
    Future<void> pumpLyrics(double width, double scale) => tester.pumpWidget(
      MaterialApp(
        theme: DesignSpec().themeData,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Center(
            child: SizedBox(
              width: width,
              height: 600,
              child: LyricsView(
                chantingState: state,
                maxWidth: width,
                topOffset: 0,
                effects: LyricsEffectsConfig.disabled,
              ),
            ),
          ),
        ),
      ),
    );
    for (final (width, scale) in [(390.0, 1.0), (390.0, 1.2), (480.0, 1.0), (390.0, 1.0)]) {
      await pumpLyrics(width, scale);
      final lineFinder = find.byType(LyricLine).first;
      final lastWord = find.text('gong-jung-mu-saek');
      final lineBottom = tester.getBottomLeft(lineFinder).dy;
      final wordBottom = tester.getBottomLeft(lastWord).dy;
      if (width == 390 && scale == 1) {
        expect(tester.getSize(lastWord).height, greaterThan(80));
      }
      expect(wordBottom, lessThanOrEqualTo(lineBottom - 8), reason: 'width=$width scale=$scale');
      expect(tester.getTopLeft(find.text('next')).dy, greaterThan(wordBottom));
      expect(tester.takeException(), isNull);
    }
  });
}
