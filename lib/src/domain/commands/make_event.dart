import 'dart:async';
import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mineral/events.dart' as events;
import 'package:mineral_cli/src/infrastructure/builder/class/class_builder.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/method_struct.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/parameter_struct.dart';
import 'package:mineral_cli/src/infrastructure/contracts/cli_command_contract.dart';
import 'package:mineral_cli/src/infrastructure/entities/cli_command.dart';
import 'package:recase/recase.dart';

final class MakeEvent implements CliCommandContract {
  final _commander = Commander(level: Level.verbose);

  @override
  String get name => 'make:event';

  @override
  String get description => 'Create a new event class';

  @override
  Future<void> handle(List<MineralCommand> _, List<String> arguments) async {
    final formatter = DartFormatter(pageWidth: 150);

    final event = await _commander.select<events.Event>(
      'Choose your event to make it !',
      options: events.Event.values,
      onDisplay: (e) => e.value.toString(),
      placeholder: 'search…',
    );

    final filename = arguments.firstOrNull?.snakeCase ??
        await _commander.ask<String>(
          'Enter the event name',
          defaultValue: event.value.toString().replaceAll('Event', '').snakeCase,
          validate: (validator) => validator.notEmpty(),
        );

    final className = filename.pascalCase;

    final location = await _commander.select<Directory>(
      'Where would you like to create the event ?',
      options: Directory('src').listSync(recursive: true).whereType<Directory>().toList(),
      onDisplay: (e) => e.path,
      placeholder: 'search…',
    );

    final task = await _commander.task();
    final eventClass = await task.step('Building event class…', callback: () {
      return _buildClass(className, event);
    });

    try {
      final file = await task.step('Building event class…', callback: () async {
        final file = File('${location.path}/$filename.dart');
        await file.writeAsString(formatter.format(eventClass));

        return file;
      });

      task.success('Event created successfully in ${file.path}');
    } catch (error) {
      task.error('An error occurred while creating the file: $error');
    }
  }

  String _buildClass(String className, events.Event event) {
    return ClassBuilder()
        .setClassName(className)
        .setExtends(
            ParameterStruct(name: event.value.toString(), import: 'package:mineral/events.dart'))
        .addMethod(MethodStruct(
            name: 'handle',
            returnType: ParameterStruct(name: 'Future<void>', import: null),
            isOverride: true,
            isAsync: true,
            body: StringBuffer()..write('// Your code here'),
            parameters: event.parameters
                .map(
                    (element) => ParameterStruct(name: element, import: 'package:mineral/api.dart'))
                .toList()))
        .build();
  }
}
