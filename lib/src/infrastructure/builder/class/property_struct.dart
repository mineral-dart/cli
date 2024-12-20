import 'package:mineral_cli/src/infrastructure/builder/class/parameter_struct.dart';

final class PropertyStruct {
  final String name;
  final bool isOverride;
  final bool isGetter;
  final bool isSetter;
  final bool isFinal;
  final bool isStatic;
  final ParameterStruct? returnType;

  PropertyStruct({
    required this.name,
    this.isOverride = false,
    this.isGetter = false,
    this.isSetter = false,
    this.isFinal = false,
    this.isStatic = false,
    this.returnType,
  });
}
