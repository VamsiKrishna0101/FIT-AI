import 'package:flutter/widgets.dart';
import 'fitness_copy.dart';

/// Display-only localisation for reusable labels, including const UI widgets.
/// User names, catalogue IDs and saved report content remain unchanged.
class FitnessText extends StatelessWidget {
  final String data;
  final Map<String, Object> values;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  const FitnessText(this.data,
      {super.key,
      this.values = const {},
      this.style,
      this.strutStyle,
      this.textAlign,
      this.textDirection,
      this.locale,
      this.softWrap,
      this.overflow,
      this.textScaler,
      this.maxLines,
      this.semanticsLabel,
      this.textWidthBasis,
      this.textHeightBehavior,
      this.selectionColor});
  @override
  Widget build(BuildContext context) => Text(
      fitnessText(context, data, values: values),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel:
          semanticsLabel == null ? null : fitnessText(context, semanticsLabel!),
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor);
}
