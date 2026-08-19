import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/contacts/presentation/contact_request_drawer_row.dart';

class ContactRequestDrawer extends StatefulWidget {
  const ContactRequestDrawer({
    required this.requests,
    required this.disabled,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final List<ContactRequest> requests;
  final bool disabled;
  final ValueChanged<ContactRequest> onAccept;
  final ValueChanged<ContactRequest> onDecline;

  @override
  State<ContactRequestDrawer> createState() => _ContactRequestDrawerState();
}

class _ContactRequestDrawerState extends State<ContactRequestDrawer> {
  static const visibleRows = 3;
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final visibleCount = math.min(widget.requests.length, visibleRows);
    return Material(
      key: const Key('contact-request-drawer'),
      color: RetroColors.glassStrong,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: context.l10n.friendRequestCount(widget.requests.length),
            value: context.l10n.ui(_expanded ? 'Expanded' : 'Collapsed'),
            child: InkWell(
              key: const Key('contact-request-drawer-toggle'),
              onTap: () => setState(() => _expanded = !_expanded),
              child: SizedBox(
                height: 42,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.friendRequestCount(
                            widget.requests.length,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      _RequestCountBadge(count: widget.requests.length),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: duration,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            alignment: Alignment.topCenter,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(height: 1, color: colors.outlineVariant),
                      SizedBox(
                        height:
                            visibleCount * contactRequestDrawerRowHeight +
                            math.max(0, visibleCount - 1),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: widget.requests.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            indent: 10,
                            color: colors.outlineVariant,
                          ),
                          itemBuilder: (context, index) {
                            final request = widget.requests[index];
                            return ContactRequestDrawerRow(
                              request: request,
                              disabled: widget.disabled,
                              onAccept: () => widget.onAccept(request),
                              onDecline: () => widget.onDecline(request),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _RequestCountBadge extends StatelessWidget {
  const _RequestCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      key: const Key('contact-request-count-badge'),
      dimension: RetroMetrics.contactRequestCountDiameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
