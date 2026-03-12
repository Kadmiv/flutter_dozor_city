import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_lat_lng.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_preview_segment.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_result.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/entities/transport_route.dart';
import 'package:flutter_dozor_city/features/live_tracking/domain/entities/vehicle_entity.dart';

abstract final class FakeSeedData {
  static const cities = <City>[
    City(
      id: 'zhytomyr',
      name: 'Житомир',
      region: 'Житомирська область',
      centerLat: 50.25465,
      centerLng: 28.65867,
      zoom: 12.5,
    ),
    City(
      id: 'lviv',
      name: 'Львів',
      region: 'Львівська область',
      centerLat: 49.83968,
      centerLng: 24.02972,
      zoom: 12.8,
    ),
    City(
      id: 'ternopil',
      name: 'Тернопіль',
      region: 'Тернопільська область',
      centerLat: 49.55352,
      centerLng: 25.59477,
      zoom: 12.4,
    ),
  ];

  static List<SelectedPoint> suggestions(String query) {
    final normalized = query.trim();
    return [
      SelectedPoint(
        label: '$normalized, Центр',
        lat: 50.25,
        lng: 28.66,
        source: SelectedPointSource.address,
      ),
      SelectedPoint(
        label: '$normalized, Зупинка "Майдан"',
        lat: 50.256,
        lng: 28.641,
        source: SelectedPointSource.zone,
        zoneId: 101,
      ),
    ];
  }

  static List<RouteResult> searchResults(SearchParams params) {
    return [
      RouteResult(
        id: 'direct-1',
        title: 'Маршрут №3 без пересадки',
        startName: params.start.label,
        endName: params.end.label,
        walkToStartMeters: 250,
        walkToEndMeters: 180,
        transferSummary: 'Без пересадок',
        totalDistanceMeters: 5400,
        totalTravelMinutes: 22,
        price: 12.0,
        realStartPoint: AppLatLng(lat: params.start.lat, lng: params.start.lng),
        realEndPoint: AppLatLng(lat: params.end.lat, lng: params.end.lng),
        previewGeometry: _buildPreviewGeometry(
          params.start.lat,
          params.start.lng,
          params.end.lat,
          params.end.lng,
        ),
        previewSegments: [
          RoutePreviewSegment(
            type: RoutePreviewSegmentType.walk,
            label: 'Пішки до зупинки',
            meters: 250,
          ),
          const RoutePreviewSegment(
            type: RoutePreviewSegmentType.ride,
            label: 'Маршрут №3',
          ),
          RoutePreviewSegment(
            type: RoutePreviewSegmentType.walk,
            label: 'Пішки до місця призначення',
            meters: 180,
          ),
        ],
      ),
      RouteResult(
        id: 'transfer-2',
        title: 'Маршрут №7 + №12',
        startName: params.start.label,
        endName: params.end.label,
        walkToStartMeters: 120,
        walkToEndMeters: 300,
        transferSummary: '1 пересадка на зупинці "Площа Перемоги"',
        totalDistanceMeters: 7600,
        totalTravelMinutes: 31,
        price: 20.0,
        realStartPoint: AppLatLng(lat: params.start.lat, lng: params.start.lng),
        realEndPoint: AppLatLng(lat: params.end.lat, lng: params.end.lng),
        previewGeometry: _buildPreviewGeometry(
          params.start.lat,
          params.start.lng,
          params.end.lat,
          params.end.lng,
          offsetLat: 0.01,
          offsetLng: -0.008,
        ),
        previewSegments: [
          RoutePreviewSegment(
            type: RoutePreviewSegmentType.walk,
            label: 'Пішки до першої зупинки',
            meters: 120,
          ),
          const RoutePreviewSegment(
            type: RoutePreviewSegmentType.ride,
            label: 'Маршрут №7',
          ),
          const RoutePreviewSegment(
            type: RoutePreviewSegmentType.transfer,
            label: 'Пересадка на площі Перемоги',
          ),
          const RoutePreviewSegment(
            type: RoutePreviewSegmentType.ride,
            label: 'Маршрут №12',
          ),
          RoutePreviewSegment(
            type: RoutePreviewSegmentType.walk,
            label: 'Пішки до місця призначення',
            meters: 300,
          ),
        ],
      ),
    ];
  }

  static List<AppLatLng> _buildPreviewGeometry(
    double startLat,
    double startLng,
    double endLat,
    double endLng, {
    double offsetLat = 0.006,
    double offsetLng = 0.004,
  }) {
    return [
      AppLatLng(lat: startLat, lng: startLng),
      AppLatLng(
        lat: (startLat + endLat) / 2 + offsetLat,
        lng: (startLng + endLng) / 2 + offsetLng,
      ),
      AppLatLng(lat: endLat, lng: endLng),
    ];
  }

  static List<TransportRoute> routesByType({
    required String cityId,
    required int transportType,
  }) {
    return List.generate(
      4,
      (index) => TransportRoute(
        id: '$cityId-$transportType-$index',
        shortName: '${transportType + 1}${index + 1}',
        title: 'Маршрут ${transportType + 1}${index + 1}',
        transportType: transportType,
        polylineSegments: [
          [
            AppLatLng(
              lat: 50.25465 + (index * 0.003),
              lng: 28.65867 + (index * 0.002),
            ),
            AppLatLng(
              lat: 50.258 + (index * 0.0025),
              lng: 28.666 + (index * 0.0015),
            ),
            AppLatLng(
              lat: 50.264 + (index * 0.002),
              lng: 28.674 + (index * 0.001),
            ),
          ],
        ],
        lineColorValue: switch (transportType % 5) {
          0 => 0xFF0C4A6E,
          1 => 0xFF2563EB,
          2 => 0xFF7C3AED,
          3 => 0xFFDB2777,
          _ => 0xFFEA580C,
        },
      ),
    );
  }

  static List<RouteZone> routeZones(String routeId) {
    return List.generate(
      5,
      (index) => RouteZone(
        id: '$routeId-zone-$index',
        routeId: routeId,
        name: 'Зупинка ${index + 1} для $routeId',
      ),
    );
  }

  static ArrivalInfo arrival(String zoneId) {
    return ArrivalInfo(
      zoneId: zoneId,
      busMinutes: const [2, 7, 14],
      trolleyMinutes: const [5, 11],
      tramMinutes: const [8, 16],
    );
  }

  static List<VehicleEntity> cityVehicles(String cityId) {
    return List.generate(
      6,
      (index) => VehicleEntity(
        id: '$cityId-vehicle-$index',
        routeId: '$cityId-${index % 3}-${index % 2}',
        routeShortName: '${(index % 3) + 1}${(index % 2) + 1}',
        routeTitle: 'Маршрут ${(index % 3) + 1}${(index % 2) + 1}',
        transportType: index % 3,
        lat: 50.25465 + (index * 0.002),
        lng: 28.65867 + (index * 0.0015),
        azimuth: 45 + (index * 15),
        speed: 18 + index,
        govNumber: 'AA10${index}BC',
      ),
    );
  }
}
