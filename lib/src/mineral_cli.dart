import 'package:args/args.dart';
import 'package:mineral_cli/mineral_cli.dart';
import 'package:mineral_cli/src/command_manager.dart';
import 'package:mineral_ioc/ioc.dart';

class MineralCli extends MineralService implements MineralCliContract {
  late Console console;

  final Theme theme;
  final CommandManager manager = CommandManager();

  MineralCli(this.theme): super(inject: true) {
    console = Console(theme: theme);
  }

  @override
  Map<String, CliCommand> get commands => manager.commands;

  @override
  Future<void> handle (List<String> arguments) async {
    ArgResults results = manager.parser.parse(arguments);
    final command = manager.commands[results.command?.name ?? 'help'];

    if (command != null) {
      if (command.arguments.isNotEmpty && results.arguments.length - 1 != command.arguments.length) {
        command.console.error('Please provide ${command.arguments.map((e) => '<$e>').join(', ')} params.');
        return;
      }

      final params = {};
      for (int i = 0; i < command.arguments.length; i++) {
        params.putIfAbsent(command.arguments[i], () => results.arguments[i + 1]);
      }

      return await command.handle(params);
    }
  }

  @override
  void register (List<CliCommand> commands) {
    for (final command in commands) {
      manager.register(command);
    }
  }

  @override
  void defineConsoleTheme (Theme theme) {
    console = Console(theme: theme);
  }
}