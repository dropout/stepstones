import 'package:chanting/src/domain/entity/chanting_state_entity.dart';
import 'package:chanting/src/domain/entity/lyrics_line_entity.dart';
import 'package:chanting/src/domain/entity/lyrics_word_entity.dart';
import 'package:chanting/src/presentation/view/player/lyric_text_style.dart';
import 'package:chanting/src/presentation/view/player/lyric_word.dart';
import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';

/// Renders a single [LyricsLineEntity] with per-word highlight animation.
/// The [position] is used to determine the state of each word (inactive, pending, singing, sung).
/// The [isActive] is currently not used, but can be used in the future to apply additional styling to the active line.
class const LyricLine({
  required final LyricsLineEntity line,
  required final Duration position,
  required final bool isActive,
  required final ChantingStateEntity chantingState,
  required final double maxWidth,
  super.key,
}) extends StatelessWidget {
  /// Returns the text style used for rendering lyrics lines.
  /// This is used when rendering the text and calculating the line heights
  /// for the varied extent sliver.
  static TextStyle getLyricsTextStyle(BuildContext context) {
    return context.theme.textTheme.headlineMedium!.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.appWhite,
    );
  }

  static EdgeInsets getLinePaddingForWidth(double maxWidth) {
    final vertical = 8.0;
    final horizontal = switch (DesignSpec.breakpointForWidth(maxWidth)) {
      .xs => 24.0,
      .sm => 32.0,
      .md => 40.0,
      .lg => 48.0,
      .xl => 60.0,
    };
    return EdgeInsets.only(
      left: horizontal,
      right: horizontal * 3,
      top: vertical,
      bottom: vertical,
    );
  }

  static final RegExp lineBreakPattern = RegExp(r'\\n|\r?\n');

  static List<InlineSpan> _buildSpans(LyricsLineEntity line, InlineSpan Function(LyricsWordEntity word) buildWord) {
    final textSpans = <InlineSpan>[];
    var hasWordOnCurrentParagraph = false;

    for (final word in line.words) {
      final fragments = word.text.split(lineBreakPattern);

      for (var i = 0; i < fragments.length; i++) {
        final fragment = fragments[i];
        if (fragment.isNotEmpty) {
          if (hasWordOnCurrentParagraph) {
            textSpans.add(const TextSpan(text: ' '));
          }
          textSpans.add(buildWord(word.copyWith(text: fragment)));
          hasWordOnCurrentParagraph = true;
        }

        if (i < fragments.length - 1) {
          textSpans.add(const TextSpan(text: '\n\n'));
          hasWordOnCurrentParagraph = false;
        }
      }
    }
    return textSpans;
  }

  /// Measures the same inline word widgets and breaks used by [build].
  static double calculateHeight(BuildContext context, LyricsLineEntity line, TextStyle style, double maxWidth) {
    final padding = getLinePaddingForWidth(maxWidth);
    final width = (maxWidth - padding.horizontal).clamp(0.0, double.infinity);
    final defaults = DefaultTextStyle.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final locale = Localizations.maybeLocaleOf(context);
    final heightBehavior = defaults.textHeightBehavior ?? DefaultTextHeightBehavior.maybeOf(context);
    final overrides = TextStyle(
      height: MediaQuery.maybeLineHeightScaleFactorOverrideOf(context),
      letterSpacing: MediaQuery.maybeLetterSpacingOverrideOf(context),
      wordSpacing: MediaQuery.maybeWordSpacingOverrideOf(context),
    );
    final defaultStyle = defaults.style
        .merge(MediaQuery.boldTextOf(context) ? const TextStyle(fontWeight: FontWeight.bold) : null)
        .merge(overrides);
    final wordStyle = defaults.style
        .merge(style)
        .merge(MediaQuery.boldTextOf(context) ? const TextStyle(fontWeight: FontWeight.bold) : null)
        .merge(overrides);
    final spanStyle = style.merge(overrides);
    final fontSize = style.fontSize ?? defaultStyle.fontSize ?? 14.0;
    // WidgetSpan scales the laid-out child in addition to its own text scaling.
    final scale = fontSize == 0 ? 1.0 : scaler.scale(fontSize) / fontSize;
    final dimensions = <PlaceholderDimensions>[];
    final spans = _buildSpans(line, (word) {
      final wordPainter =
          TextPainter(
            text: TextSpan(text: word.text, style: wordStyle),
            textDirection: direction,
            textScaler: scaler,
            locale: locale,
            textAlign: defaults.textAlign ?? TextAlign.start,
            maxLines: defaults.maxLines,
            ellipsis: defaults.overflow == TextOverflow.ellipsis ? '\u2026' : null,
            textWidthBasis: defaults.textWidthBasis,
            textHeightBehavior: heightBehavior,
          )..layout(
            maxWidth: defaults.softWrap || defaults.overflow == TextOverflow.ellipsis ? width / scale : double.infinity,
          );
      dimensions.add(
        PlaceholderDimensions(
          size: Size((wordPainter.width * scale).clamp(0.0, width), wordPainter.height * scale),
          alignment: PlaceholderAlignment.bottom,
        ),
      );
      wordPainter.dispose();
      return const WidgetSpan(child: SizedBox.shrink());
    });
    final painter =
        TextPainter(
            text: TextSpan(
              style: defaultStyle,
              children: [TextSpan(style: spanStyle, children: spans)],
            ),
            textDirection: direction,
            textScaler: scaler,
            locale: locale,
            textAlign: defaults.textAlign ?? TextAlign.start,
            maxLines: defaults.maxLines,
            ellipsis: defaults.overflow == TextOverflow.ellipsis ? '\u2026' : null,
            textWidthBasis: defaults.textWidthBasis,
            textHeightBehavior: heightBehavior,
          )
          ..setPlaceholderDimensions(dimensions)
          ..layout(maxWidth: defaults.softWrap || defaults.overflow == TextOverflow.ellipsis ? width : double.infinity);
    final height = painter.height + padding.vertical;
    painter.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final textSpans = _buildSpans(
      line,
      (word) => WidgetSpan(
        child: LyricWordWidget(line: line, word: word, position: position),
      ),
    );
    return Padding(
      padding: getLinePaddingForWidth(maxWidth),
      child: Text.rich(TextSpan(children: textSpans, style: LyricTextStyle.of(context))),
    );
  }

  static String displayText(LyricsLineEntity line) =>
      TextSpan(children: _buildSpans(line, (word) => TextSpan(text: word.text))).toPlainText();
}
