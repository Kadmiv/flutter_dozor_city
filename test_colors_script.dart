import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_dozor_city/core/presentation/route_display_color.dart';

void main() {
  final testNames = ['1', '1А', '1Б', '2', '3', '4', '5', '8', '10', '110'];
  for (var name in testNames) {
    try {
      final colorValue = RouteDisplayColor.fromRouteIdentity(shortName: name, title: name);
      final color = Color(colorValue);
      print('Route $name -> hash value: $colorValue, Color ARGB: alpha=${color.alpha}, R=${color.red}, G=${color.green}, B=${color.blue}');
    } catch (e) {
      print('Route $name failed: $e');
    }
  }
}
