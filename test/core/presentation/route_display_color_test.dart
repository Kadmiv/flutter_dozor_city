import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/presentation/route_display_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteDisplayColor', () {
    test('similar route names should have distinct colors', () {
      final color3 = RouteDisplayColor.fromRouteIdentity(
        shortName: 'TO3',
        title: 'Route TO3',
      );
      final color8 = RouteDisplayColor.fromRouteIdentity(
        shortName: 'TO8',
        title: 'Route TO8',
      );

      final c3 = Color(color3);
      final c8 = Color(color8);

      final hsl3 = HSLColor.fromColor(c3);
      final hsl8 = HSLColor.fromColor(c8);

      // Verify hue difference is significant (at least 20 degrees for visual distinction)
      final hueDiff = (hsl3.hue - hsl8.hue).abs();
      final wrappedHueDiff = hueDiff > 180 ? 360 - hueDiff : hueDiff;

      print('TO3 Color: $c3, Hue: ${hsl3.hue}');
      print('TO8 Color: $c8, Hue: ${hsl8.hue}');
      print('Hue Difference: $wrappedHueDiff');

      expect(wrappedHueDiff, greaterThan(20.0), reason: 'Hues should be distinct for TO3 and TO8');
    });

    test('different routes should generally have different colors', () {
      final routes = ['TO1', 'TO2', 'TO3', 'TO4', 'TO5', 'TO6', 'TO7', 'TO8', 'TO9'];
      final colors = routes.map((name) => RouteDisplayColor.fromRouteIdentity(
            shortName: name,
            title: 'Route $name',
          )).toList();

      // Check that they are not all the same
      final uniqueColors = colors.toSet();
      expect(uniqueColors.length, equals(routes.length));
    });
  });
}
