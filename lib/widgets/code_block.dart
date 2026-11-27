import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/bidi_text.dart';

class CodeBlock extends StatelessWidget {
  final String code;
  final VoidCallback? onCopy;

  const CodeBlock({super.key, required this.code, this.onCopy});

  Future<void> _copyToClipboard(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: code));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: BidiText(data: 'تم النسخ'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      onCopy?.call();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: BidiText(
                  data: 'COMMAND / PATH',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8B949E), fontFamily: 'Mono'),
                  forceLtr: true,
                ),
              ),
              InkWell(
                onTap: () => _copyToClipboard(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.copy, size: 16, color: Color(0xFF8B949E)),
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFF30363D)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontFamily: 'Mono',
                fontSize: 12,
                color: Color(0xFFE4E4E7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
