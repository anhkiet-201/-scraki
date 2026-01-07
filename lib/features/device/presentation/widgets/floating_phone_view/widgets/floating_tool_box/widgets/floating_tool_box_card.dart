import 'package:flutter/material.dart';
import 'package:scraki/core/widgets/box_card.dart';

class FloatingToolBoxCard extends BoxCard {
  const FloatingToolBoxCard({
    super.key,
    required super.child,
    super.height,
    super.width,
    super.margin = const EdgeInsets.only(left: 12),
    super.padding,
  });
}