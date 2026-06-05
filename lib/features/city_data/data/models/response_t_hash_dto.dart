class CityHashResponseDto {
  const CityHashResponseDto({required this.hash});

  final int hash;

  factory CityHashResponseDto.fromJson(Map<String, dynamic> json) {
    return CityHashResponseDto(
      hash: (json['hash'] as num? ?? 0).toInt(),
    );
  }
}

typedef ResponseTHashModel = CityHashResponseDto;
