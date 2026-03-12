import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    final citiesResponse = await dio.get('https://city.dozor.tech/ua/cities');
    final citiesList = jsonDecode(citiesResponse.data);
    final cities = (citiesList is List ? citiesList : citiesList['data']) as List;
    
    int totalRoutesWithLines = 0;
    int totalRoutesMissingLines = 0;
    
    for (var cityJson in cities) {
      final cityId = cityJson['id'] ?? cityJson['cityId'];
      final cityName = cityJson['name'] ?? cityJson['name0'];
      
      try {
        final response = await dio.get(
          'https://city.dozor.tech/data?t=1',
          options: Options(headers: {'gts.web.city': cityId}),
        );
        final data = jsonDecode(response.data);
        if (data == null || data['data'] == null) continue;
        final routes = data['data'] as List;
        
        for (var route in routes) {
          final lns = route['lns'] ?? route['lines'];
          if (lns == null || lns.isEmpty) {
            totalRoutesMissingLines++;
          } else {
            bool hasGoodLine = false;
            for (var line in lns) {
               final pts = line['pts'] ?? line['points'];
               if (pts is List && pts.length > 1) {
                 hasGoodLine = true;
                 break;
               }
            }
            if (hasGoodLine) {
              totalRoutesWithLines++;
            } else {
              totalRoutesMissingLines++;
            }
          }
        }
      } catch (e) {
        // ignore city error
      }
    }
    print('Total routes with lines: $totalRoutesWithLines');
    print('Total routes missing lines: $totalRoutesMissingLines');
  } catch (e) {
    print('Failed: $e');
  }
}
