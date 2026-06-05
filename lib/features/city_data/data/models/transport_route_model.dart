import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';

class TransportRouteModel {
  const TransportRouteModel({
    required this.id,
    required this.shortName,
    required this.title,
    required this.transportType,
  });

  final String id;
  final String shortName;
  final String title;
  final int transportType;

  factory TransportRouteModel.fromJson(Map<String, Object?> json) {
    return TransportRouteModel(
      id: _string(json['id']),
      shortName: _string(json['shortName']).isNotEmpty
          ? _string(json['shortName'])
          : _string(json['sNm']),
      title: _string(json['title']).isNotEmpty ? _string(json['title']) : _string(json['name']),
      transportType: _int(json['transportType']),
    );
  }

  TransportRoute toEntity() {
    return TransportRoute(
      id: id,
      shortName: shortName,
      title: title,
      transportType: transportType,
    );
  }
}

String _string(Object? raw) => raw == null ? '' : '$raw';

int _int(Object? raw) {
  if (raw is num) {
    return raw.toInt();
  }
  return int.tryParse('$raw') ?? 0;
}
