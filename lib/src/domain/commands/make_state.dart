import 'dart:async';
import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/class_builder.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/parameter_struct.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/property_struct.dart';
import 'package:mineral_cli/src/infrastructure/contracts/cli_command_contract.dart';
import 'package:mineral_cli/src/infrastructure/entities/cli_command.dart';
import 'package:recase/recase.dart';

final class MakeState implements CliCommandContract {
  final _commander = Commander(level: Level.verbose);

  @override
  String get name => 'make:state';

  @override
  String get description => 'Create a new global state';

  @override
  Future<void> handle(List<MineralCommand> _, List<String> arguments) async {
    final formatter = DartFormatter(pageWidth: 80);

    final filename = arguments.firstOrNull?.snakeCase ??
        await _commander.ask<String>(
          'Enter the state name',
          validate: (validator) => validator.notEmpty(),
        );

    final type = await _commander.ask<String>(
      'Enter the state type',
      validate: (validator) => validator.notEmpty(),
    );

    final className = '${filename.pascalCase}State';

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

    final task = await _commander.task();
    final abstractStateClass =
        await task.step('Building abstract state class…', callback: () {
      return _buildAbstractClass(className, type);
    });

    final stateClass = await task.step('Building state class…', callback: () {
      return _buildClass(className, type);
    });

    try {
      final file = await task.step('Building state class…', callback: () async {
        final buffer = StringBuffer()
          ..writeln(abstractStateClass)
          ..writeln(stateClass);

        final file = File('${location.path}/${filename}_state.dart');
        await file.writeAsString(formatter.format(buffer.toString()));

        return file;
      });

      task.success('State created successfully in ${file.path}');
      _commander.warn('Don\'t forget to register your state in the client.');
    } catch (error) {
      task.error('An error occurred while creating the file: $error');
    }
  }

  String _buildClass(String className, String genericType) {
    return ClassBuilder()
        .setClassName(className)
        .addImplement(ParameterStruct(name: '${className}Contract'))
        .addProperty(PropertyStruct(
          name: 'state',
          returnType: ParameterStruct(name: genericType),
          value: switch (genericType) {
            String value when value == 'int' => 0,
            String value when value == 'String' => "''",
            String value when value == 'bool' => false,
            _ => UnimplementedError('Please specify the default state value'),
          },
          isOverride: true,
        ))
        .build();
  }

  String _buildAbstractClass(String className, String genericType) {
    return ClassBuilder()
        .setClassName('${className}Contract')
        .setAbstract(true)
        .setInterface(true)
        .addImplement(ParameterStruct(
            name: 'GlobalState<$genericType>',
            import: 'package:mineral/api.dart'))
        .build();
  }
}
