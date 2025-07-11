import 'package:mineral_cli/src/application/commands/create.dart';
import 'package:mineral_cli/src/application/commands/help.dart';
import 'package:mineral_cli/src/application/commands/make_command.dart';
import 'package:mineral_cli/src/application/commands/make_event.dart';
import 'package:mineral_cli/src/application/commands/make_provider.dart';
import 'package:mineral_cli/src/application/commands/make_state.dart';
import 'package:mineral_cli/src/domain/cli.dart';

void main(List<String> arguments) async {
  final cli = Cli()
    ..registerCommand(CreateProject())
    ..registerCommand(MakeEvent())
    ..registerCommand(MakeCommand())
    ..registerCommand(MakeProvider())
    ..registerCommand(MakeState())
    ..registerCommand(Help());

  await cli.handle(arguments);
}
