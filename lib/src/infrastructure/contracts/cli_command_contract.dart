import 'dart:async';

import 'package:mineral_cli/src/infrastructure/entities/cli_command.dart';

abstract interface class CliCommandContract {
  String get name;
  String get description;
  FutureOr handle(List<MineralCommand> commands, List<String> arguments);
}
