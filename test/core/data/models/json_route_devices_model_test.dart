import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dozor_city/core/data/models/json_route_devices_model.dart';

void main() {
  group('JsonRouteDevicesModel', () {
    test('should parse from JSON with rId and dvs', () {
      final json = {
        'rId': 123,
        'dvs': [
          {
            'id': 1,
            'loc': {'lat': 50.4501, 'lng': 30.5234},
            'azi': 90,
            'spd': 40,
            'gNb': 'AA1234BB'
          }
        ]
      };

      final model = JsonRouteDevicesModel.fromJson(json);

      expect(model.routeId, 123);
      expect(model.devices.length, 1);
      expect(model.devices[0].id, 1);
      expect(model.devices[0].location.lat, 50.4501);
      expect(model.devices[0].location.lng, 30.5234);
      expect(model.devices[0].azimuth, 90);
      expect(model.devices[0].speed, 40);
      expect(model.devices[0].govNumber, 'AA1234BB');
    });

    test('should fallback to routeId and devices if rId and dvs are missing', () {
      final json = {
        'routeId': 456,
        'devices': [
          {
            'id': 2,
            'location': {'lat': 48.4647, 'lng': 35.0462},
            'azimuth': 180,
            'speed': 0,
            'govNumber': 'BB5678CC'
          }
        ]
      };

      final model = JsonRouteDevicesModel.fromJson(json);

      expect(model.routeId, 456);
      expect(model.devices.length, 1);
      expect(model.devices[0].id, 2);
    });
  });
}
