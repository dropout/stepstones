import 'package:chanting/src/domain/entity/chant_playback_state_entity.dart';
import 'package:chanting/src/domain/entity/chanting_state_entity.dart';
import 'package:chanting/src/domain/entity/lyrics_line_entity.dart';
import 'package:chanting/src/domain/entity/lyrics_word_entity.dart';
import 'package:chanting/src/presentation/view/player/lyric_line.dart';
import 'package:chanting/src/presentation/view/player/lyric_pause_dots.dart';
import 'package:chanting/src/presentation/view/player/lyric_text_style.dart';
import 'package:chanting/src/presentation/view/player/lyric_word.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  LyricsLineEntity line(List<String> words, {int startMs = 10000, int endMs = 20000}) => LyricsLineEntity(
    text: words.join(' '),
    start: Duration(milliseconds: startMs),
    end: Duration(milliseconds: endMs),
    words: [
      for (final w in words)
        LyricsWordEntity(
          text: w,
          start: Duration(milliseconds: startMs),
          end: Duration(milliseconds: endMs),
        ),
    ],
  );

  // 10s line: outro 600ms, enlarge 400ms, thirds of 3s each.
  final pause = line(['...']);
  // Pulse off by default so scale checks see only the fill and enlarge steps.
  List<PauseDotFrame> at(int ms, {double pulseTime = 0, bool pulsing = false}) => PauseDots.frames(
    line: pause,
    position: Duration(milliseconds: ms),
    pulseTime: pulseTime,
    pulsing: pulsing,
  );

  final pending = LyricWordWidget.colorOf(.pending);
  final white = LyricWordWidget.colorOf(.active);
  final gold = LyricWordWidget.colorOf(.highlight);
  final sung = LyricWordWidget.colorOf(.sung);

  group('isPauseLine', () {
    test('matches exactly three dots', () {
      expect(LyricLine.isPauseLine(line(['...'])), isTrue);
      expect(LyricLine.isPauseLine(line([' ... '])), isTrue);
    });

    test('rejects other text', () {
      expect(LyricLine.isPauseLine(line(['…'])), isFalse);
      expect(LyricLine.isPauseLine(line(['.', '.', '.'])), isFalse);
      expect(LyricLine.isPauseLine(line(['....'])), isFalse);
      expect(LyricLine.isPauseLine(line(['...', 'om'])), isFalse);
    });
  });

  group('frames', () {
    test('pending and passed lines are still, small and grey', () {
      for (final (frames, color) in [
        (at(9000, pulseTime: 0.8, pulsing: true), pending),
        (at(20000, pulseTime: 0.8, pulsing: true), sung),
      ]) {
        for (final f in frames) {
          expect(f.color, color);
          expect(f.scale, 1);
        }
      }
    });

    test('dots are white once the line is active', () {
      // The first dot starts filling immediately, so only the waiting dots are pure white.
      final frames = at(10300);
      expect(frames[1].color, white);
      expect(frames[2].color, white);
    });

    test('each dot fills to gold over its own third, then enlarges', () {
      final mid = at(11500);
      expect(mid[0].color, Color.lerp(white, gold, 0.5));
      expect(mid[1].color, white);
      expect(mid[0].scale, 1);

      final afterFirst = at(13500);
      expect(afterFirst[0].color, gold);
      expect(afterFirst[0].scale, closeTo(PauseDots.enlargedScale, 1e-4));
      expect(afterFirst[1].color, isNot(gold));
      expect(afterFirst[1].scale, 1);

      final beforeOutro = at(19400);
      for (final f in beforeOutro) {
        expect(f.color, gold);
        expect(f.scale, closeTo(PauseDots.enlargedScale, 1e-4));
      }
    });

    test('outro shrinks dots back toward the sung look', () {
      final late = at(19990, pulseTime: 0.8, pulsing: true);
      for (final f in late) {
        expect(f.scale, lessThan(1.01));
      }
    });

    test('dots pulse slightly out of phase while active, not without motion', () {
      final still = at(19400);
      final pulsing = at(19400, pulseTime: 0.8, pulsing: true);
      for (var i = 0; i < PauseDots.count; i++) {
        expect(pulsing[i].scale, greaterThan(still[i].scale));
        expect(pulsing[i].scale, lessThanOrEqualTo(PauseDots.maxScale + 1e-9));
      }
      expect(pulsing.map((f) => f.scale).toSet(), hasLength(3));
    });

    test('very short lines still finish gold and end grey', () {
      final short = line(['...'], startMs: 0, endMs: 300);
      final end = PauseDots.frames(line: short, position: const Duration(milliseconds: 299), pulseTime: 0);
      expect(end.every((f) => f.scale >= 1), isTrue);
      final done = PauseDots.frames(line: short, position: const Duration(milliseconds: 300), pulseTime: 0);
      expect(done.every((f) => f.color == sung), isTrue);
    });
  });

  testWidgets('pause line renders dots instead of words', (tester) async {
    final state = ChantingStateEntity(playbackState: ChantPlaybackStateEntity(updateTime: DateTime(2026)));
    await tester.pumpWidget(
      MaterialApp(
        theme: DesignSpec().themeData,
        home: Builder(
          builder: (context) => LyricTextStyle(
            style: LyricTextStyle.resolve(LyricLine.getLyricsTextStyle(context), 390),
            child: LyricLine(
              line: pause,
              position: const Duration(milliseconds: 12000),
              isActive: true,
              chantingState: state,
              maxWidth: 390,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(LyricPauseDots), findsOneWidget);
    expect(find.byType(LyricWordWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
