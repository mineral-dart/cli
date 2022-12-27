import 'package:args/args.dart';
import 'package:mineral_cli/src/cli_command.dart';

class CommandManager {
  final ArgParser parser = ArgParser();
  final Map<String, CliCommand> commands = {};

  void register (CliCommand command) {
    commands.putIfAbsent(command.name, () => command);

    final ArgParser parser = ArgParser();
    if (command.arguments.isNotEmpty) {
      for (final argument in command.arguments) {
        parser.addOption(argument);
      }
    }

    this.parser.addCommand(command.name, parser);
  }
}