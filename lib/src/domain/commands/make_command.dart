import 'dart:async';
import 'dart:io';

import 'package:mineral_cli/src/infrastructure/builder/class/class_builder.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/method_struct.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/parameter_struct.dart';
import 'package:mineral_cli/src/infrastructure/contracts/cli_command_contract.dart';
import 'package:mineral_cli/src/infrastructure/entities/cli_command.dart';
import 'package:commander_ui/commander_ui.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mineral/utils.dart';
import 'package:recase/recase.dart';
import 'package:yaml/yaml.dart';

enum CommandType {
  declaration('Declaration'),
  definition('Definition');

  final String label;

  const CommandType(this.label);
}

enum ActionType {
  addGroup,
  addSubCommand,
  build,
}

typedef Action = ({ActionType action, String label});
typedef SubCommand = ({String label, String description});
typedef Group = ({String label, String description, List<SubCommand> commands});

final class MakeCommand implements CliCommandContract {
  final _commander = Commander(level: Level.verbose);
  late ScreenManager _screenManager;

  @override
  String get name => 'make:command';

  @override
  String get description => 'Create a new command class';

  final commandClass = ClassBuilder();

  late String _filename;
  late Directory _location;
  String? _commandName;
  String? _commandDescription;

  final List<Group> _groups = [];
  final List<SubCommand> _subCommands = [];

  @override
  Future<void> handle(List<MineralCommand> _, List<String> arguments) async {
    _screenManager = _commander.screen(title: 'Creating command…');
    _screenManager.enter();

    _filename = (arguments.firstOrNull?.snakeCase ??
        await _commander.ask('Enter the command filename',
            defaultValue: 'foo_command', validate: (validator) => validator.notEmpty()))!;

    final className = _filename.pascalCase;
    commandClass.setClassName(className);

    _location = await _commander.select<Directory>(
      'Where would you like to create the command ?',
      options: Directory('src').listSync(recursive: true).whereType<Directory>().toList(),
      onDisplay: (e) => e.path,
      placeholder: 'search…',
    );

    final commandType = await _commander.select<CommandType>(
      'What type of command would you like to create ?',
      options: [CommandType.declaration, CommandType.definition],
      placeholder: 'search…',
    );

    return switch (commandType) {
      CommandType.declaration => _buildDeclaration(),
      CommandType.definition => _buildDefinition(),
    };
  }

  Future<void> _buildDeclaration() async {
    final title = await _commander.ask<String>('Enter the command name',
        validate: (validator) => validator.notEmpty());

    final description = await _commander.ask<String>(
      'Enter the description',
      validate: (validator) => validator.notEmpty(),
    );

    _commandName = title.pascalCase;
    _commandDescription = description.pascalCase;

    _drawMenu();
  }

  Future<void> _drawMenu() async {
    final action = await _commander.select<Action>(
      'What would you like to do ?',
      options: [
        (action: ActionType.addGroup, label: 'Créer un groupe de commandes'),
        (action: ActionType.addSubCommand, label: 'Add subcommand'),
        (action: ActionType.build, label: 'Generate command'),
      ],
      onDisplay: (e) => e.label,
      placeholder: 'search…',
    );

    return switch (action.action) {
      ActionType.addGroup => _addGroup(),
      ActionType.addSubCommand => _addSubCommand(),
      ActionType.build => _buildDeclarationClass(),
    };
  }

  Future<void> _addGroup() async {
    final title = await _commander.ask(
      'Enter the group name',
      validate: (validator) => validator.notEmpty(),
    );

    stdout.writeln();

    final description = await _commander.ask(
      'Enter the group description',
      validate: (validator) => validator.notEmpty(),
    );

    _groups.add((label: title!, description: description!, commands: []));
    await _drawMenu();
  }

  Future<void> _addSubCommand() async {
    final name = await _commander.ask(
      'Enter the subcommand name',
      validate: (validator) => validator.notEmpty(),
    );

    final description = await _commander.ask(
      'Enter the subcommand description',
      validate: (validator) => validator.notEmpty(),
    );

    if (_groups.isNotEmpty) {
      final group = await _commander.select<Group>(
        'Select the group (optional)',
        options: [(label: 'No group', description: 'No group', commands: []), ..._groups],
        onDisplay: (element) => element.label,
        placeholder: 'search a group…',
      );

      if (group.label != 'No group') {
        group.commands.add((label: name!, description: description!));
      } else {
        _subCommands.add((label: name!, description: description!));
      }
    }

    await _drawMenu();
  }

  Future<void> _buildDeclarationClass() async {
    _screenManager.leave();

    final body = StringBuffer()
      ..write('return CommandDeclarationBuilder()')
      ..write('''..setName('$_commandName')''')
      ..write('''..setDescription('$_commandDescription')''')
      ..write(_subCommands.isEmpty ? '..setHandler(handle);' : '');

    for (final subCommand in _subCommands) {
      final index = _subCommands.indexOf(subCommand);

      commandClass.addMethod(MethodStruct(
        name: subCommand.label.camelCase,
        returnType: ParameterStruct(name: 'Future<void>'),
        isAsync: true,
        body: StringBuffer()..write('''print('Hello, World!');'''),
        parameters: [
          ParameterStruct(name: 'ctx', import: 'package:mineral/api.dart'),
        ],
      ));

      body
        ..write('..addSubCommand((command) {')
        ..write('command')
        ..write('''..setName('${subCommand.label}')''')
        ..write('''..setDescription('${subCommand.description}')''')
        ..write('''..setHandle(${subCommand.label.camelCase});''')
        ..write('})');

      if (index == _subCommands.length - 1 && _groups.isEmpty) {
        body.write(';');
      }
    }

    if (_subCommands.isEmpty && _groups.isEmpty) {
      commandClass.addMethod(MethodStruct(
        name: 'handle',
        returnType: ParameterStruct(name: 'Future<void>'),
        isAsync: true,
        body: StringBuffer('''print('Hello, World!');'''),
        parameters: [
          ParameterStruct(name: 'CommandContext', import: 'package:mineral/api.dart'),
        ],
      ));
    }

    for (final group in _groups) {
      final index = _groups.indexOf(group);

      body.write('..createGroup((group) {');
      body.write('group');

      for (final subCommand in group.commands) {
        final index = group.commands.indexOf(subCommand);

        commandClass.addMethod(MethodStruct(
          name: subCommand.label.camelCase,
          returnType: ParameterStruct(name: 'Future<void>'),
          isAsync: true,
          body: StringBuffer('''print('Hello, World!');'''),
          parameters: [
            ParameterStruct(name: 'ctx', import: 'package:mineral/api.dart'),
          ],
        ));

        body.write('..addSubCommand((command) {');
        body.write('command');
        body.write('''..setName('${subCommand.label}')''');
        body.write('''..setDescription('${subCommand.description}')''');
        body.write('''..setHandle(${subCommand.label.camelCase});''');
        body.write('})');

        if (index == group.commands.length - 1) {
          body.write(';');
        }
      }

      body.write('})');
      if (index == _groups.length - 1) {
        body.write(';');
      }
    }

    commandClass
        .addImplement(
            ParameterStruct(name: 'CommandDeclaration', import: 'package:mineral/api.dart'))
        .addMethod(MethodStruct(
          name: 'build',
          returnType: ParameterStruct(
              name: 'CommandDeclarationBuilder', import: 'package:mineral/api.dart'),
          body: body,
          isOverride: true,
        ));

    await _createFileInDisk(commandClass.build());
  }

  Future<void> _buildDefinition() async {
    final sourceFile = await _commander.select<File>(
      'Where would you like to create the command ?',
      options: Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('yaml') || file.path.endsWith('yml'))
          .where((file) => !file.path.endsWith('pubspec.yaml'))
          .where((file) => !file.path.endsWith('analysis_options.yaml'))
          .toList(),
      onDisplay: (e) => e.path,
      placeholder: 'search…',
    );

    commandClass.imports.add('dart:io');
    commandClass.addImplement(
        ParameterStruct(name: 'CommandDefinition', import: 'package:mineral/api.dart'));

    final body = StringBuffer()
      ..write('return CommandDefinitionBuilder()')
      ..write('''..using(File('${sourceFile.path}'))''');

    final content = await sourceFile.readAsYaml();
    if (content['commands'] case YamlMap commands) {
      for (final command in commands.entries) {
        final name = command.key as String;

        commandClass.addMethod(MethodStruct(
          name: name.camelCase,
          returnType: ParameterStruct(name: 'Future<void>'),
          isAsync: true,
          body: StringBuffer('''print('Hello, World!');'''),
          parameters: [
            ParameterStruct(name: 'ctx', import: 'package:mineral/api.dart'),
          ],
        ));

        body.write('''..setHandler('${name.camelCase}', ${name.camelCase})''');
      }

      body.write(';');

      commandClass.addMethod(MethodStruct(
          name: 'build',
          returnType: ParameterStruct(name: 'CommandDefinitionBuilder'),
          isOverride: true,
          body: body));
    }

    await _createFileInDisk(commandClass.build());
  }

  Future<void> _createFileInDisk(String clazz) async {
    final formatter = DartFormatter(pageWidth: 150);

    _screenManager.leave();
    final task = await _commander.task();
    task.step('Creating file…');

    try {
      final file = await task.step('Creating file…', callback: () async {
        final file = File('${_location.path}/${_filename.snakeCase}.dart');
        await file.writeAsString(formatter.format(clazz));

        return file;
      });

      task.success('Command created successfully in ${file.path}');
    } catch (error) {
      task.error('An error occurred while creating the file: $error');
    }
  }
}
