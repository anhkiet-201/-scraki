import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/image_overlay_item/image_overlay_item_store.dart';

void main() {
  group('ImageOverlayItemStore rotation-aware drag and resize', () {
    late ImageOverlayItemStore store;

    setUp(() {
      store = ImageOverlayItemStore(
        id: 'img_1',
        initialX: 0.5,
        initialY: 0.5,
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
        initialWidth: 50,
        initialHeight: 50,
        onPositionUpdate: (_, _, _) {},
        onSelect: (_) {},
        onResize: (_, _, _) {},
      );
    });

    test('handleDrag at 0 degrees moves directly along parent axes', () {
      store.handleDrag(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(10, -20),
        ),
        0.0,
      );

      expect(store.x, closeTo(0.6, 1e-6));
      expect(store.y, closeTo(0.3, 1e-6));
    });

    test('handleDrag at 90 degrees converts local delta to parent axes', () {
      // Screen drag right (+10, 0) appears as local (0, -10) when rotated +90 deg.
      store.handleDrag(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(0, -10),
        ),
        90.0,
      );

      expect(store.x, closeTo(0.6, 1e-6));
      expect(store.y, closeTo(0.5, 1e-6));
    });

    test('handleDrag at 180 degrees converts inverted local delta to parent axes', () {
      // Screen drag right (+10, 0) appears as local (-10, 0) when rotated 180 deg.
      store.handleDrag(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(-10, 0),
        ),
        180.0,
      );

      expect(store.x, closeTo(0.6, 1e-6));
      expect(store.y, closeTo(0.5, 1e-6));
    });

    test('handleDrag at -90 degrees converts local delta to parent axes', () {
      // Screen drag right (+10, 0) appears as local (0, +10) when rotated -90 deg.
      store.handleDrag(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(0, 10),
        ),
        -90.0,
      );

      expect(store.x, closeTo(0.6, 1e-6));
      expect(store.y, closeTo(0.5, 1e-6));
    });

    test('handleResize at 90 degrees expands width in local space and shifts center in parent space', () {
      // Dragging right edge (+1, 0) outward by +10 in local space -> width +10, center shifts +5 local X -> +5 parent Y.
      store.handleResize(
        details: DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(10, 0),
        ),
        multiplierX: 1,
        multiplierY: 0,
        rotation: 90.0,
      );

      expect(store.width, closeTo(60, 1e-6));
      expect(store.height, closeTo(50, 1e-6));
      expect(store.x, closeTo(0.5, 1e-6));
      expect(store.y, closeTo(0.55, 1e-6));
    });
  });
}

