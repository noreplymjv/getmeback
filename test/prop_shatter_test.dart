import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/widgets/prop_shatter_fx.dart';

void main() {
  test('PropShatterController burst spawns shards', () {
    final ctrl = PropShatterController();
    expect(ctrl.shards, isEmpty);

    ctrl.burst(
      at: const Offset(100, 200),
      color: Colors.white,
      style: PropShatterStyle.glass,
      count: 12,
    );
    expect(ctrl.shards, hasLength(12));
    expect(ctrl.shards.every((s) => s.style == PropShatterStyle.glass), isTrue);

    ctrl.burst(
      at: Offset.zero,
      color: Colors.red,
      style: PropShatterStyle.metal,
      count: 8,
    );
    expect(ctrl.shards, hasLength(20));

    ctrl.tick(0.016);
    expect(ctrl.shards, isNotEmpty);
    expect(ctrl.shards.first.life, lessThan(ctrl.shards.first.maxLife));

    ctrl.clear();
    expect(ctrl.shards, isEmpty);
    ctrl.dispose();
  });

  test('each shatter style produces distinct shard shapes', () {
    final ctrl = PropShatterController();
    for (final style in PropShatterStyle.values) {
      ctrl.burst(at: const Offset(50, 50), style: style, count: 4);
    }
    expect(ctrl.shards, hasLength(16));
    expect(
      ctrl.shards.map((s) => s.style).toSet(),
      PropShatterStyle.values.toSet(),
    );
    ctrl.dispose();
  });
}
