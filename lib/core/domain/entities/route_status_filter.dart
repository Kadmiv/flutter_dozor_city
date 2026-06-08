enum RouteStatusFilter { all, status1, status2, unknown }

extension RouteStatusFilterX on RouteStatusFilter {
  int? get statusValue => switch (this) {
    RouteStatusFilter.status1 => 1,
    RouteStatusFilter.status2 => 2,
    RouteStatusFilter.unknown => -1,
    RouteStatusFilter.all => null,
  };

  String get code => name;

  static RouteStatusFilter fromCode(String? raw) {
    final value = raw?.trim();
    return RouteStatusFilter.values.firstWhere(
      (item) => item.name == value,
      orElse: () => RouteStatusFilter.all,
    );
  }
}
