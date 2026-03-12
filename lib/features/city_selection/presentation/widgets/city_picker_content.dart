import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dozor_city/core/domain/entities/city.dart';
import 'package:flutter_dozor_city/core/network/api_paths.dart';
import 'package:flutter_dozor_city/features/city_selection/presentation/bloc/city_selection_cubit.dart';

class CityPickerContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocBuilder<CitySelectionCubit, CitySelectionState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            if (showHeader)
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
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back,
                            ),
                            tooltip: 'Назад',
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              title,
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
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                itemBuilder: (context, index) {
                  final city = state.cities[index];
                  final isBusy = state.isSubmitting && state.selectedCity == city;
                  return _CityRow(
                    city: city,
                    isBusy: isBusy,
                    onTap: state.isSubmitting
                        ? null
                        : () async {
                            final onCityTap = onCityTapOverride;
                            if (onCityTap != null) {
                              await onCityTap(context, city);
                              return;
                            }
                            await context
                                .read<CitySelectionCubit>()
                                .selectCity(city);
                          },
                  );
                },
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemCount: state.cities.length,
              ),
            ),
          ],
        );
      },
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
