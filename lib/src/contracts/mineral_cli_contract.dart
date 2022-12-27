import 'package:mineral_cli/mineral_cli.dart';
import 'package:mineral_console/mineral_console.dart';

abstract class MineralCliContract {
  Map<String, CliCommand> get commands;

  Future<void> handle (List<String> arguments);
  void register (List<CliCommand> commands);
  void defineConsoleTheme (Theme theme);
}