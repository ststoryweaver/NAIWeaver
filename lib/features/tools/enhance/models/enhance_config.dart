class EnhanceConfig {
  final double strength;
  final double noise;
  final double scale;

  const EnhanceConfig({
    this.strength = 0.5,
    this.noise = 0.0,
    this.scale = 1.0,
  });

  EnhanceConfig copyWith({
    double? strength,
    double? noise,
    double? scale,
  }) {
    return EnhanceConfig(
      strength: strength ?? this.strength,
      noise: noise ?? this.noise,
      scale: scale ?? this.scale,
    );
  }
}
