import 'package:flutter/material.dart';

bool containsArabic(String text) {
  return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
}

class BidiText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool forceLtr;

  const BidiText({
    super.key,
    required this.data,
    this.style,
    this.textAlign,
    this.forceLtr = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = containsArabic(data) && !forceLtr;
    final dir = isArabic ? TextDirection.rtl : TextDirection.ltr;
    return Directionality(
      textDirection: dir,
      child: Text(
        data,
        textDirection: dir,
        textAlign: textAlign,
        style: style,
      ),
    );
  }
}
