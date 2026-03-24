// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anti_reup_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AntiReupConfig _$AntiReupConfigFromJson(Map<String, dynamic> json) =>
    _AntiReupConfig(
      isRandomized: json['isRandomized'] as bool? ?? true,
      speedMultiplier: (json['speedMultiplier'] as num?)?.toDouble() ?? 1.05,
      enableVisualNoise: json['enableVisualNoise'] as bool? ?? true,
      noiseLevel: (json['noiseLevel'] as num?)?.toDouble() ?? 0.05,
      colorShiftIntensity:
          (json['colorShiftIntensity'] as num?)?.toDouble() ?? 0.05,
      enableAudioPitchShift: json['enableAudioPitchShift'] as bool? ?? true,
      stripMetadata: json['stripMetadata'] as bool? ?? true,
      targetDuration: (json['targetDuration'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AntiReupConfigToJson(_AntiReupConfig instance) =>
    <String, dynamic>{
      'isRandomized': instance.isRandomized,
      'speedMultiplier': instance.speedMultiplier,
      'enableVisualNoise': instance.enableVisualNoise,
      'noiseLevel': instance.noiseLevel,
      'colorShiftIntensity': instance.colorShiftIntensity,
      'enableAudioPitchShift': instance.enableAudioPitchShift,
      'stripMetadata': instance.stripMetadata,
      'targetDuration': instance.targetDuration,
    };
