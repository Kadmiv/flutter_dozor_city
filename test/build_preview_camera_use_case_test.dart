import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/domain/entities/search_params.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/map/app_map_camera.dart';
import 'package:flutter_dozor_city/features/route_preview/domain/usecases/build_preview_camera_use_case.dart';

void main() {
  group('BuildPreviewCameraUseCase', () {
    const useCase = BuildPreviewCameraUseCase();

    test('builds close zoom for nearby points', () {
      final result = useCase(
        const SearchParams(
          start: SelectedPoint(
            label: 'A',
            lat: 50.254,
            lng: 28.658,
            source: SelectedPointSource.zone,
          ),
          end: SelectedPoint(
            label: 'B',
            lat: 50.271,
            lng: 28.676,
            source: SelectedPointSource.address,
          ),
          transportTypes: {0},
        ),
      );

      expect(
        result,
        const AppMapCamera(
          centerLat: 50.2625,
          centerLng: 28.667,
          zoom: 14.0,
        ),
      );
    });

    test('builds medium zoom for mid-distance points', () {
      final result = useCase(
        const SearchParams(
          start: SelectedPoint(
            label: 'A',
            lat: 50.20,
            lng: 28.60,
            source: SelectedPointSource.zone,
          ),
          end: SelectedPoint(
            label: 'B',
            lat: 50.25,
            lng: 28.65,
            source: SelectedPointSource.address,
          ),
          transportTypes: {0},
        ),
      );

      expect(result.zoom, 12.8);
    });

    test('builds wide zoom for far points', () {
      final result = useCase(
        const SearchParams(
          start: SelectedPoint(
            label: 'A',
            lat: 50.00,
            lng: 28.10,
            source: SelectedPointSource.zone,
          ),
          end: SelectedPoint(
            label: 'B',
            lat: 50.20,
            lng: 28.40,
            source: SelectedPointSource.address,
          ),
          transportTypes: {0},
        ),
      );

      expect(result.zoom, 11.4);
    });
  });
}
