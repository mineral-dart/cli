// import 'dart:io';
//
// import 'package:args/args.dart';
// import 'package:mineral_cli/src/commands/create_project.dart';
// import 'package:mineral_cli/src/commands/help.dart';
// import 'package:mineral_cli/src/commands/make/command.dart';
// import 'package:mineral_cli/src/commands/make/event.dart';
// import 'package:mineral_cli/src/commands/make/module.dart';
// import 'package:mineral_cli/src/commands/make/shared_state.dart';
// import 'package:mineral_cli/src/commands/start_project.dart';
// import 'package:mineral_cli/src/console/console.dart';
// import 'package:mineral_cli/src/console/themes/default_theme.dart';
// import 'package:mineral_cli/src/mineral_command.dart';
//
import 'package:mineral_cli/mineral_cli.dart';
import 'package:mineral_cli/src/commands/create_project.dart';
import 'package:mineral_cli/src/commands/help.dart';

Future<void> main (List<String> arguments) async {
  final cli = MineralCli(DefaultTheme());
  final console = Console(theme: DefaultTheme());

  cli.register([
    CreateProject(console),
    Help(console, cli)
  ]);

  await cli.handle(arguments);
}
// Future<void> main (List<String> arguments) async {
//   stdin.lineMode = true;
//   final console = Console(theme: DefaultTheme());
//
//   final Map<String, MineralCommand> commands = {}
//     ..putIfAbsent('create', () => CreateProject(console))
//     ..putIfAbsent('start', () => StartProject(console))
//     ..putIfAbsent('make:command', () => MakeCommand(console))
//     ..putIfAbsent('make:event', () => MakeEvent(console))
//     ..putIfAbsent('make:state', () => MakeSharedState(console))
//     ..putIfAbsent('make:module', () => MakeModule(console));
//
//   commands.putIfAbsent('help', () => Help(console, commands.values.toList()));
//
//   final ArgParser parser = ArgParser();
//
//   parser.addCommand('create', ArgParser()
//     ..addOption('name'));
//
//   parser.addCommand('start', ArgParser());
//   parser.addCommand('make:command', ArgParser()
//     ..addOption('name'));
//
//   parser.addCommand('make:event', ArgParser()
//     ..addOption('name'));
//
//   parser.addCommand('make:state', ArgParser()
//     ..addOption('name'));
//
//   parser.addCommand('make:module', ArgParser()
//     ..addOption('name'));
//
//   parser.addCommand('help', ArgParser());
//   parser.addCommand('compile', ArgParser());
//
//   ArgResults results = parser.parse(arguments);
//
//   final command = commands[results.command?.name ?? 'help'];
//   if (command != null) {
//     if (command.arguments.isNotEmpty && results.arguments.length - 1 != command.arguments.length) {
//       console.error('Please provide ${command.arguments.map((e) => '<$e>').join(', ')} params.');
//       return;
//     }
//
//     final params = {};
//     for (int i = 0; i < command.arguments.length; i++) {
//       params.putIfAbsent(command.arguments[i], () => results.arguments[i + 1]);
//     }
//
//     return await command.handle(params);
//   }
// }