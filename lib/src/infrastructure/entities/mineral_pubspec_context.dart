import 'package:mineral_cli/src/infrastructure/entities/cli_command.dart';
import 'package:yaml/yaml.dart';

final class MineralPubSpecContext {
  final List<MineralCommand> commands;

  MineralPubSpecContext({
    required this.commands,
  });

  factory MineralPubSpecContext.fromJson(String root, YamlMap json) {
    final YamlList commands = json['commands'] ?? YamlList();

    final List<MineralCommand> commandsList = commands.fold([], (acc, element) {
      final command = MineralCommand.fromJson(root, element);
      return [...acc, command];
    });

    return MineralPubSpecContext(
      commands: commandsList,
    );
  }
}
