import 'package:flutter/material.dart';

import '../models/preset_character.dart';
import '../models/vent_target.dart';
import '../theme/app_theme.dart';
import '../utils/target_image.dart';

class TargetAvatar extends StatelessWidget {
  const TargetAvatar({
    super.key,
    required this.target,
    this.size = 120,
    this.showLabel = true,
    this.opacity = 1.0,
    this.cracks = 0,
  });

  final VentTarget target;
  final double size;
  final bool showLabel;
  final double opacity;
  final int cracks;

  @override
  Widget build(BuildContext context) {
    final preset = PresetCharacter.findById(target.presetId);

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: preset?.color ?? AppTheme.card,
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.7),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withValues(alpha: 0.28),
                      blurRadius: 18,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: TargetImage.build(
                    target: target,
                    emojiSize: size * 0.45,
                  ),
                ),
              ),
              if (cracks > 0) ..._buildCracks(size),
            ],
          ),
          if (showLabel) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: size * 1.35,
              child: Text(
                target.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCracks(double avatarSize) {
    return List.generate(cracks.clamp(0, 8), (index) {
      final angle = (index * 45) * 3.14159 / 180;
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: 3,
          height: avatarSize * 0.55,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.15),
              ],
            ),
          ),
        ),
      );
    });
  }
}
