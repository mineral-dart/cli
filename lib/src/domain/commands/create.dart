import 'dart:async';

import 'package:mineral_cli/src/infrastructure/contracts/cli_command_contract.dart';
import 'package:mineral_cli/src/infrastructure/entities/cli_command.dart';
import 'package:mineral_cli/src/domain/commands/project_setups/basic_preset.dart';
import 'package:mineral_cli/src/domain/commands/project_setups/preset.dart';
import 'package:mineral_cli/src/domain/commands/project_setups/slim_preset.dart';
import 'package:commander_ui/commander_ui.dart';
import 'package:mineral/services.dart';
import 'package:recase/recase.dart';

final class CreateProject implements CliCommandContract {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new project';

  @override
  Future<void> handle(List<MineralCommand> _, List<String> arguments) async {
    final commander = Commander(level: Level.verbose);

    final projectName = arguments.firstOrNull?.snakeCase ??
        await commander.ask(
          'Enter the project name :',
          defaultValue: 'mineral_project',
          validate: (value) {
            return switch (value) {
              String(:final isEmpty) when isEmpty =>
                'The project name cannot be empty',
              _ => null,
            };
          },
        );

    final token = await commander.ask(
      'Enter your bot token :',
      hidden: true,
    );

    final useHmr = await commander.swap(
      'Would you like to enable HMR ?',
      defaultValue: true,
    );

    final logLevel = await commander.select<LogLevel>(
      'Choose your log level',
      options: LogLevel.values,
      onDisplay: (preset) => preset.name.toLowerCase(),
      placeholder: 'search preset…',
    );

    final List<PresetContract> presets = [
      SlimPreset(projectName!, useHmr, token!, logLevel.name.toLowerCase()),
      BasicPreset(projectName, useHmr, token, logLevel.name.toLowerCase()),
    ];

    final preset = await commander.select<PresetContract>(
      'Choose your project preset',
      options: presets,
      onDisplay: (preset) => preset.name,
      placeholder: 'search preset…',
    );

    await preset.handle(arguments);
  }
}
