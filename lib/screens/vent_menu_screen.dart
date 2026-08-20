import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/vent_action.dart';
import '../models/vent_target.dart';
import '../services/storage_service.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTarget();
  }

  Future<void> _loadTarget() async {
    final targets = await StorageService.instance.loadTargets();
    final target = targets.where((t) => t.id == widget.targetId).firstOrNull;
    if (mounted) setState(() => _target = target);
  }

  @override
  Widget build(BuildContext context) {
    if (_target == null) {
      return const Scaffold(
        body: PremiumBackdrop(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final target = _target!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Choose Your Vent'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
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
                                  'Pick a scene. Make it theatrical.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.goldSoft),
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
                      itemCount: VentAction.all.length,
                      itemBuilder: (context, index) {
                        final action = VentAction.all[index];
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
