import 'dart:io';

import 'package:flutter/material.dart';

import '../models/preset_character.dart';
import '../models/vent_target.dart';
import '../theme/app_theme.dart';

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
                    color: AppTheme.accent.withValues(alpha: 0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(child: _buildContent(preset)),
              ),
              if (cracks > 0) ..._buildCracks(size),
            ],
          ),
          if (showLabel) ...[
            const SizedBox(height: 8),
            Text(
              target.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(PresetCharacter? preset) {
    if (target.hasPhoto) {
      final file = File(target.imagePath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return Center(
      child: Text(
        preset?.emoji ?? '🎯',
        style: TextStyle(fontSize: size * 0.45),
      ),
    );
  }

  List<Widget> _buildCracks(double avatarSize) {
    return List.generate(cracks.clamp(0, 6), (index) {
      final angle = (index * 60) * 3.14159 / 180;
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: 2,
          height: avatarSize * 0.4,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      );
    });
  }
}
