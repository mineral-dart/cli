import 'package:cli/commands/make_command.dart';
import 'package:cli/commands/make_event.dart';
import 'package:mineral/api.dart';

void main(List<String> arguments) async {
  final cli = Cli()
    ..registerCommand(MakeEvent())
    ..registerCommand(MakeCommand());

  await cli.handle(arguments);
}
