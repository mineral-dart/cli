import 'package:mineral_cli/src/infrastructure/builder/class/parameter_struct.dart';

final class MethodStruct {
  final String name;
  final ParameterStruct returnType;
  late final StringBuffer? body;
  final List<ParameterStruct> parameters;
  final bool isOverride;
  final bool isAsync;

  MethodStruct({
    required this.name,
    required this.returnType,
    required this.body,
    this.parameters = const [],
    this.isOverride = false,
    this.isAsync = false,
  });
}
