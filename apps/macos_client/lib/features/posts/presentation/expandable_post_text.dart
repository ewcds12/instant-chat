import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class ExpandablePostText extends StatefulWidget {
  const ExpandablePostText({required this.text, super.key});

  final String text;

  @override
  State<ExpandablePostText> createState() => _ExpandablePostTextState();
}

class _ExpandablePostTextState extends State<ExpandablePostText> {
  var _expanded = false;

  @override
  void didUpdateWidget(ExpandablePostText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.35);
    return LayoutBuilder(
      builder: (context, constraints) {
        final canExpand = _exceedsCollapsedLines(
          context,
          style,
          constraints.maxWidth,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectionArea(
              child: Text(
                widget.text,
                key: const Key('post-text-content'),
                maxLines: _expanded
                    ? null
                    : RetroMetrics.explorePostCollapsedLines,
                overflow: _expanded ? null : TextOverflow.clip,
                style: style,
              ),
            ),
            if (canExpand)
              TextButton(
                key: const Key('post-text-toggle'),
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  context.l10n.ui(_expanded ? 'Show less' : 'Show more'),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _exceedsCollapsedLines(
    BuildContext context,
    TextStyle? style,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: RetroMetrics.explorePostCollapsedLines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    )..layout(maxWidth: maxWidth);
    final exceeds = painter.didExceedMaxLines;
    painter.dispose();
    return exceeds;
  }
}
