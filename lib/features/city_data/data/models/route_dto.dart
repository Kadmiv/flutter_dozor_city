import 'package:flutter_dozor_city/features/city_data/data/models/route_line_dto.dart';
import 'package:flutter_dozor_city/features/city_data/data/models/route_zone_shape_dto.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/core/presentation/route_display_color.dart';

class RouteDto {
  const RouteDto({
    required this.id,
    required this.names,
    required this.shortName,
    required this.info,
    required this.transportType,
    required this.lines,
    required this.zones,
    required this.outLineColor,
    required this.price,
  });

  final int id;
  final List<String> names;
  final String shortName;
  final String info;
  final int? transportType;
  final List<RouteLineDto> lines;
  final List<RouteZoneShapeDto> zones;
  final String outLineColor;
  final double price;

  factory RouteDto.fromJson(Map<String, Object?> json) {
    final rawNames =
        _stringList(json['nm']) ?? _stringList(json['name']) ?? const [];
    final rawLines =
        _objectList(json['lns']) ?? _objectList(json['lines']) ?? const [];
    final rawZones =
        _objectList(json['zns']) ?? _objectList(json['zones']) ?? const [];
    return RouteDto(
      id: _int(json['id']),
      names: rawNames,
      shortName: _string(json['sNm']).isNotEmpty
          ? _string(json['sNm'])
          : _string(json['shortName']),
      info: _string(json['inf']).isNotEmpty
          ? _string(json['inf'])
          : _string(json['info']),
      transportType: json['transportType'] == null
          ? null
          : _int(json['transportType']),
      lines: rawLines
          .map((item) => RouteLineDto.fromJson(item))
          .toList(growable: false),
      zones: rawZones
          .map((item) => RouteZoneShapeDto.fromJson(item))
          .toList(growable: false),
      outLineColor: _string(json['oLC']).isNotEmpty
          ? _string(json['oLC'])
          : _string(json['outLineColor']),
      price: _double(json['prc'] ?? json['price']),
    );
  }

  TransportRoute toEntity({required int transportType}) {
    final polylineSegments = lines
        .map(
          (line) => line.points
              .map((point) => point.toEntity())
              .toList(growable: false),
        )
        .where((segment) => segment.length > 1)
        .toList(growable: false);
    final routeTitle = names.length > 1
        ? names[1]
        : names.firstOrNull ?? 'Route $id';
    final displayColorValue = RouteDisplayColor.fromRouteIdentity(
      shortName: shortName,
      title: routeTitle,
    );
    return TransportRoute(
      id: '$id',
      shortName: shortName,
      title: routeTitle,
      transportType: transportType,
      shortNameEn: shortName,
      titleKa: names.length > 1 ? names[0] : routeTitle,
      titleEn: routeTitle,
      polylineSegments: polylineSegments,
      lineColorValue: displayColorValue,
    );
  }
}

typedef JsonRouteModel = RouteDto;

List<String>? _stringList(Object? raw) {
  if (raw is List) {
    return raw
        .map((item) => '$item')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return null;
}

List<Map<String, Object?>>? _objectList(Object? raw) {
  if (raw is List) {
    final result = <Map<String, Object?>>[];
    for (final item in raw) {
      final map = _objectMap(item);
      if (map != null) {
        result.add(map);
      }
    }
    return result;
  }
  return null;
}

Map<String, Object?>? _objectMap(Object? raw) {
  if (raw is Map<String, Object?>) {
    return raw;
  }
  if (raw is Map) {
    final result = <String, Object?>{};
    for (final entry in raw.entries) {
      result['${entry.key}'] = entry.value;
    }
    return result;
  }
  return null;
}

String _string(Object? raw) => raw == null ? '' : '$raw';

int _int(Object? raw) {
  if (raw is num) {
    return raw.toInt();
  }
  return int.tryParse('$raw') ?? 0;
}

double _double(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse('$raw') ?? 0;
}
