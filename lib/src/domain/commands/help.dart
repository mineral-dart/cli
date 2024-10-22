import 'package:mineral_cli/src/infrastructure/contracts/cli_command_contract.dart';
import 'package:mineral_cli/src/infrastructure/entities/cli_command.dart';
import 'package:commander_ui/commander_ui.dart';
import 'package:mansion/mansion.dart';

final class Help implements CliCommandContract {
  @override
  String get name => 'help';

  @override
  String get description => 'Display the help message';

  @override
  Future<void> handle(
      List<MineralCommand> commands, List<String> arguments) async {
    final Map<String, List<MineralCommand>> commandBucket = {};

    for (final command in commands) {
      final String key = command.name.contains(':')
          ? '${command.name.split(':').first} commands'
          : 'Core commands';

      if (commandBucket.containsKey(key)) {
        commandBucket[key]?.add(command);
      } else {
        commandBucket.putIfAbsent(key, () => [command]);
      }
    }

    final stringBuffer = StringBuffer();

    stringBuffer.writeAnsiAll([
      Print('Welcome to Mineral CLI !'),
      AsciiControl.lineFeed,
      Print('Work seamlessly with Mineral from the command line.'),
      AsciiControl.lineFeed,
      AsciiControl.lineFeed,
    ]);

    stringBuffer.writeAnsiAll([
      SetStyles(Style.foreground(Color.white), Style.bold),
      Print('Usage:'.toUpperCase()),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    stringBuffer.writeAnsiAll([
      Print('  mineral <command> <subcommand> [flags]'),
      AsciiControl.lineFeed,
      AsciiControl.lineFeed,
    ]);

    int nameLength = 0;
    for (final element in commandBucket.entries) {
      for (final command in element.value) {
        if (command.name.length > nameLength) {
          nameLength = command.name.length;
        }
      }
    }

    for (final element in commandBucket.entries) {
      stringBuffer.writeAnsiAll([
        SetStyles(Style.foreground(Color.white), Style.bold),
        Print(element.key.toUpperCase()),
        SetStyles.reset,
        AsciiControl.lineFeed,
      ]);

      for (final command in element.value) {
        stringBuffer.writeAnsiAll([
          Print('  ${command.name}'),
          Print(' ' * (nameLength - command.name.length + 4)),
          Print(command.description),
          AsciiControl.lineFeed,
        ]);
      }

      stringBuffer.writeAnsiAll([
        AsciiControl.lineFeed,
      ]);
    }

    print(stringBuffer.toString());
  }
}
