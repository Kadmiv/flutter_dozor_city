import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/app_display_language.dart';
import 'package:flutter_dozor_city/core/domain/entities/route_zone.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_language_cubit.dart';
import 'package:flutter_dozor_city/features/main_map/presentation/bloc/map_stops_cubit.dart';

class StopSearchSheet extends StatefulWidget {
  const StopSearchSheet({super.key});

  @override
  State<StopSearchSheet> createState() => _StopSearchSheetState();
}

class _StopSearchSheetState extends State<StopSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _query = value.trim();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.76,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0E5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: BlocBuilder<MapStopsBloc, MapStopsState>(
              builder: (context, stopsState) {
                return BlocBuilder<MapLanguageBloc, MapLanguageState>(
                  builder: (context, languageState) {
                    final filtered = _filterStops(stopsState.cityStops, _query);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB8B4A8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Пошук зупинки',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF17324D),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFFD64545),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: _onQueryChanged,
                          decoration: InputDecoration(
                            hintText: 'Пошук за назвою зупинки',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.search, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          stopsState.isLoading && stopsState.cityStops.isEmpty
                              ? 'Завантажуємо зупинки'
                              : '${filtered.length} зупинок',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.56),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (stopsState.isLoading &&
                            stopsState.cityStops.isEmpty)
                          const Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (filtered.isEmpty)
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Нічого не знайдено',
                                style: TextStyle(
                                  color: Color(0xFF4E6378),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final stop = filtered[index];
                                final displayName = stop.displayName(
                                  languageState.language,
                                );
                                return InkWell(
                                  onTap: () => Navigator.of(context).pop(stop),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Ink(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1C4F7A),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.directions_bus_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                style: const TextStyle(
                                                  color: Color(0xFF17324D),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _subtitle(
                                                  stop,
                                                  languageState.language,
                                                ),
                                                style: TextStyle(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.56),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<RouteZone> _filterStops(List<RouteZone> stops, String query) {
    if (query.isEmpty) {
      return stops;
    }
    final lower = query.toLowerCase();
    return stops
        .where((stop) {
          final values = <String>[
            stop.name,
            stop.nameEn ?? '',
            stop.nameKa ?? '',
          ];
          return values.any((value) => value.toLowerCase().contains(lower));
        })
        .toList(growable: false);
  }

  String _subtitle(RouteZone stop, AppDisplayLanguage language) {
    final routePart = stop.routeId.isNotEmpty ? 'Маршрут ${stop.routeId}' : '';
    final languagePart = switch (language) {
      AppDisplayLanguage.ka =>
        stop.nameKa?.trim().isNotEmpty == true ? 'KA' : 'UA',
      AppDisplayLanguage.en =>
        stop.nameEn?.trim().isNotEmpty == true ? 'EN' : 'UA',
    };
    if (routePart.isEmpty) {
      return languagePart;
    }
    return '$routePart • $languagePart';
  }
}
