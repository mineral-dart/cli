import 'dart:async';

import 'package:cli/commands/project_setups/preset.dart';
import 'package:cli/commands/project_setups/slim_preset.dart';
import 'package:commander_ui/commander_ui.dart';
import 'package:mineral/api.dart';
import 'package:mineral/services.dart';
import 'package:recase/recase.dart';

final class CreateProject with Tools implements CliCommandContract {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new project';

  @override
  Future<void> handle(List<String> arguments) async {
    final projectName = arguments.firstOrNull?.snakeCase ??
        await Input(
          answer: 'Enter the project name',
          defaultValue: 'mineral_project',
        ).handle();

    final token = await Input(
      answer: 'Enter your bot token',
      secure: true,
    ).handle();

    final useHmr = await Switch(
      answer: 'Would you like to enable HMR ?',
      defaultValue: true,
    ).handle();

    final logLevel = await Select<LogLevel>(
      answer: 'Choose your project preset',
      options: LogLevel.values,
      onDisplay: (preset) => preset.name.toLowerCase(),
      placeholder: 'search preset…',
    ).handle();

    final List<PresetContract> presets = [
      SlimPreset(projectName, useHmr, token, logLevel.name.toLowerCase()),
    ];

    final preset = await Select<PresetContract>(
      answer: 'Choose your project preset',
      options: presets,
      onDisplay: (preset) => preset.name,
      placeholder: 'search preset…',
    ).handle();

    await preset.handle(arguments);
  }
}