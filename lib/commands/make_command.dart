import 'dart:async';
import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mineral/api.dart';
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

final class MakeCommand with Tools implements CliCommandContract {
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

  AlternateScreen? _screen;

  @override
  Future<void> handle(List<String> arguments) async {
    _screen = AlternateScreen(title: 'Creating command…');
    _screen?.start();

    _filename = arguments.firstOrNull?.snakeCase ??
        await Input(
          answer: 'Enter the command filename',
          placeholder: 'foo_command',
          defaultValue: 'foo_command',
        ).handle();

    final className = _filename.pascalCase;
    commandClass.setClassName(className);

    _location = await Select<Directory>(
      answer: 'Where would you like to create the command ?',
      options: Directory('src').listSync(recursive: true).whereType<Directory>().toList(),
      onDisplay: (e) => e.path,
      placeholder: 'search…',
    ).handle();

    final commandType = await Select<CommandType>(
      answer: 'What type of command would you like to create ?',
      options: [CommandType.declaration, CommandType.definition],
      placeholder: 'search…',
    ).handle();

    return switch (commandType) {
      CommandType.declaration => _buildDeclaration(),
      CommandType.definition => _buildDefinition(),
    };
  }

  Future<void> _buildDeclaration() async {
    final title = await Input(
      answer: 'Enter the command name',
    ).handle();

    final description = await Input(
      answer: 'Enter the description',
    ).handle();

    _commandName = title.pascalCase;
    _commandDescription = description.pascalCase;

    _drawMenu();
  }

  Future<void> _drawMenu() async {
    final action = await Select<Action>(
      answer: 'Where would you like to create the event ?',
      options: [
        (action: ActionType.addGroup, label: 'Créer un groupe de commandes'),
        (action: ActionType.addSubCommand, label: 'Add subcommand'),
        (action: ActionType.build, label: 'Generate command'),
      ],
      onDisplay: (e) => e.label,
      placeholder: 'search…',
    ).handle();

    return switch (action.action) {
      ActionType.addGroup => _addGroup(),
      ActionType.addSubCommand => _addSubCommand(),
      ActionType.build => _buildDeclarationClass(),
    };
  }

  Future<void> _addGroup() async {
    final title = await Input(
      answer: 'Enter the group name',
    ).handle();

    final description = await Input(
      answer: 'Enter the group description',
    ).handle();

    _groups.add((label: title, description: description, commands: []));
    await _drawMenu();
  }

  Future<void> _addSubCommand() async {
    final name = await Input(
      answer: 'Enter the subcommand name',
    ).handle();

    final description = await Input(
      answer: 'Enter the subcommand description',
    ).handle();

    if (_groups.isNotEmpty) {
      final group = await Select<Group>(
        answer: 'Select the group (optional)',
        options: [(label: 'No group', description: 'No group', commands: []), ..._groups],
        onDisplay: (element) => element.label,
        placeholder: 'search a group…',
      ).handle();

      if (group.label != 'No group') {
        group.commands.add((label: name, description: description));
      } else {
        _subCommands.add((label: name, description: description));
      }
    }

    await _drawMenu();
  }

  Future<void> _buildDeclarationClass() async {
    _screen?.stop();
    hideInput();

    final delayed = Delayed();

    delayed.step('Build command class…');

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
    final sourceFile = await Select<File>(
      answer: 'Where would you like to create the command ?',
      options: Directory('src')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('yaml') || file.path.endsWith('yml'))
          .toList(),
      onDisplay: (e) => e.path,
      placeholder: 'search…',
    ).handle();

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

    _screen?.stop();
    hideInput();

    final delayed = Delayed();
    delayed.step('Creating file…');

    try {
      final file = File('${_location.path}/${_filename.snakeCase}.dart');
      await file.writeAsString(formatter.format(clazz));

      delayed.success('Command created successfully in ${file.path}');

      await Future.delayed(Duration(seconds: 1), () => exit(0));
    } catch (error) {
      delayed.error('An error occurred while creating the file: $error');
    } finally {
      showInput();
    }
  }
}
