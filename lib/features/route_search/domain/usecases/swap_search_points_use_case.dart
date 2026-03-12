import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';

typedef SearchPointsPair = ({SelectedPoint? start, SelectedPoint? end});

class SwapSearchPointsUseCase {
  const SwapSearchPointsUseCase();

  SearchPointsPair call({
    required SelectedPoint? start,
    required SelectedPoint? end,
  }) {
    return (start: end, end: start);
  }
}
