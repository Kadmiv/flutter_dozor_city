import 'package:flutter_dozor_city/core/domain/entities/selected_point.dart';
import 'package:flutter_dozor_city/core/domain/repositories/search_draft_repository.dart';
import 'package:hive/hive.dart';

class HiveSearchDraftRepository implements SearchDraftRepository {
  HiveSearchDraftRepository({required Box<dynamic> box}) : _box = box;

  final Box<dynamic> _box;

  static const _draftKey = 'route_search_draft';

  @override
  Future<void> clearDraft() async {
    await _box.delete(_draftKey);
  }

  @override
  Future<SearchDraft> loadDraft() async {
    final raw = _box.get(_draftKey);
    if (raw is! Map) {
      return const SearchDraft();
    }
    return SearchDraft(
      start: _readPoint(raw['start']),
      end: _readPoint(raw['end']),
      transportTypes: _readTypes(raw['transportTypes']),
    );
  }

  @override
  Future<void> saveDraft(SearchDraft draft) async {
    await _box.put(_draftKey, <String, dynamic>{
      'start': _writePoint(draft.start),
      'end': _writePoint(draft.end),
      'transportTypes': draft.transportTypes.toList(growable: false),
    });
  }

  SelectedPoint? _readPoint(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final sourceRaw = raw['source'] as String? ?? SelectedPointSource.address.name;
    final source = SelectedPointSource.values.firstWhere(
      (value) => value.name == sourceRaw,
      orElse: () => SelectedPointSource.address,
    );
    return SelectedPoint(
      label: raw['label'] as String,
      lat: (raw['lat'] as num).toDouble(),
      lng: (raw['lng'] as num).toDouble(),
      source: source,
      zoneId: (raw['zoneId'] as num?)?.toInt(),
    );
  }

  Set<int> _readTypes(dynamic raw) {
    if (raw is! List) {
      return const {0};
    }
    return raw.map((item) => (item as num).toInt()).toSet();
  }

  Map<String, dynamic>? _writePoint(SelectedPoint? point) {
    if (point == null) {
      return null;
    }
    return <String, dynamic>{
      'label': point.label,
      'lat': point.lat,
      'lng': point.lng,
      'source': point.source.name,
      'zoneId': point.zoneId,
    };
  }
}
