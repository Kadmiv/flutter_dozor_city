import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/network/api_paths.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';

class CityPickerContent extends StatefulWidget {
  const CityPickerContent({
    super.key,
    this.showHeader = true,
    this.title = 'Вибір міста',
    this.onBack,
    this.onCityTapOverride,
  });

  final bool showHeader;
  final String title;
  final VoidCallback? onBack;
  final Future<void> Function(BuildContext context, City city)? onCityTapOverride;

  @override
  State<CityPickerContent> createState() => _CityPickerContentState();
}

class _CityPickerContentState extends State<CityPickerContent> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CitySelectionBloc, CitySelectionState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredCities = _filterCities(state.cities, _query);

        return Column(
          children: [
            if (widget.showHeader)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF1C4F7A),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(26),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Назад',
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Оберіть місто для мапи, маршрутів і прогнозу прибуття',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                widget.showHeader ? 14 : 16,
                16,
                8,
              ),
              child: _CitySearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                onClear: _query.isEmpty
                    ? null
                    : () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
              ),
            ),
            Expanded(
              child: filteredCities.isEmpty
                  ? const _EmptyCitiesState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        final isBusy =
                            state.isSubmitting && state.selectedCity == city;
                        return _CityRow(
                          city: city,
                          isBusy: isBusy,
                          onTap: state.isSubmitting
                              ? null
                              : () async {
                                  final onCityTap = widget.onCityTapOverride;
                                  if (onCityTap != null) {
                                    await onCityTap(context, city);
                                    return;
                                  }
                                  context
                                      .read<CitySelectionBloc>()
                                      .add(CitySelectionSubmitted(city));
                                },
                          );
                      },
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemCount: filteredCities.length,
                    ),
            ),
          ],
        );
      },
    );
  }

  List<City> _filterCities(List<City> cities, String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return cities;
    }
    return cities
        .where((city) => _matchesCity(city, normalizedQuery))
        .toList(growable: false);
  }

  bool _matchesCity(City city, String normalizedQuery) {
    final haystack = _normalize('${city.name} ${city.region}');
    if (haystack.contains(normalizedQuery)) {
      return true;
    }
    return _isSubsequence(normalizedQuery, haystack);
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-_.,()]+'), '')
        .replaceAll('ь', '')
        .replaceAll('ъ', '')
        .replaceAll('і', 'и');
  }

  bool _isSubsequence(String needle, String haystack) {
    if (needle.isEmpty) {
      return true;
    }
    var index = 0;
    for (final codeUnit in haystack.codeUnits) {
      if (codeUnit == needle.codeUnitAt(index)) {
        index++;
        if (index == needle.length) {
          return true;
        }
      }
    }
    return false;
  }
}

class _CitySearchField extends StatelessWidget {
  const _CitySearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Пошук міста',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
                tooltip: 'Очистити пошук',
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _EmptyCitiesState extends StatelessWidget {
  const _EmptyCitiesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Місто не знайдено',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.58),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.city,
    required this.isBusy,
    required this.onTap,
  });

  final City city;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                '${ApiPaths.baseUrl}${ApiPaths.cityEmblem(city.id)}',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: Color(0xFF1C4F7A),
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17324D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    city.region,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
            isBusy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.chevron_right,
                    color: Colors.black.withValues(alpha: 0.48),
                  ),
          ],
        ),
      ),
    );
  }
}
