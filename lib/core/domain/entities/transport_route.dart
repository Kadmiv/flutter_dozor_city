import 'package:equatable/equatable.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_display_language.dart';

class TransportRoute extends Equatable {
  const TransportRoute({
    required this.id,
    required this.shortName,
    required this.title,
    required this.transportType,
    this.shortNameKa,
    this.shortNameEn,
    this.titleKa,
    this.titleEn,
    this.polylineSegments = const [],
    this.polylineSegmentsByStatus = const {},
    this.lineColorValue = 0xFF1C4F7A,
  });

  final String id;
  final String shortName;
  final String title;
  final int transportType;
  final String? shortNameKa;
  final String? shortNameEn;
  final String? titleKa;
  final String? titleEn;
  final List<List<AppLatLng>> polylineSegments;
  final Map<int, List<List<AppLatLng>>> polylineSegmentsByStatus;
  final int lineColorValue;

  String displayShortName(AppDisplayLanguage language) {
    return switch (language) {
      AppDisplayLanguage.ka =>
        shortNameKa?.trim().isNotEmpty == true
            ? shortNameKa!
            : shortNameEn?.trim().isNotEmpty == true
            ? shortNameEn!
            : shortName,
      AppDisplayLanguage.en =>
        shortNameEn?.trim().isNotEmpty == true
            ? shortNameEn!
            : shortNameKa?.trim().isNotEmpty == true
            ? shortNameKa!
            : shortName,
    };
  }

  String displayTitle(AppDisplayLanguage language) {
    return switch (language) {
      AppDisplayLanguage.ka =>
        titleKa?.trim().isNotEmpty == true
            ? titleKa!
            : titleEn?.trim().isNotEmpty == true
            ? titleEn!
            : title,
      AppDisplayLanguage.en =>
        titleEn?.trim().isNotEmpty == true
            ? titleEn!
            : titleKa?.trim().isNotEmpty == true
            ? titleKa!
            : title,
    };
  }

  List<List<AppLatLng>> displayPolylineSegments(int? routeStatus) {
    if (routeStatus != null &&
        polylineSegmentsByStatus[routeStatus]?.isNotEmpty == true) {
      return polylineSegmentsByStatus[routeStatus]!;
    }
    return polylineSegments;
  }

  @override
  List<Object?> get props => [
    id,
    shortName,
    title,
    transportType,
    shortNameKa,
    shortNameEn,
    titleKa,
    titleEn,
    polylineSegments,
    polylineSegmentsByStatus,
    lineColorValue,
  ];
}
