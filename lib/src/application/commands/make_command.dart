import 'dart:async';
import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:commander_ui/commander_ui.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mineral/utils.dart';
import 'package:mineral_cli/src/domain/contracts/cli_command_contract.dart';
import 'package:mineral_cli/src/domain/entities/cli_command.dart';
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

  final _emitter = DartEmitter();
  final _formatter = DartFormatter(
      pageWidth: 150, languageVersion: DartFormatter.latestLanguageVersion);

  @override
  String get name => 'make:command';

  @override
  String get description => 'Create a new command class';

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
            defaultValue: 'foo_command',
            validate: (validator) => validator.notEmpty()))!;

    final libDirectoryHasFolders = Directory('lib')
        .listSync(recursive: true)
        .whereType<Directory>()
        .isNotEmpty;

    _location = !libDirectoryHasFolders
        ? Directory('lib')
        : await _commander.select<Directory>(
            'Where would you like to create the command ?',
            options: Directory('lib')
                .listSync(recursive: true)
                .whereType<Directory>()
                .toList(),
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
        options: [
          (label: 'No group', description: 'No group', commands: []),
          ..._groups
        ],
        onDisplay: (element) => element.label,
        placeholder: 'search a group…',
      );

      if (group.label != 'No group') {
        group.commands.add((label: name!, description: description!));
      } else {
        _subCommands.add((label: name!, description: description!));
      }
    } else {
      _subCommands.add((label: name!, description: description!));
    }

    await _drawMenu();
  }

  Future<void> _buildDeclarationClass() async {
    _screenManager.leave();

    final handleFunction = StringBuffer()
      ..write('return CommandDeclarationBuilder()')
      ..write('''..setName('$_commandName')''')
      ..write('''..setDescription('$_commandDescription')''')
      ..write(_subCommands.isEmpty ? '..setHandle(handle);' : '');

    for (final element in _subCommands.indexed) {
      final (index, subCommand) = element;

      handleFunction
        ..write('..addSubCommand((command) {')
        ..write('command')
        ..write('''..setName('${subCommand.label}')''')
        ..write('''..setDescription('${subCommand.description}')''')
        ..write('''..setHandle(${subCommand.label.camelCase});''')
        ..write('})');

      if (index == _subCommands.length - 1 && _groups.isEmpty) {
        handleFunction.write(';');
      }
    }

    for (final group in _groups) {
      final index = _groups.indexOf(group);

      handleFunction.write('..createGroup((group) {');
      handleFunction.write('group');

      for (final subCommand in group.commands) {
        final index = group.commands.indexOf(subCommand);

        handleFunction.write('..addSubCommand((command) {');
        handleFunction.write('command');
        handleFunction.write('''..setName('${subCommand.label}')''');
        handleFunction
            .write('''..setDescription('${subCommand.description}')''');
        handleFunction.write('''..setHandle(${subCommand.label.camelCase});''');
        handleFunction.write('})');

        if (index == group.commands.length - 1) {
          handleFunction.write(';');
        }
      }

      handleFunction.write('})');
      if (index == _groups.length - 1) {
        handleFunction.write(';');
      }
    }

    final List<Method> methods = [
      // Create handle function
      if (_subCommands.isEmpty && _groups.isEmpty)
        Method((method) => method
          ..name = 'handle'
          ..modifier = MethodModifier.async
          ..returns = refer('Future<void>')
          ..body = Code('print(\'Hello, World!\');\n')),
      // Create subcommands
      for (final subCommand in _subCommands)
        Method((method) => method
          ..name = subCommand.label.camelCase
          ..modifier = MethodModifier.async
          ..requiredParameters.add(Parameter((parameter) => parameter
            ..name = 'ctx'
            ..type = refer('CommandContext', 'package:mineral/api.dart')))
          ..returns = refer('Future<void>')
          ..body = Code('print(\'Hello, World!\');\n')),
      // Compute subcommands from groups
      for (final group in _groups)
        for (final subCommand in group.commands)
          Method((method) => method
            ..name = subCommand.label.camelCase
            ..modifier = MethodModifier.async
            ..requiredParameters.add(Parameter((parameter) => parameter
              ..name = 'ctx'
              ..type = refer('CommandContext', 'package:mineral/api.dart')))
            ..returns = refer('Future<void>')
            ..body = Code('print(\'Hello, World!\');\n')),
      // Build function
      Method((method) => method
        ..name = 'build'
        ..annotations.add(refer('override'))
        ..returns =
            refer('CommandDeclarationBuilder', 'package:mineral/api.dart')
        ..body = Code(handleFunction.toString())),
    ];

    final library = Library((library) => library
      ..body.addAll([
        Code('import \'package:mineral/api.dart\';'),
        Class((clazz) => clazz
          ..name = _commandName
          ..implements
              .add(refer('CommandDeclaration', 'package:mineral/api.dart'))
          ..methods.addAll(methods))
      ]));

    await _createFileInDisk(library);
  }

  Future<void> _buildDefinition() async {
    final sourceFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
            (file) => file.path.endsWith('yaml') || file.path.endsWith('yml'))
        .where((file) => !file.path.endsWith('pubspec.yaml'))
        .where((file) => !file.path.endsWith('analysis_options.yaml'))
        .toList();

    if (sourceFiles.isEmpty) {
      _commander.error('No source file found in the lib directory');
      return;
    }

    final sourceFile = await _commander.select<File>(
      'What is the source file for your command ?',
      options: sourceFiles,
      onDisplay: (e) => e.path,
      placeholder: 'search…',
    );

    final handleFunction = StringBuffer()
      ..write('return CommandDefinitionBuilder()')
      ..write('''..using(File('${sourceFile.path}'))''');

    final content = await sourceFile.readAsYaml();
    if (content['commands'] case YamlMap commands) {
      for (final command in commands.entries) {
        handleFunction.write(
            '''..setHandler('${command.key}', ${command.key.toString().camelCase})''');
      }
    }

    handleFunction.write(';');

    final List<Method> methods = [
      // Create subcommands
      if (content['commands'] case YamlMap commands)
        for (final command in commands.entries)
          Method((method) => method
            ..name = command.key.toString().camelCase
            ..modifier = MethodModifier.async
            ..requiredParameters.add(Parameter((parameter) => parameter
              ..name = 'ctx'
              ..type = refer('CommandContext', 'package:mineral/api.dart')))
            ..returns = refer('Future<void>')
            ..body = Code('print(\'Hello, World!\');\n')),
      // Build function
      Method((method) => method
        ..name = 'build'
        ..annotations.add(refer('override'))
        ..returns =
            refer('CommandDefinitionBuilder', 'package:mineral/api.dart')
        ..body = Code(handleFunction.toString())),
    ];

    final library = Library((library) => library
      ..body.addAll([
        Code('import \'dart:io\';'),
        Code('import \'package:mineral/api.dart\';'),
        Class((clazz) => clazz
          ..name = _filename.pascalCase
          ..implements
              .add(refer('CommandDefinition', 'package:mineral/api.dart'))
          ..methods.addAll(methods))
      ]));

    await _createFileInDisk(library);
  }

  Future<void> _createFileInDisk(Library library) async {
    final formatter = DartFormatter(pageWidth: 150, languageVersion: DartFormatter.latestLanguageVersion);

    _screenManager.leave();
    final task = await _commander.task();
    task.step('Creating file…');

    try {
      final file = await task.step('Creating file…', callback: () async {
        final file = File('${_location.path}/${_filename.snakeCase}.dart');
        final content = formatter.format(library.accept(_emitter).toString());

        return file.writeAsString(content);
      });

      task.success('Command created successfully in ${file.path}');

      final example = Library((library) => library
        ..body.addAll([
          Code('// Please register your command in the client\n'),
          Method((method) => method
            ..name = 'main'
            ..returns = refer('void')
            ..body = Code('client.register(${_filename.pascalCase}.new);'))
        ]));

      stdout
        ..writeln()
        ..writeln(_formatter
            .format(example.accept(_emitter).toString())
            .style(Style.foreground(Color.brightBlack)));
    } catch (error) {
      task.error('An error occurred while creating the file: $error');
    }
  }
}
