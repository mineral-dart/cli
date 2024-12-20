import 'package:mineral_cli/src/domain/commands/make_provider.dart';
import 'package:mineral_cli/src/infrastructure/cli.dart';
import 'package:mineral_cli/src/domain/commands/create.dart';
import 'package:mineral_cli/src/domain/commands/help.dart';
import 'package:mineral_cli/src/domain/commands/make_command.dart';
import 'package:mineral_cli/src/domain/commands/make_event.dart';

void main(List<String> arguments) async {
  final cli = Cli()
    ..registerCommand(CreateProject())
    ..registerCommand(MakeEvent())
    ..registerCommand(MakeCommand())
    ..registerCommand(MakeProvider())
    ..registerCommand(Help());

  await cli.handle(arguments);
}
