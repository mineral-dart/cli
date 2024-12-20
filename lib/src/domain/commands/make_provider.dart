import 'dart:async';
import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/class_builder.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/method_struct.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/parameter_struct.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/property_struct.dart';
import 'package:mineral_cli/src/infrastructure/contracts/cli_command_contract.dart';
import 'package:mineral_cli/src/infrastructure/entities/cli_command.dart';
import 'package:recase/recase.dart';

final class MakeProvider implements CliCommandContract {
  final _commander = Commander(level: Level.verbose);

  @override
  String get name => 'make:provider';

  @override
  String get description => 'Create a new provider entrypoint';

  @override
  Future<void> handle(List<MineralCommand> _, List<String> arguments) async {
    final formatter = DartFormatter(pageWidth: 80);

    final filename = arguments.firstOrNull?.snakeCase ??
        await _commander.ask<String>(
          'Enter the provider name',
          validate: (validator) => validator.notEmpty(),
        );

    final className = '${filename.pascalCase}Provider';

    final libDirectoryHasFolders =
        Directory('lib').listSync(recursive: true).whereType<Directory>().isNotEmpty;

    final location = !libDirectoryHasFolders
        ? Directory('lib')
        : await _commander.select<Directory>(
            'Where would you like to create the provider ?',
            options: Directory('lib').listSync(recursive: true).whereType<Directory>().toList(),
            onDisplay: (e) => e.path,
            placeholder: 'search…',
          );

    final task = await _commander.task();
    final eventClass = await task.step('Building event class…', callback: () {
      return _buildClass(className);
    });

    try {
      final file = await task.step('Building provider class…', callback: () async {
        final file = File('${location.path}/$filename.dart');
        await file.writeAsString(formatter.format(eventClass));

        return file;
      });

      task.success('Provider created successfully in ${file.path}');
      _commander.warn('Don\'t forget to register your provider in the client.');
    } catch (error) {
      task.error('An error occurred while creating the file: $error');
    }
  }

  String _buildClass(String className) {
    final constructor = PropertyStruct(
      name: '_client',
      returnType: ParameterStruct(
        name: 'Client',
        import: 'package:mineral/api.dart',
      ),
      isFinal: true,
      isOverride: true,
    );

    return ClassBuilder()
        .setClassName(className)
        .setExtends(ParameterStruct(name: 'Provider', import: 'package:mineral/api.dart'))
        .addConstructor([constructor])
        .addBodyConstructor(StringBuffer('// _client.register();'))
        .build();
  }
}
