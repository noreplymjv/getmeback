import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/room_setup.dart';
import '../models/vent_target.dart';
import '../services/storage_service.dart';
import '../services/vent_sfx.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_chrome.dart';
import '../widgets/responsive_columns.dart';
import '../widgets/target_avatar.dart';

/// Guest used when entering Rooms without a saved character.
VentTarget get roomGuestTarget => VentTarget(
      id: 'room_guest',
      name: 'Room Mode',
      presetId: 'grumpy_cat',
      createdAt: DateTime(2026),
    );

class RoomPickerScreen extends StatefulWidget {
  const RoomPickerScreen({super.key, this.targetId});

  final String? targetId;

  @override
  State<RoomPickerScreen> createState() => _RoomPickerScreenState();
}

class _RoomPickerScreenState extends State<RoomPickerScreen> {
  VentTarget? _target;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.targetId;
    if (id == null || id == 'room_guest') {
      if (mounted) setState(() => _target = roomGuestTarget);
      return;
    }
    final targets = await StorageService.instance.loadTargets();
    final target = targets.where((t) => t.id == id).firstOrNull;
    if (mounted) {
      setState(() {
        _target = target;
        _failed = target == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pick a Room')),
        body: const Center(child: Text('Character not found')),
      );
    }
    if (_target == null) {
      return const Scaffold(
        body: PremiumBackdrop(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final target = _target!;
    final width = MediaQuery.sizeOf(context).width - 32;
    final cols = responsiveTileColumns(width).clamp(2, 3);
    final isGuest = target.id == 'room_guest';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pick a Room Scene'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: PremiumBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              children: [
                FadeSlideIn(
                  child: GlassPanel(
                    goldEdge: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        if (!isGuest) ...[
                          TargetAvatar(
                            target: target,
                            size: 40,
                            showLabel: false,
                          ),
                          const SizedBox(width: 10),
                        ] else ...[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFF26A69A),
                            ),
                            child: const Icon(
                              Icons.meeting_room,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            'Each tile is a real room picture. Tap one, then '
                            'TAP the glowing objects inside to smash — nothing '
                            'breaks by itself.',
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
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: RoomSetup.all.length,
                  itemBuilder: (context, index) {
                    final room = RoomSetup.all[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 18 * index),
                      child: _RoomCard(
                        room: room,
                        onTap: () {
                          VentSfx.light();
                          VentSfx.instance.unlock();
                          VentSfx.instance.play(Sfx.whoosh);
                          context.push(
                            '/room-rampage/${target.id}/${room.id}',
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onTap});

  final RoomSetup room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.gold.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  room.resolvedAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: room.gradient,
                      ),
                    ),
                    child: Icon(room.icon, color: room.accent, size: 40),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0.35, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${room.props.length} smashable objects',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: room.accent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(room.icon, size: 16, color: Colors.white),
                  ),
                ),
              ],
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
