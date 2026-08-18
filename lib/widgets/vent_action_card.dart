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

  static const double tileSize = 88;

  @override
  State<VentActionCard> createState() => _VentActionCardState();
}

class _VentActionCardState extends State<VentActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: Duration(milliseconds: 30 * widget.index),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: VentActionCard.tileSize,
          height: VentActionCard.tileSize,
          child: GlassPanel(
            padding: EdgeInsets.zero,
            radius: 12,
            blur: false,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
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
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.action.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
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
          ),
        ),
      ),
    );
  }
}
