import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class RouteDisplayColor {
  static int fromRouteIdentity({
    required String shortName,
    required String title,
  }) {
    final seed = shortName.trim().isNotEmpty ? shortName.trim() : title.trim();
    if (seed.isEmpty) {
      return const Color(0xFF1C4F7A).toARGB32();
    }
    var hash = 0;
    for (final codeUnit in seed.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    final hue = (hash % 360).toDouble();
    final saturation = 0.68 + ((hash % 7) * 0.02);
    final lightness = 0.46 + ((hash % 5) * 0.02);
    return HSLColor.fromAHSL(
      1,
      hue,
      math.min(saturation, 0.82),
      math.min(lightness, 0.58),
    ).toColor().toARGB32();
  }
}
