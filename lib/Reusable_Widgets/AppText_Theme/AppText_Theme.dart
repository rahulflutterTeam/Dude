import 'package:flutter/material.dart';

class AppText extends StatefulWidget {
  final String data;
  FontWeight? fontWeight;
  double? fontSize;
  Color? color;
  final TextDecoration? decoration;
  final double? letterSpacing;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  AppText(
    @required this.data, {
    Key? key,
    this.fontWeight = FontWeight.normal,
    this.fontSize = 16,
    this.color,
    this.decoration,
    this.textAlign,
    this.style,
    this.overflow,
    this.letterSpacing,
    this.maxLines,
    String? fontFamily,
  }) : super(key: key);

  @override
  State<AppText> createState() => _AppTextState();
}

class _AppTextState extends State<AppText> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium ?? const TextStyle();

    return Text(
      widget.data,
      textAlign: widget.textAlign ?? TextAlign.left,
      style:
          widget.style ??
          baseStyle.copyWith(
            decoration: widget.decoration,
            color: widget.color ?? theme.colorScheme.onSurface,
            fontSize: widget.fontSize,
            letterSpacing: widget.letterSpacing,
            overflow: widget.overflow,
            fontWeight: widget.fontWeight,
          ),
      overflow: widget.overflow,
      maxLines: widget.maxLines,
    );
  }
}
