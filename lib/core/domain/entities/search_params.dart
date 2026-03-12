import 'package:equatable/equatable.dart';
import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';

class SearchParams extends Equatable {
  const SearchParams({
    required this.start,
    required this.end,
    required this.transportTypes,
  });

  final SelectedPoint start;
  final SelectedPoint end;
  final Set<int> transportTypes;

  @override
  List<Object> get props => [start, end, transportTypes];
}
