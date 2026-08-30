import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/vent_action.dart';
import '../models/vent_target.dart';
import '../services/storage_service.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
import '../utils/target_image.dart';
import '../widgets/premium_chrome.dart';
import '../widgets/target_avatar.dart';
import '../widgets/vent_action_card.dart';

class VentMenuScreen extends StatefulWidget {
  const VentMenuScreen({super.key, required this.targetId});

  final String targetId;

  @override
  State<VentMenuScreen> createState() => _VentMenuScreenState();
}

class _VentMenuScreenState extends State<VentMenuScreen> {
  VentTarget? _target;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTarget();
  }

  Future<void> _loadTarget() async {
    VentTarget? target;
    if (widget.targetId == 'room_guest') {
      target = roomGuestTarget;
    } else {
      final targets = await StorageService.instance.loadTargets();
      target = targets.where((t) => t.id == widget.targetId).firstOrNull;
    }
    if (target != null) {
      TargetImage.preloadTarget(target);
    }
    if (mounted) {
      setState(() {
        _target = target;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: PremiumBackdrop(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_target == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Character Not Found'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/characters');
              }
            },
          ),
        ),
        body: PremiumBackdrop(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: GlassPanel(
                goldEdge: true,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_off_rounded,
                      size: 54,
                      color: AppTheme.gold,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Character Not Found',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This character might have been removed or the link is invalid.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 20),
                    ShineButton(
                      label: 'Choose Character',
                      icon: Icons.people_rounded,
                      onPressed: () => context.go('/characters'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text(
                        'Go Home',
                        style: TextStyle(color: AppTheme.goldSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final target = _target!;
    final faceVents = VentAction.all
        .where((a) => a.type != VentActionType.roomRampage)
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Choose Your Vent'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/characters');
            }
          },
        ),
      ),
      body: PremiumBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  children: [
                    FadeSlideIn(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: GlassPanel(
                          goldEdge: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              TargetAvatar(
                                target: target,
                                size: 40,
                                showLabel: false,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Face vents only — tap a scene below.\n'
                                  'For room smashing, use Home → Rooms & Scenes.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.goldSoft,
                                        height: 1.35,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 140,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        mainAxisExtent: 110,
                      ),
                      itemCount: faceVents.length,
                      itemBuilder: (context, index) {
                        final action = faceVents[index];
                        return VentActionCard(
                          action: action,
                          index: index,
                          onTap: () {
                            VentSfx.light();
                            VentSfx.instance.unlock();
                            VentSfx.instance.play(Sfx.whoosh);
                            context.push(
                              '/vent/${action.type.name}/${target.id}',
                            );
                          },
                        );
                      },
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

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
