import 'package:flutter/material.dart';

/// Collects the text currently visible inside part of the screen, so the
/// "Read this screen" button can read it out loud. Hidden tabs and closed
/// panels are skipped. Websites shown inside the app can't be read this way.
String visibleTextIn(BuildContext context) {
  final parts = <String>[];

  void visit(Element element) {
    final widget = element.widget;
    if (widget is Offstage && widget.offstage) return; // hidden, skip it
    if (widget is Text) {
      final text = widget.data ?? widget.textSpan?.toPlainText();
      if (text != null && text.trim().isNotEmpty) parts.add(text.trim());
      return;
    }
    element.visitChildren(visit);
  }

  context.visitChildElements(visit);
  return parts.join('. ');
}
