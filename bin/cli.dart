import 'package:cli/src/infrastructure/cli.dart';
import 'package:cli/src/domain/commands/create.dart';
import 'package:cli/src/domain/commands/help.dart';
import 'package:cli/src/domain/commands/make_command.dart';
import 'package:cli/src/domain/commands/make_event.dart';

void main(List<String> arguments) async {
  final cli = Cli()
    ..registerCommand(CreateProject())
    ..registerCommand(MakeEvent())
    ..registerCommand(MakeCommand())
    ..registerCommand(Help());

  await cli.handle(arguments);
}
