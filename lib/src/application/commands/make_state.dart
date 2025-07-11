import 'dart:async';
import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:commander_ui/commander_ui.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mineral_cli/src/domain/contracts/cli_command_contract.dart';
import 'package:mineral_cli/src/domain/entities/cli_command.dart';
import 'package:recase/recase.dart';

final class MakeState implements CliCommandContract {
  final _commander = Commander(level: Level.verbose);
  final _emitter = DartEmitter();
  final _formatter = DartFormatter(
      pageWidth: 150, languageVersion: DartFormatter.latestLanguageVersion);

  @override
  String get name => 'make:state';

  @override
  String get description => 'Create a new global state';

  @override
  Future<void> handle(List<MineralCommand> _, List<String> arguments) async {
    final screenManager = _commander.screen(title: 'Creating command…');
    screenManager.enter();

    final filename = arguments.firstOrNull?.snakeCase ??
        await _commander.ask<String>(
          'Enter the state name',
          validate: (validator) => validator.notEmpty(),
        );

    final type = await _commander.ask<String>(
      'Enter the state type',
      validate: (validator) => validator.notEmpty(),
    );

    final libDirectoryHasFolders = Directory('lib')
        .listSync(recursive: true)
        .whereType<Directory>()
        .isNotEmpty;

    final location = !libDirectoryHasFolders
        ? Directory('lib')
        : await _commander.select<Directory>(
            'Where would you like to create the state ?',
            options: Directory('lib')
                .listSync(recursive: true)
                .whereType<Directory>()
                .toList(),
            onDisplay: (e) => e.path,
            placeholder: 'search…',
          );

    screenManager.leave();

    final task = await _commander.task();
    final abstractClazz =
        await task.step('Building abstract state class…', callback: () {
      return Class((clazz) => clazz
        ..name = '${filename.pascalCase}StateContract'
        ..abstract = true
        ..modifier = ClassModifier.interface
        ..implements
            .add(refer('GlobalState<$type>', 'package:mineral/api.dart'))
        ..constructors.add(Constructor((constructor) => constructor
          ..requiredParameters.addAll([
            Parameter((parameter) => parameter
              ..name = 'client'
              ..type = refer('Client', 'package:mineral/api.dart'))
          ]))));
    });

    final clazz = await task.step('Building state class…', callback: () {
      return Class((clazz) => clazz
        ..name = filename.pascalCase
        ..implements.add(refer(
            '${filename.pascalCase}StateContract', 'package:mineral/api.dart'))
        ..fields.add(Field((field) => field
          ..name = 'state'
          ..type = refer(type, 'package:mineral/api.dart')
          ..annotations.add(refer('override')))));
    });

    final library = Library((library) => library
      ..body.addAll([
        Code('import \'package:mineral/api.dart\';'),
        abstractClazz,
        clazz,
      ]));

    try {
      final file = await task.step('Building state class…', callback: () async {
        final file = File('${location.path}/${filename}_state.dart');
        final content = _formatter.format(library.accept(_emitter).toString());

        return file.writeAsString(content);
      });

      task.success('State created successfully in ${file.path}');

      final example = Library((library) => library
        ..body.addAll([
          Code('// Please register your state in the client\n'),
          Method((method) => method
            ..name = 'main'
            ..returns = refer('void')
            ..body = Code(
                'client.register<${filename.pascalCase}StateContract>(${filename.pascalCase}State.new);'))
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
