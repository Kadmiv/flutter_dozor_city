class CityHashResponseDto {
  const CityHashResponseDto({required this.hash});

  final int hash;

  factory CityHashResponseDto.fromJson(Map<String, Object?> json) {
    return CityHashResponseDto(
      hash: _int(json['hash']),
    );
  }
}

typedef ResponseTHashModel = CityHashResponseDto;

int _int(Object? raw) {
  if (raw is num) {
    return raw.toInt();
  }
  return int.tryParse('$raw') ?? 0;
}
