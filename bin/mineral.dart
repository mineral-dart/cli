import 'package:mineral_cli/mineral_cli.dart';
import 'package:mineral_cli/src/commands/create_project.dart';
import 'package:mineral_cli/src/commands/help.dart';
import 'package:mineral_console/mineral_console.dart';

Future<void> main (List<String> arguments) async {
  final cli = MineralCli(DefaultTheme());
  final console = Console(theme: DefaultTheme());

  cli.register([
    CreateProject(console),
    Help(console, cli)
  ]);

  await cli.handle(arguments);
}