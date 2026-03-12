class ResponseTHashModel {
  const ResponseTHashModel({required this.hash});

  final int hash;

  factory ResponseTHashModel.fromJson(Map<String, dynamic> json) {
    return ResponseTHashModel(
      hash: (json['hash'] as num? ?? 0).toInt(),
    );
  }
}
