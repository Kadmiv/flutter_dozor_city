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

  factory TransportRouteModel.fromJson(Map<String, dynamic> json) {
    return TransportRouteModel(
      id: '${json['id']}',
      shortName: json['shortName'] as String? ?? json['sNm'] as String? ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      transportType: (json['transportType'] as num? ?? 0).toInt(),
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
