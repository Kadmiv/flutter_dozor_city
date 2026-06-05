import 'package:flutter_dozor_city/features/city_data/data/models/arrival_info_dto.dart';

class ResponseT3DataModel {
  const ResponseT3DataModel({required this.arrivalInfo});

  final ArrivalInfoModel arrivalInfo;

  factory ResponseT3DataModel.fromJson({
    required String zoneId,
    required Map<String, dynamic> json,
  }) {
    return ResponseT3DataModel(
      arrivalInfo: ArrivalInfoModel.fromJson(<String, dynamic>{
        ...json,
        'zoneId': zoneId,
      }),
    );
  }
}
