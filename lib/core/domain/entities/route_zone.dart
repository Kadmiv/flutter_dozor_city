import 'package:equatable/equatable.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_display_language.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';

class RouteZone extends Equatable {
  const RouteZone({
    required this.id,
    required this.routeId,
    required this.name,
    this.nameKa,
    this.nameEn,
    this.status,
    this.position,
  });

  final String id;
  final String routeId;
  final String name;
  final String? nameKa;
  final String? nameEn;
  final int? status;
  final AppLatLng? position;

  String displayName(AppDisplayLanguage language) {
    return switch (language) {
      AppDisplayLanguage.ka =>
        nameKa?.trim().isNotEmpty == true
            ? nameKa!
            : nameEn?.trim().isNotEmpty == true
            ? nameEn!
            : name,
      AppDisplayLanguage.en =>
        nameEn?.trim().isNotEmpty == true
            ? nameEn!
            : nameKa?.trim().isNotEmpty == true
            ? nameKa!
            : name,
    };
  }

  @override
  List<Object?> get props => [
    id,
    routeId,
    name,
    nameKa,
    nameEn,
    status,
    position,
  ];
}
