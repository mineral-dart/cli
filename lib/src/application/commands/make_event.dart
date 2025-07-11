import 'dart:async';
import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:commander_ui/commander_ui.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mineral/events.dart' as events;
import 'package:mineral_cli/src/domain/contracts/cli_command_contract.dart';
import 'package:mineral_cli/src/domain/entities/cli_command.dart';
import 'package:recase/recase.dart';

final class MakeEvent implements CliCommandContract {
  final _commander = Commander();
  final _emitter = DartEmitter();
  final _formatter = DartFormatter(
      pageWidth: 150, languageVersion: DartFormatter.latestLanguageVersion);

  @override
  String get name => 'make:event';

  @override
  String get description => 'Create a new event class';

  @override
  Future<void> handle(List<MineralCommand> _, List<String> arguments) async {
    final event = await _commander.select<events.Event>(
      'Choose your event to make it !',
      options: events.Event.values,
      onDisplay: (e) => e.value.toString(),
      placeholder: 'search…',
    );

    final filename = arguments.firstOrNull?.snakeCase ??
        await _commander.ask<String>(
          'Enter the event name',
          defaultValue:
              event.value.toString().replaceAll('Event', '').snakeCase,
          validate: (validator) => validator.notEmpty(),
        );

    final className = filename.pascalCase;

    final libDirectoryHasFolders = Directory('lib')
        .listSync(recursive: true)
        .whereType<Directory>()
        .isNotEmpty;

    final location = !libDirectoryHasFolders
        ? Directory('lib')
        : await _commander.select<Directory>(
            'Where would you like to create the event ?',
            options: Directory('lib')
                .listSync(recursive: true)
                .whereType<Directory>()
                .toList(),
            onDisplay: (e) => e.path,
            placeholder: 'search…',
          );

    final task = await _commander.task();

    final clazz = await task.step('Building event class…', callback: () {
      return Library((librairy) => librairy
        ..body.addAll([
          Code('import \'package:mineral/api.dart\';'),
          Code('import \'package:mineral/events.dart\';'),
          Class((clazz) => clazz
            ..name = className.pascalCase
            ..extend =
                refer(event.value.toString(), 'package:mineral/events.dart')
            ..methods.add(Method((method) => method
              ..name = 'handle'
              ..modifier = MethodModifier.async
              ..annotations.add(refer('override'))
              ..body = Code('// Your code here\nprint(\'Hello, World!\');')
              ..returns = refer('Future<void>')
              ..requiredParameters.addAll(event.parameters.map((element) {
                final [type, name] = element;
                return Parameter((parameter) => parameter
                  ..name = name
                  ..type = refer(type, 'package:mineral/api.dart'));
              })))))
        ]));
    });

    try {
      final file = await task.step('Building event class…', callback: () async {
        final file = File('${location.path}/$filename.dart');
        final content = _formatter.format(clazz.accept(_emitter).toString());

        return file.writeAsString(content);
      });

      task.success('Event created successfully in ${file.path}');
    } catch (error) {
      task.error('An error occurred while creating the file: $error');
    }
  }
}
