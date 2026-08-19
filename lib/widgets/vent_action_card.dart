import 'package:flutter/material.dart';

import '../models/vent_action.dart';
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
      delay: Duration(milliseconds: 24 * widget.index),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth;
            final iconBox = (side * 0.34).clamp(24.0, 40.0);
            final iconSize = iconBox * 0.52;
            final titleSize = (side * 0.095).clamp(8.5, 11.0);

            return GlassPanel(
              padding: EdgeInsets.zero,
              radius: 10,
              blur: false,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  onHighlightChanged: (v) => setState(() => _pressed = v),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4, 8, 4, 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: iconBox,
                          height: iconBox,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.action.color.withValues(alpha: 0.95),
                                widget.action.color.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                          child: Icon(
                            widget.action.icon,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.action.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: titleSize,
                            height: 1.1,
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
