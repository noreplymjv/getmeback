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
      delay: Duration(milliseconds: 40 * widget.index),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: GlassPanel(
          padding: EdgeInsets.zero,
          radius: 22,
          blur: false,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.action.color.withValues(alpha: 0.95),
                            widget.action.color.withValues(alpha: 0.45),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.action.color.withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.action.icon,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.action.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.action.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
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
    );
  }
}
