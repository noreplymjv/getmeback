import 'package:flutter/material.dart';

import '../models/vent_action.dart';
import '../theme/app_theme.dart';
import 'premium_chrome.dart';

class VentActionCard extends StatefulWidget {
  const VentActionCard({
    super.key,
    required this.action,
    required this.onTap,
    this.index = 0,
  });

  final VentAction action;
  final VoidCallback onTap;
  final int index;

  @override
  State<VentActionCard> createState() => _VentActionCardState();
}

class _VentActionCardState extends State<VentActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: Duration(milliseconds: 20 * widget.index),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth;
            final iconBox = (side * 0.36).clamp(28.0, 42.0);
            final iconSize = iconBox * 0.54;
            final titleSize = (side * 0.095).clamp(9.0, 11.5);

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.card.withValues(alpha: 0.85),
                    widget.action.color.withValues(alpha: 0.12),
                  ],
                ),
                border: Border.all(
                  color: _pressed
                      ? widget.action.color
                      : widget.action.color.withValues(alpha: 0.28),
                  width: _pressed ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.action.color.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(14),
                  onHighlightChanged: (v) => setState(() => _pressed = v),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: iconBox,
                          height: iconBox,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.action.color.withValues(alpha: 0.95),
                                widget.action.color.withValues(alpha: 0.55),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.action.color
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.action.icon,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          widget.action.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: titleSize,
                            letterSpacing: 0.15,
                            height: 1.15,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
