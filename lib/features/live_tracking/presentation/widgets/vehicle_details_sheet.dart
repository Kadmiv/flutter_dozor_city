import 'package:flutter/material.dart';
import 'package:flutter_dozor_city/core/domain/entities/vehicle.dart';

class VehicleDetailsSheet extends StatelessWidget {
  const VehicleDetailsSheet({
    super.key,
    required this.vehicle,
    required this.routeColorValue,
  });

  final Vehicle vehicle;
  final int routeColorValue;

  @override
  Widget build(BuildContext context) {
    final color = Color(routeColorValue);
    return FractionallySizedBox(
      heightFactor: 0.40,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0E5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
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
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Маршрут ${vehicle.routeShortName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF17324D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vehicle.routeTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF5A6A7A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFFD64545)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Державний номер', value: vehicle.govNumber),
                _InfoRow(label: 'Швидкість', value: '${vehicle.speed} км/год'),
                _InfoRow(label: 'Напрямок', value: '${vehicle.azimuth}°'),
                _InfoRow(
                  label: 'Тип',
                  value: 'Транспорт ${vehicle.transportType}',
                ),
                const Spacer(),
                Text(
                  'Остання позиція автобуса на мапі',
                  style: TextStyle(
                    color: const Color(0xFF17324D).withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vehicle.lat.toStringAsFixed(5)}, ${vehicle.lng.toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: Color(0xFF17324D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5A6A7A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
