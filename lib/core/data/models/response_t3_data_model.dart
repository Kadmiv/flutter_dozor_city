import 'package:flutter_dozor_city/core/data/models/arrival_info_model.dart';
import 'package:flutter_dozor_city/core/domain/entities/arrival_info.dart';

class ResponseT3DataModel {
  const ResponseT3DataModel({required this.arrivalInfo});

  final ArrivalInfo arrivalInfo;

  factory ResponseT3DataModel.fromJson({
    required String zoneId,
    required Map<String, dynamic> json,
  }) {
    return ResponseT3DataModel(
      arrivalInfo: ArrivalInfoModel.fromJson(<String, dynamic>{
        ...json,
        'zoneId': zoneId,
      }).toEntity(),
    );
  }
}
